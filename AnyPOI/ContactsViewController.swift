//
//  PhoneTableViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import Contacts
import MessageUI

protocol ContactsDelegate : class {
    func endContacts()
}


class ContactsViewController: UIViewController   {

    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            theTableView.delegate = self
            theTableView.dataSource = self
            theTableView.estimatedRowHeight = 70
            theTableView.rowHeight = UITableViewAutomaticDimension
            theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
        }
    }

    enum ModeType {
        case phone, email
    }
    
    weak var delegate:ContactsDelegate!
    
    var mode = ModeType.phone
    
    var poi:PointOfInterest?
    fileprivate var contact: CNContact?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let thePOI = poi, let contactId = thePOI.poiContactIdentifier {
            contact = ContactsUtilities.getContactForDetailedDescription(contactId)
        }
        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.layer.masksToBounds = true;
        
        theTableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeButtonPushed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        delegate.endContacts()
    }
    
    @IBAction func faceTimeButtonPushed(_ sender: UIButton) {
        if let theContact =  contact {
            let currentLabeledValue = theContact.phoneNumbers[sender.tag]
            let phoneNumber = (currentLabeledValue.value as CNPhoneNumber).stringValue
            if let facetimeURL = URL(string: "facetime://\(phoneNumber)") {
                if UIApplication.shared.canOpenURL(facetimeURL) {
                    UIApplication.shared.open(facetimeURL, options:[UIApplicationOpenURLOptionUniversalLinksOnly : true], completionHandler: nil)
                    dismiss(animated: true, completion: nil)
                    delegate.endContacts()
                }
            }
        }
    }
    
    //MARK: Utils
    fileprivate static func CNlabelTranslation(_ label:String) -> String {
        switch label {
        case CNLabelPhoneNumberMain:
            return NSLocalizedString("PhoneLabelMain", comment: "")
        case CNLabelPhoneNumberiPhone:
            return NSLocalizedString("PhoneLabeliPhone", comment: "")
        case CNLabelPhoneNumberMobile:
            return NSLocalizedString("PhoneLabelMobile", comment: "")
        case CNLabelWork:
            return NSLocalizedString("PhoneLabelWork", comment: "")
        case CNLabelHome:
            return NSLocalizedString("PhoneLabelHome", comment: "")
        case CNLabelPhoneNumberPager:
            return NSLocalizedString("PhoneLabelPager", comment: "")
        case CNLabelPhoneNumberHomeFax:
            return NSLocalizedString("PhoneLabelHomeFax", comment: "")
        case CNLabelPhoneNumberWorkFax:
            return NSLocalizedString("PhoneLabelWorkFax", comment: "")
        case CNLabelPhoneNumberOtherFax:
            return NSLocalizedString("PhoneLabelOtherFax", comment: "")
        default:
            return NSLocalizedString("PhoneLabelOther", comment: "")
        }
    }
}

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return poi?.poiDisplayName
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let theContact = contact {
            switch mode {
            case .phone:
                return theContact.phoneNumbers.count
            case .email:
                return theContact.emailAddresses.count
            }
        } else {
            return 0
        }
    }
    
    struct storyboard {
        static let contactCellId = "contactCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: storyboard.contactCellId, for: indexPath) as! ContactTableViewCell
        if let theContact = contact {

            switch mode {
            case .phone:
                let currentLabeledValue = theContact.phoneNumbers[indexPath.row]

                let phoneNumber = currentLabeledValue.value as CNPhoneNumber

                cell.phoneLabel?.text = ContactsViewController.CNlabelTranslation(currentLabeledValue.label ?? "")
                cell.phoneNumber?.text = phoneNumber.stringValue

                if currentLabeledValue.label == CNLabelPhoneNumberiPhone {
                    cell.faceTimeButton.isHidden = false
                    cell.faceTimeButton.tag = indexPath.row
                } else {
                    cell.faceTimeButton.isHidden = true
                }
            case .email:
                let currentLabeledValue = theContact.emailAddresses[indexPath.row]
                let email = currentLabeledValue.value as String

                cell.phoneLabel?.text = ContactsViewController.CNlabelTranslation(currentLabeledValue.label ?? "")
                cell.phoneNumber?.text = email
                cell.faceTimeButton.isHidden = true
                break
            }
        } else {
            cell.phoneLabel?.text = "Unknown error, contact doesn't exist"
        }

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let theContact = contact {
            switch mode {
            case .phone:
                let currentLabeledValue = theContact.phoneNumbers[indexPath.row]
                let phoneNumber = currentLabeledValue.value as CNPhoneNumber
                Utilities.startPhoneCall(phoneNumber.stringValue)
                dismiss(animated: true, completion: nil)
                delegate.endContacts()

            case .email:
                if MFMailComposeViewController.canSendMail() {
                    let currentLabeledValue = theContact.emailAddresses[indexPath.row]
                    let email = currentLabeledValue.value as String
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.setToRecipients([email])
                    mailComposer.mailComposeDelegate = self
                    present(mailComposer, animated: true, completion: nil)
                }
                break
            }
        }
    }
}

extension ContactsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            self.dismiss(animated: true, completion: nil)
            self.delegate.endContacts()
        }
    }
}
