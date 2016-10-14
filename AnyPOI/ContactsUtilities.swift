//
//  ContactsUtilities.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 15/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import CoreLocation
import PKHUD

class ContactsUtilities {
    
    static func getContactsWithAddress() -> [CNContact] {
        
        let keysToFetch = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactPostalAddressesKey, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [Any]
        let store = CNContactStore()
        var contactsWithAddress = [CNContact]()
        do {
            try store.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])) {
                (contact, cursor) -> Void in
                if contact.areKeysAvailable([CNContactPostalAddressesKey as CNKeyDescriptor]) {
                    if contact.postalAddresses.count != 0 {
                        contactsWithAddress.append(contact)
                    }
                }
            }
        }
        catch{
            print("\(#function) Error when retrieving the contacts.")
        }
        return contactsWithAddress
    }
    
    static func getThumbailImageDataFor(_ contactIdentifier:String) -> Data? {
        let keysToFectch = [CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
        let store = CNContactStore()
        do {
            let contact =  try store.unifiedContact(withIdentifier: contactIdentifier, keysToFetch: keysToFectch as [CNKeyDescriptor])
            if contact.imageDataAvailable {
                return contact.thumbnailImageData
            }
        }
        catch{
            print("\(#function) Error when retrieving thumbail image for the contacts: \(contactIdentifier).")
        }
        
        return nil
    }
    
    static func getContactForDetailedDescription(_ contactIdentifier:String) -> CNContact? {
        let keysToFectch = [CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey, CNContactPhoneNumbersKey, CNContactUrlAddressesKey, CNContactEmailAddressesKey]
        let store = CNContactStore()
        do {
            return try store.unifiedContact(withIdentifier: contactIdentifier, keysToFetch: keysToFectch as [CNKeyDescriptor])
        }
        catch{
            print("\(#function) Error when retrieving data for the contacts: \(contactIdentifier).")
        }
        
        return nil
    }
    
    static func getContactForCNContactViewController(_ contactIdentifier:String) -> CNContact? {
        let contactStore = CNContactStore()
        
        do {
            return try contactStore.unifiedContact(withIdentifier: contactIdentifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        }
        catch{
            print("\(#function) Error when retrieving data for the contacts: \(contactIdentifier).")
        }
        
        return nil

    }
    
    static func extractPhoneNumber(_ contact:CNContact) -> CNPhoneNumber? {
        if contact.phoneNumbers.count > 0 {
            var otherNumber:CNPhoneNumber?
            for currentLabeledValue in contact.phoneNumbers {
                
                if let phoneLabel = currentLabeledValue.label {
                    switch phoneLabel {
                    case CNLabelPhoneNumberMain:
                        return currentLabeledValue.value as? CNPhoneNumber
                    case CNLabelPhoneNumberiPhone, CNLabelPhoneNumberMobile, CNLabelWork, CNLabelHome:
                        otherNumber = currentLabeledValue.value as? CNPhoneNumber
                    default:
                        break
                    }
                }
            }
            
            if otherNumber == nil && contact.phoneNumbers.count > 0 {
                otherNumber = contact.phoneNumbers[0].value as? CNPhoneNumber
            }
            
            return otherNumber
        } else {
            return nil
        }
    }
    
    static func extractURL(_ contact:CNContact) -> String? {
        if contact.urlAddresses.count > 0 {
            return contact.urlAddresses[0].value as? String
        } else {
            return nil
        }
    }
}
