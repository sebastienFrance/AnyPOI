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
import PKHUD

class ContactsSynchronization {
    
    fileprivate var contacts = [CNContact]()
    
    // Keep translation from an Address to a Placemark
    // It's used to avoid perform the geocoding of the same address several times
    // It can occurs when severals contacts are living at the same address
    fileprivate var addressToPlacemark = [String:CLPlacemark]()
    
    // List of contacts that must be removed when the synchronization has been completed
    fileprivate var contactsToBeDeleted:Set<String>?
    
    struct Notifications {
        static let synchronizationDone = "SynchronizationDone"
    }

    
    fileprivate(set) var isSynchronizing = false
    
    static let sharedInstance = ContactsSynchronization()
    
    fileprivate init() {
    }
    
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
            
                let contactToSync = contacts[index]
                let address = CNPostalAddressFormatter().string(from: contactToSync.postalAddresses[0].value)
                
                let foundContacts = POIDataManager.sharedInstance.findContact(contactToSync.identifier)
                if foundContacts.count > 0 {
                    _ = self.contactsToBeDeleted?.remove(contactToSync.identifier)
                    
                    // The contact is already registered in the database, we just need to update it. We need to perform geocoding only if the
                    // address has been changed
                    if foundContacts.count > 1 {
                        print("\(#function) Warning, more than one contact found with identifier \(contactToSync.identifier)")
                    }
                    
                    if address == foundContacts[0].address {
                        // Update only the contact name because the address has not been changed
                        foundContacts[0].updateWith(contactToSync)
                        self.contactsSynchronization(index:index + 1) // Synchronize the next contact
                    } else {
                        // When the address has changed we must perform a new GeoCoding only if we have not already resolved it
                        if let placemarkContact = self.addressToPlacemark[address.lowercased()] {
                            foundContacts[0].updateWith(contactToSync, placemark:placemarkContact)
                            self.contactsSynchronization(index:index + 1)
                        } else {
                            self.geoCodingFor(index:index, address: address, contactToBeAdded: contactToSync)
                        }
                    }
                    
                } else {
                    // It's a new contact but maybe we already have its placemark
                    if let placemarkContact = self.addressToPlacemark[address.lowercased()] {
                        _ = POIDataManager.sharedInstance.addPOI(contactToSync, placemark: placemarkContact)
                        self.contactsSynchronization(index:index + 1)
                    } else {
                        self.geoCodingFor(index:index, address: address, contactToBeAdded: contactToSync)
                    }
                }

        } else {
            // All contacts have been processed
            // check which contacts must be removed from the database
            if let theContactsList = contactsToBeDeleted, theContactsList.count > 0 {
                    POIDataManager.sharedInstance.deleteContacts(theContactsList)
                    POIDataManager.sharedInstance.commitDatabase()
            }
            
            addressToPlacemark.removeAll()
            contacts.removeAll()
            contactsToBeDeleted?.removeAll()
            isSynchronizing = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.synchronizationDone), object: self)
        }
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
            // If we have an error it's just ignored
            if let theError = error  {
                print("\(#function) Error, geocode has failed for address \(address) with error \(theError.localizedDescription)")
            } else {
                // If we have found the placemark of the contact it's recorded in the database
                if let thePlacemark = placemarks {
                    if thePlacemark.count > 0 {
                        self.addressToPlacemark[address.lowercased()] = thePlacemark[0]
                        self.synchronizeContactWithDatabase(contact:contactToBeAdded, withPlacemark:thePlacemark[0])
                    } else {
                        print("\(#function) Warning, no placemark for address \(address)")
                    }
                } else {
                    print("\(#function) Warning geocode has no results for address \(address)")
                }
            }
            self.contactsSynchronization(index:index + 1)
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
                print("\(#function) Warning, more than one contact found with identifier \(contact.identifier)")
            }
            contacts[0].updateWith(contact, placemark:withPlacemark)
            POIDataManager.sharedInstance.commitDatabase()
        }
    }
}
