//
//  PreferencesViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 05/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit
import LocalAuthentication
import Contacts
import PKHUD

//, EnterCredentialsDelegate
class OptionsViewController: UITableViewController, PasswordConfigurationDelegate, UserAuthenticationDelegate, ContainerViewControllerDelegate {

    weak var theMapView: MKMapView!
    
    @IBOutlet weak var switchApplePOIs: UISwitch!
    @IBOutlet weak var switchTraffic: UISwitch!
    
    @IBOutlet weak var cellStandard: UITableViewCell!
    @IBOutlet weak var cellHybridFlyover: UITableViewCell!
    @IBOutlet weak var cellFlyoverWith360: UITableViewCell!
    
    @IBOutlet weak var switchDefaultTransportType: UISegmentedControl! {
        didSet {
            let defaultTransportType = UserPreferences.sharedInstance.routeDefaultTransportType
            switch(defaultTransportType) {
            case MKDirectionsTransportType.automobile:
                switchDefaultTransportType.selectedSegmentIndex = 0
            case MKDirectionsTransportType.walking:
                switchDefaultTransportType.selectedSegmentIndex = 1
            default:
                switchDefaultTransportType.selectedSegmentIndex = 0
            }
        }
    }


    @IBOutlet weak var wikiLanguage: UILabel!

