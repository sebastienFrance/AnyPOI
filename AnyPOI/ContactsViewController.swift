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
            theTableView.tableFooterView = UIView(frame: CGRectZero) // remove separator for empty lines
        }
    }

    enum ModeType {
        case phone, email
    }
    
    weak var delegate:ContactsDelegate!
    
    var mode = ModeType.phone
    
    var poi:PointOfInterest?
    private var contact: CNContact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contact = ContactsUtilities.getContactForDetailedDescription(poi!.poiContactIdentifier!)
        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.layer.masksToBounds = true;
        
        theTableView.reloadData()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeButtonPushed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        delegate.endContacts()
    }
    
    @IBAction func faceTimeButtonPushed(sender: UIButton) {
        let currentLabeledValue = contact!.phoneNumbers[sender.tag]
        
        if let phoneNumber = (currentLabeledValue.value as? CNPhoneNumber)?.stringValue {
            if let facetimeURL = NSURL(string: "facetime://\(phoneNumber)") {
                if UIApplication.sharedApplication().canOpenURL(facetimeURL) {
                    UIApplication.sharedApplication().openURL(facetimeURL)
                    dismissViewControllerAnimated(true, completion: nil)
                    delegate.endContacts()
                }
            }
        }
    }
    
    //MARK: Utils
    private static func CNlabelTranslation(label:String) -> String {
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return poi?.poiDisplayName
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(storyboard.contactCellId, forIndexPath: indexPath) as! ContactTableViewCell
        
        switch mode {
        case .phone:
            let currentLabeledValue = contact!.phoneNumbers[indexPath.row]
            
            let phoneNumber = currentLabeledValue.value as? CNPhoneNumber
            
            cell.phoneLabel?.text = ContactsViewController.CNlabelTranslation(currentLabeledValue.label ?? "")
            cell.phoneNumber?.text = phoneNumber!.stringValue
            
            if currentLabeledValue.label == CNLabelPhoneNumberiPhone {
                cell.faceTimeButton.hidden = false
                cell.faceTimeButton.tag = indexPath.row
            } else {
                cell.faceTimeButton.hidden = true
            }
            
        case .email:
            let currentLabeledValue = contact!.emailAddresses[indexPath.row]
            let email = currentLabeledValue.value as? String
            
            cell.phoneLabel?.text = ContactsViewController.CNlabelTranslation(currentLabeledValue.label ?? "")
            cell.phoneNumber?.text = email
            cell.faceTimeButton.hidden = true
            break
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch mode {
        case .phone:
            let currentLabeledValue = contact!.phoneNumbers[indexPath.row]
            let phoneNumber = currentLabeledValue.value as? CNPhoneNumber
            Utilities.startPhoneCall(phoneNumber!.stringValue)
            dismissViewControllerAnimated(true, completion: nil)
            delegate.endContacts()

        case .email:
            if MFMailComposeViewController.canSendMail() {
                let currentLabeledValue = contact!.emailAddresses[indexPath.row]
                if let email = currentLabeledValue.value as? String {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.setToRecipients([email])
                    mailComposer.mailComposeDelegate = self
                    presentViewController(mailComposer, animated: true, completion: nil)
                }
            }
            break
        }
    }

}

extension ContactsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) {
            self.dismissViewControllerAnimated(true, completion: nil)
            self.delegate.endContacts()
        }
    }
}
