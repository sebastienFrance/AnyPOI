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
    
    fileprivate let contacts:[CNContact]
    
    fileprivate var addressToPlacemark = [String:CLPlacemark]()
    
    fileprivate var contactsToBeDeleted:Set<String>?
    
    
    init() {
        contacts = ContactsUtilities.getContactsWithAddress()
    }
    
    func contactsToSynchronize() -> Int {
        return contacts.count
    }
    
    func synchronize() {
        addressToPlacemark.removeAll()
        contactsToBeDeleted = POIDataManager.sharedInstance.getAllContactsIdentifier()
        contactsSynchronization(index:0)
        addressToPlacemark.removeAll()
   }

    fileprivate func contactsSynchronization(index:Int) {
        if index < contacts.count {
            let contactToBeAdded = self.contacts[index]
            if CNContactFormatter.string(from: contactToBeAdded, style: .fullName) == nil {
                self.contactsSynchronization(index:index + 1)
            } else {
                let address = CNPostalAddressFormatter().string(from: contactToBeAdded.postalAddresses[0].value )
                
                let contacts = POIDataManager.sharedInstance.findContact(contactToBeAdded.identifier)
                if contacts.count > 0 {
                    _ = contactsToBeDeleted?.remove(contactToBeAdded.identifier)
                    
                    // The contact is already registered in the database, we just need to update it. We need to perform geocoding only if the 
                    // address has been changed
                    if contacts.count > 1 {
                        print("\(#function) Warning, more than one contact found with identifier \(contactToBeAdded.identifier)")
                    }
                    
                    if address == contacts[0].poiContactLatestAddress {
                        contacts[0].updateWith(contactToBeAdded)
                    } else {
                        geoCodingFor(index:index, address: address, contactToBeAdded: contactToBeAdded)
                    }
                    
                    contactsSynchronization(index:index + 1)
                } else {
                    // It's a new contact
                    
                    if addressToPlacemark[address.lowercased()] == nil {
                        geoCodingFor(index:index, address: address, contactToBeAdded: contactToBeAdded)
                    } else {
                        synchronizeContactWithDatabase(contact:contactToBeAdded, withPlacemark:addressToPlacemark[address.lowercased()]!)
                        contactsSynchronization(index:index + 1)
                    }
                }
            }
        } else {
            // All contacts have been processed
            // check which contacts must be removed from the database
            if let theContactsList = contactsToBeDeleted {
                POIDataManager.sharedInstance.deleteContacts(theContactsList)
                POIDataManager.sharedInstance.commitDatabase()
            }
            HUD.hide()
        }
    }
    
    
    fileprivate func geoCodingFor(index:Int, address:String, contactToBeAdded:CNContact) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let theError = error  {
                print("\(#function) Error, geocode has failed for address \(address) with error \(theError .localizedDescription)")
            } else {
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
