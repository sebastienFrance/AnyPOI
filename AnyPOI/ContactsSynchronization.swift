//
//  ContactsGeoCoding.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 16/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import CoreLocation


/// This class synchronize all user contacts 
/// It look for each contacts if it exists as a POI. If it doesn't exist and if it has an address
/// it performs geocoding to get the address of the contact and then it's created as a POI.
/// If a POI was created from a contact and that contact doesn't exist anymore it's removed from the POI
///
/// Warning: Due to Geocoding request rate limitation the geocoding may fails (usually after 40 requests).
/// When the error happens, we stop the synchronization and we display an error message
/// We wait 3 second between each Geocding request to try to not exceed the request rate...
class ContactsSynchronization {
    
    struct Notifications {
        static let synchronizationDone = "SynchronizationDone"
        static let sycnhronizationUpdate = "SynchronizationUpdate"
        struct Parameter {
            static let isSuccess = "isSuccess"
            static let synchronizedContactsNumber = "synchronizedContactsNumber"
            static let totalContactsNumber = "totalContactsNumber"
        }
    }
    static let sharedInstance = ContactsSynchronization()
    
    // All user contacts
    fileprivate var contacts = [CNContact]()
    
    // Keep translation from an Address to a Placemark
    // It's used to avoid perform the geocoding of the same address several times
    // It can occurs when severals contacts are living at the same address
    fileprivate var addressToPlacemark = [String:CLPlacemark]()
    
    // List of contacts that must be removed when the synchronization has been completed
    fileprivate var contactsToBeDeleted = Set<String>()
    
    fileprivate(set) var isSynchronizing = false
    
    
    fileprivate init() {
    }
    
    
    /// Start the synchronization of the contact list
    /// It must be called on the Main thread
    /// If a synchronization is already ongoing, it will do nothing
    func synchronize() {
        if !isSynchronizing {
            isSynchronizing = true
            
            
            // Initialize the data before the synchronization
            addressToPlacemark.removeAll()
            contactsToBeDeleted = POIDataManager.sharedInstance.getAllContactsIdentifier()
            contacts = ContactsUtilities.getContactsWithAddress()
            
            contactsSynchronization(index:0)
        }
    }

    /// Synchronize a contact at the given index
    /// This methods is called recursively to synchronize all contacts. It's a recursive method and not a simple loop because the 
    /// GeoCoding is performed asynchronously and only one can be done at the same time
    ///
    /// - Parameter index: index of the contact that must be synchronized. When the index is > contacts.count the loop is stopped
    // and the synchronization is completed
    fileprivate func contactsSynchronization(index:Int) {
        if index < contacts.count {

            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.sycnhronizationUpdate),
                                            object: self,
                                            userInfo:[Notifications.Parameter.synchronizedContactsNumber: index + 1,
                                                      Notifications.Parameter.totalContactsNumber : self.contacts.count])
            let contactToSync = contacts[index]
            let address = CNPostalAddressFormatter().string(from: contactToSync.postalAddresses[0].value)
            