    @IBOutlet weak var wikiDistanceAndResults: UILabel!
    @IBOutlet weak var switchEnablePassword: UISwitch!
    @IBOutlet weak var switchEnableTouchId: UISwitch!
    @IBOutlet weak var changePasswordButton: UIButton!
    
  
    @IBOutlet weak var synchronizeContactsPurchaseLabel: UILabel!
    @IBOutlet weak var synchronizeContactsButton: UIButton!
    @IBOutlet weak var synchronizationContactsProgressLabel: UILabel!
    @IBOutlet weak var synchronizationContactsActivity: UIActivityIndicatorView!
    @IBOutlet weak var exportAllData: UIButton!
    @IBOutlet weak var exportAllDataPurchaseLabel: UILabel!
    var userAuthentication:UserAuthentication!
    
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?

    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }

    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            tableView.isUserInteractionEnabled = enable
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 96
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .plain, target: self, action: #selector(OptionsViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }

 
        userAuthentication = UserAuthentication(delegate: self)

        switchApplePOIs.isOn = UserPreferences.sharedInstance.mapShowPointsOfInterest
        switchTraffic.isOn = UserPreferences.sharedInstance.mapShowTraffic
 
        switchEnablePassword.isOn = UserPreferences.sharedInstance.authenticationPasswordEnabled
        enableChangePassword()
        enableTouchId()
        updateCellMapMode()
        
        NotificationCenter.default.addObserver(self, selector: #selector(OptionsViewController.contactsSynchronizationDone(_:)), name:  Notification.Name(rawValue: ContactsSynchronization.Notifications.synchronizationDone), object: ContactsSynchronization.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(OptionsViewController.contactsSynchronizationUpdate(_:)), name:  Notification.Name(rawValue: ContactsSynchronization.Notifications.sycnhronizationUpdate), object: ContactsSynchronization.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(OptionsViewController.productPurchased(_:)), name:  Notification.Name(rawValue: AppDelegate.Notifications.purchasedProduct), object: UIApplication.shared.delegate)

        synchronizationContactsProgressLabel.text = ""
        
        if UserPreferences.sharedInstance.isAnyPoiUnlimited {
            synchronizeContactsPurchaseLabel.isHidden = true
            exportAllDataPurchaseLabel.isHidden = true
            if ContactsSynchronization.sharedInstance.isSynchronizing {
                synchronizeContactsButton.isEnabled = false
                synchronizationContactsActivity.startAnimating()
            }
        } else {
            synchronizeContactsButton.isEnabled = false
            exportAllData.isEnabled = false
        }
    }
    
    func productPurchased(_ notification:Notification) {
        synchronizeContactsButton.isEnabled = true
        synchronizeContactsPurchaseLabel.isHidden = true
        exportAllData.isEnabled = true
        exportAllDataPurchaseLabel.isHidden = true
    }

    
    func contactsSynchronizationDone(_ notification:Notification) {
        synchronizeContactsButton.isEnabled = true
        synchronizationContactsActivity.stopAnimating()
        synchronizationContactsProgressLabel.text = ""
    }
    
    func contactsSynchronizationUpdate(_ notification:Notification) {
        if let userInfo = notification.userInfo,
            let synchronizedContacts = userInfo[ContactsSynchronization.Notifications.Parameter.synchronizedContactsNumber] as? Int,
            let totalContacts = userInfo[ContactsSynchronization.Notifications.Parameter.totalContactsNumber] as? Int {
            synchronizationContactsProgressLabel.text = "\(synchronizedContacts) / \(totalContacts)"
        }
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    fileprivate func updateWikipediaDescription() {
        let userPrefs = UserPreferences.sharedInstance
        
        let distanceFormatter = LengthFormatter()
        distanceFormatter.unitStyle = .short
        let distance = distanceFormatter.string(fromMeters: Double(userPrefs.wikipediaNearByDistance))

        let attributedText = NSMutableAttributedString(string: "\(NSLocalizedString("LanguageWikipediaOptionVC", comment: "")) ")
        let language = WikipediaLanguages.LanguageForISOcode(userPrefs.wikipediaLanguageISOcode)
        attributedText.append(NSAttributedString(string: language, attributes:[NSForegroundColorAttributeName : UIColor.blue]))
        wikiLanguage.attributedText = attributedText

        let rangeAndResults = NSMutableAttributedString(string:NSLocalizedString("RangeWikipediaOptionVC", comment: ""))
        rangeAndResults.append(NSAttributedString(string: "\(distance) ", attributes:[NSForegroundColorAttributeName : UIColor.blue]))
        rangeAndResults.append(NSAttributedString(string: NSLocalizedString("MaxResultWikipediaOptionVC", comment: "")))
        rangeAndResults.append(NSAttributedString(string: "\(userPrefs.wikipediaMaxResults)", attributes:[NSForegroundColorAttributeName : UIColor.blue]))
        wikiDistanceAndResults.attributedText = rangeAndResults
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        
        updateWikipediaDescription()
    }

    
    func enableChangePassword() {
        changePasswordButton.isEnabled =  UserPreferences.sharedInstance.authenticationPasswordEnabled
    }
    
    func enableTouchId() {
        switchEnableTouchId.isEnabled = switchEnablePassword.isOn
        switchEnableTouchId.isOn = UserPreferences.sharedInstance.authenticationTouchIdEnabled
    }
    
    
    @IBAction func updateDefaultTransportType(_ sender: UISegmentedControl) {
        switch(sender.selectedSegmentIndex) {
        case 0:
            UserPreferences.sharedInstance.routeDefaultTransportType = .automobile
        case 1:
            UserPreferences.sharedInstance.routeDefaultTransportType = .walking
        default:
            UserPreferences.sharedInstance.routeDefaultTransportType = .automobile
        }
    }
    
    func updateCellMapMode() {
        cellStandard.accessoryType = .none
        cellHybridFlyover.accessoryType = .none
        
        switch(theMapView.mapType) {
        case .hybridFlyover:
            cellHybridFlyover.accessoryType = .checkmark
        case .standard:
            cellStandard.accessoryType = .checkmark
        default:
            cellStandard.accessoryType = .checkmark
        }
        
        cellFlyoverWith360.accessoryType = UserPreferences.sharedInstance.flyover360Enabled ? .checkmark : .none
    }

    @IBAction func switchMapOptionsChanged(_ sender: UISwitch) {
        if sender == switchApplePOIs {
            UserPreferences.sharedInstance.mapShowPointsOfInterest = sender.isOn
            theMapView.showsPointsOfInterest = sender.isOn
       } else if sender == switchTraffic {
            UserPreferences.sharedInstance.mapShowTraffic = sender.isOn
            theMapView.showsTraffic = sender.isOn
       } else {
            print("\(#function) Error unknown sender")
        }
    }
    
    //MARK: Contacts sync
    @IBAction func synchronizeContacts(_ sender: UIButton) {
        synchronizeContactsButton.isEnabled = false
        synchronizationContactsActivity.startAnimating()

        ContactsSynchronization.sharedInstance.synchronize()
    }
    
    @IBAction func exportAll(_ sender: UIButton) {
        let activityController = UIActivityViewController(activityItems: [ExportAllMailActivityItemSource(), GPXActivityItemSource()],
                                                          applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivityType.print, UIActivityType.airDrop, UIActivityType.postToVimeo,
                                                    UIActivityType.postToWeibo, UIActivityType.openInIBooks, UIActivityType.postToFlickr, UIActivityType.postToFacebook,
                                                    UIActivityType.postToTwitter, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard,
                                                    UIActivityType.saveToCameraRoll, UIActivityType.postToTencentWeibo, UIActivityType.message]
        
        present(activityController, animated: true, completion: nil)

    }
    // MARK: Password & TouchId
    var isDisablingPassword = false

    @IBAction func switchEnablePasswordChanged(_ sender: UISwitch) {
        if switchEnablePassword.isOn {
            performPasswordChange()
        } else {
            isDisablingPassword = true
            userAuthentication.requestOneShotAuthentication(reason:NSLocalizedString("DisablePasswordAuthentication",comment:""))
        }
    }
    
    @IBAction func switchTouchIdChanged(_ sender: UISwitch) {
        if switchEnableTouchId.isOn {
            var error:NSError?
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                UserPreferences.sharedInstance.authenticationTouchIdEnabled = true
            } else {
                switchEnableTouchId.isOn = false
                Utilities.showAlertMessage(self, title: NSLocalizedString("TouchIdError",comment:""), error: error!)
            }
        } else {
            isDisablingPassword = false
            userAuthentication.requestOneShotAuthentication(reason:NSLocalizedString("DisableTouchIdAuthentication",comment:""))
        }
    }

    
    //MARK: UserAuthenticationDelegate
    func authenticationDone() {
        if isDisablingPassword {
            // Reset everything related to authentication
            UserPreferences.sharedInstance.authenticationPasswordEnabled = false
            UserPreferences.sharedInstance.authenticationTouchIdEnabled = false
            UserPreferences.sharedInstance.authenticationPassword = ""
            switchEnableTouchId.setOn(false, animated: true)
            switchEnableTouchId.isEnabled = false
            changePasswordButton.isEnabled = false
        } else {
            UserPreferences.sharedInstance.authenticationTouchIdEnabled = false
        }
        
        isDisablingPassword = false
    }
    
    func authenticationFailure() {
        // No change, restore original position of the switch
        if isDisablingPassword {
            switchEnablePassword.setOn(UserPreferences.sharedInstance.authenticationPasswordEnabled, animated: true)
        } else {
            switchEnableTouchId.setOn(UserPreferences.sharedInstance.authenticationTouchIdEnabled, animated: true)
        }
        isDisablingPassword = false
    }


    @IBAction func changePassword(_ sender: UIButton) {
        performPasswordChange()
    }
    
    fileprivate func performPasswordChange() {
        let passwordChangeRequest = ChangePassword()
        passwordChangeRequest.requestNewPassword(self, delegate: self, oldPassword: UserPreferences.sharedInstance.authenticationPassword)
    }
    
    //MARK: PasswordConfigurationDelegate
    func passwordChangedSuccessfully(_ newPassword:String) {
        UserPreferences.sharedInstance.authenticationPasswordEnabled = true
        UserPreferences.sharedInstance.authenticationPassword = newPassword
        enableTouchId()
        enableChangePassword()
    }

    func passwordNotChanged() {
        if !UserPreferences.sharedInstance.authenticationPasswordEnabled {
            switchEnablePassword.isOn = false
        }
    }
    
    //MARK: Tableview delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                theMapView.mapType = .standard
            } else if indexPath.row == 1 {
                theMapView.mapType = .hybridFlyover
            } else if indexPath.row == 2 {
                 UserPreferences.sharedInstance.flyover360Enabled = cellFlyoverWith360.accessoryType == .checkmark ? false : true
            }
            UserPreferences.sharedInstance.mapMode = theMapView.mapType
            updateCellMapMode()
        }
    }
}
