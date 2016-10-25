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
    
    fileprivate var contactsToBeDeleted:Set<String>?
    
    
    init() {
    }
    
    func synchronize() {
        
        contacts = ContactsUtilities.getContactsWithAddress()
        
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = NSLocalizedString("Geocoding",comment:"")
        
        
        addressToPlacemark.removeAll()
        contactsToBeDeleted = POIDataManager.sharedInstance.getAllContactsIdentifier()
        contactsSynchronization(index:0)
    }

    fileprivate func contactsSynchronization(index:Int) {
        if index < contacts.count {
            
            // Update the HUD with the contact under synchronization
            let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
            hudBaseView.titleLabel.text = NSLocalizedString("Geocoding",comment:"")
            if let name = CNContactFormatter.string(from: contacts[index], style: .fullName) {
                hudBaseView.subtitleLabel.text = "Resolving \(name) \(index)/\(contacts.count)"
            } else {
                hudBaseView.subtitleLabel.text = "Resolving ? \(index)/\(contacts.count)"
            }

            
            let contactToBeAdded = self.contacts[index]
            let address = CNPostalAddressFormatter().string(from: contactToBeAdded.postalAddresses[0].value)
            
            let foundContacts = POIDataManager.sharedInstance.findContact(contactToBeAdded.identifier)
            if foundContacts.count > 0 {
                _ = contactsToBeDeleted?.remove(contactToBeAdded.identifier)
                
                // The contact is already registered in the database, we just need to update it. We need to perform geocoding only if the
                // address has been changed
                if foundContacts.count > 1 {
                    print("\(#function) Warning, more than one contact found with identifier \(contactToBeAdded.identifier)")
                }
                
                if address == foundContacts[0].poiContactLatestAddress {
                    foundContacts[0].updateWith(contactToBeAdded)
                    contactsSynchronization(index:index + 1)
                } else {
                    geoCodingFor(index:index, address: address, contactToBeAdded: contactToBeAdded)
                }
                
            } else {
                // It's a new contact but maybe we already have its placemark
                if let placemarkContact = addressToPlacemark[address.lowercased()] {
                    _ = POIDataManager.sharedInstance.addPOI(contactToBeAdded, placemark: placemarkContact)
                    contactsSynchronization(index:index + 1)
                 } else {
                    geoCodingFor(index:index, address: address, contactToBeAdded: contactToBeAdded)
                }
            }
        } else {
            // All contacts have been processed
            // check which contacts must be removed from the database
            if let theContactsList = contactsToBeDeleted, theContactsList.count > 0 {
                    POIDataManager.sharedInstance.deleteContacts(theContactsList)
                    POIDataManager.sharedInstance.commitDatabase()
            }
            HUD.hide()
            
            addressToPlacemark.removeAll()
            contacts.removeAll()
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