            // Check if the contact is already registered in the database
            let foundContacts = POIDataManager.sharedInstance.findContact(contactToSync.identifier)
            if let theContact = foundContacts.first {
                _ = self.contactsToBeDeleted.remove(contactToSync.identifier)
                
                // Perform geocoding only if the address has been changed
                if address == theContact.address {
                    // Update only the contact name because the address has not been changed
                    theContact.updateWith(contactToSync)
                    POIDataManager.sharedInstance.commitDatabase()
                    contactsSynchronization(index:index + 1) // Synchronize the next contact
                } else {
                    // When the address has changed we must perform a new GeoCoding only if we have not already resolved it
                    if let placemarkContact = self.addressToPlacemark[address.lowercased()] {
                        theContact.updateWith(contactToSync, placemark:placemarkContact)
                        POIDataManager.sharedInstance.commitDatabase()
                        contactsSynchronization(index:index + 1)
                    } else {
                        geoCodingFor(index:index, address: address, contactToBeAdded: contactToSync)
                    }
                }
                
            } else {
                // It's a new contact but maybe we already have its placemark
                if let placemarkContact = addressToPlacemark[address.lowercased()] {
                    _ = POIDataManager.sharedInstance.addPOI(contactToSync, placemark: placemarkContact)
                    contactsSynchronization(index:index + 1)
                } else {
                    geoCodingFor(index:index, address: address, contactToBeAdded: contactToSync)
                }
            }
            
        } else {
            // All contacts have been processed
            
            endSynchronization(withSuccess: true, stoppedIndex: index)
        }
    }
    
    fileprivate func endSynchronization(withSuccess:Bool, stoppedIndex:Int) {

        
        addressToPlacemark.removeAll()
        let totalCount = contacts.count
        contacts.removeAll()
        
        // check which contacts must be removed from the database
        POIDataManager.sharedInstance.deleteContacts(self.contactsToBeDeleted)
        POIDataManager.sharedInstance.commitDatabase()
        self.contactsToBeDeleted.removeAll()
        
        self.isSynchronizing = false
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.synchronizationDone),
                                        object: self,
                                        userInfo:[Notifications.Parameter.isSuccess: withSuccess,
                                                  Notifications.Parameter.synchronizedContactsNumber: stoppedIndex,
                                                  Notifications.Parameter.totalContactsNumber : totalCount])
    }
    
    private struct GeoCodingTimer {
        static let afterSuccess = 1
        static let afterFailure = 60
    }
    
    /// Perform the Geocoding of the address and then update the contact in the database
    /// At the end this method callback the synchronization to continue with the next contact
    /// This method is asynchronous and the callback is executed on the main thread
    ///
    /// - Parameters:
    ///   - index: index of the contact under synchronization
    ///   - address: address of the contact that must be resolved using GeoCoding
    ///   - contactToBeAdded: Contact under synchronization
    fileprivate func geoCodingFor(index:Int, address:String, contactToBeAdded:CNContact) {
        // geocodeAddressString is async and the response is called on the Main thread
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let errorReverseGeocode = error  {
                NSLog("\(#function) geocode has failed for address \(address) with error \(errorReverseGeocode.localizedDescription)")
                switch errorReverseGeocode {
                case CLError.network:
                    NSLog("\(#function) Error because too many requests! (network error)")
                    
                    // Remove from the contactToBeDeleted contacts that still exists in Contact and in database
                    for i in index...(self.contacts.count - 1) {
                        let contactToSync = self.contacts[i]
                        
                        // Check if the contact is already registered in the database
                        let foundContacts = POIDataManager.sharedInstance.findContact(contactToSync.identifier)
                        if foundContacts.count > 0 {
                            _ = self.contactsToBeDeleted.remove(contactToSync.identifier)
                        }
                    }
                    
                    self.endSynchronization(withSuccess: false, stoppedIndex: index + 1)
                    return
                default:
                    break
                }
            } else {
                // If we have found the placemark of the contact it's recorded in the database
                if let thePlacemark = placemarks {
                    if thePlacemark.count > 0 {
                        self.addressToPlacemark[address.lowercased()] = thePlacemark[0]
                        self.synchronizeContactWithDatabase(contact:contactToBeAdded, withPlacemark:thePlacemark[0])
                    } else {
                        NSLog("\(#function) Warning, no placemark for address \(address)")
                    }
                } else {
                    NSLog("\(#function) Warning geocode has no results for address \(address)")
                }
            }
            
            
            let expirationTime = DispatchTime.now() + .seconds(GeoCodingTimer.afterSuccess)
            DispatchQueue.main.asyncAfter(deadline: expirationTime) {
                self.contactsSynchronization(index:index + 1)
            }
        }
    }
    
    
    /// Add or update a POI in the database using the contact & placemark informations
    ///
    /// - Parameters:
    ///   - contact: Contact to be synchronized
    ///   - withPlacemark: Placemark information of the contact
    fileprivate func synchronizeContactWithDatabase(contact:CNContact, withPlacemark:CLPlacemark) {
        let contacts = POIDataManager.sharedInstance.findContact(contact.identifier)
        if contacts.count == 0 {
            _ = POIDataManager.sharedInstance.addPOI(contact, placemark: withPlacemark)
        } else {
            if contacts.count > 1 {
                NSLog("\(#function) Warning, more than one contact found with identifier \(contact.identifier)")
            }
            contacts[0].updateWith(contact, placemark:withPlacemark)
            POIDataManager.sharedInstance.commitDatabase()
        }
    }
}
