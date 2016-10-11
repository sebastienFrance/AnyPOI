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
    
    @IBOutlet weak var switchDefaultTransportType: UISegmentedControl!


    @IBOutlet weak var wikiLanguage: UILabel!

    @IBOutlet weak var wikiDistanceAndResults: UILabel!
    @IBOutlet weak var switchEnablePassword: UISwitch!
    @IBOutlet weak var switchEnableTouchId: UISwitch!
    @IBOutlet weak var changePasswordButton: UIButton!
    
    var userAuthentication:UserAuthentication!
    
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?

    @objc private func menuButtonPushed(button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }

    func enableGestureRecognizer(enable:Bool) {
        if isViewLoaded() {
            tableView.userInteractionEnabled = enable
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .Plain, target: self, action: #selector(OptionsViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }

 
        userAuthentication = UserAuthentication(delegate: self)

        switchApplePOIs.on = UserPreferences.sharedInstance.mapShowPointsOfInterest
        switchTraffic.on = UserPreferences.sharedInstance.mapShowTraffic
        
        
        let defaultTransportType = UserPreferences.sharedInstance.routeDefaultTransportType
        switch(defaultTransportType) {
        case MKDirectionsTransportType.Automobile:
            switchDefaultTransportType.selectedSegmentIndex = 0
        case MKDirectionsTransportType.Walking:
            switchDefaultTransportType.selectedSegmentIndex = 1
        default:
            switchDefaultTransportType.selectedSegmentIndex = 0
        }

        switchEnablePassword.on = UserPreferences.sharedInstance.authenticationPasswordEnabled
        enableChangePassword()
        enableTouchId()
        updateCellMapMode()
    }
    
    
    
    private func updateWikipediaDescription() {
        let userPrefs = UserPreferences.sharedInstance
        let language = WikipediaLanguages.LanguageForISOcode(userPrefs.wikipediaLanguageISOcode)
        
        let distanceFormatter = NSLengthFormatter()
        distanceFormatter.unitStyle = .Short
        let distance = distanceFormatter.stringFromMeters(Double(userPrefs.wikipediaNearByDistance))
        
        wikiLanguage.text = "\(NSLocalizedString("LanguageWikipediaOptionVC", comment: "")) \(language)"
        wikiDistanceAndResults.text = String.localizedStringWithFormat(NSLocalizedString("Range %@, maxResult %@", comment: ""), distance, "\(userPrefs.wikipediaMaxResults)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true
        
        updateWikipediaDescription()
    }

    
    func enableChangePassword() {
        changePasswordButton.enabled =  UserPreferences.sharedInstance.authenticationPasswordEnabled
    }
    
    func enableTouchId() {
        switchEnableTouchId.enabled = switchEnablePassword.on
        switchEnableTouchId.on = UserPreferences.sharedInstance.authenticationTouchIdEnabled
    }
    
    
    @IBAction func updateDefaultTransportType(sender: UISegmentedControl) {
        switch(sender.selectedSegmentIndex) {
        case 0:
            UserPreferences.sharedInstance.routeDefaultTransportType = .Automobile
        case 1:
            UserPreferences.sharedInstance.routeDefaultTransportType = .Walking
        default:
            UserPreferences.sharedInstance.routeDefaultTransportType = .Automobile
        }
    }
    
    func updateCellMapMode() {
        cellStandard.accessoryType = .None
        cellHybridFlyover.accessoryType = .None
        
        switch(theMapView.mapType) {
        case .HybridFlyover:
            cellHybridFlyover.accessoryType = .Checkmark
        case .Standard:
            cellStandard.accessoryType = .Checkmark
        default:
            cellStandard.accessoryType = .Checkmark
        }
    }

    @IBAction func switchMapOptionsChanged(sender: UISwitch) {
        if sender == switchApplePOIs {
            UserPreferences.sharedInstance.mapShowPointsOfInterest = sender.on
            theMapView.showsPointsOfInterest = sender.on
       } else if sender == switchTraffic {
            UserPreferences.sharedInstance.mapShowTraffic = sender.on
            theMapView.showsTraffic = sender.on
       } else {
            print("\(#function) Error unknown sender")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Contacts sync
    @IBAction func synchronizeContacts(sender: UIButton) {
        let contactSync = ContactsSynchronization()
        
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.Progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = NSLocalizedString("Geocoding",comment:"")
        hudBaseView.subtitleLabel.text = "\(contactSync.contactsToSynchronize()) \(NSLocalizedString("Adresses",comment:""))"

        contactSync.synchronize()
    }
    
    // MARK: Password & TouchId
    var isDisablingPassword = false

    @IBAction func switchEnablePasswordChanged(sender: UISwitch) {
        if switchEnablePassword.on {
            performPasswordChange()
        } else {
            isDisablingPassword = true
            userAuthentication.requestOneShotAuthentication(NSLocalizedString("DisablePasswordAuthentication",comment:""))
        }
    }
    
    @IBAction func switchTouchIdChanged(sender: UISwitch) {
        if switchEnableTouchId.on {
            var error:NSError?
            let context = LAContext()
            if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                UserPreferences.sharedInstance.authenticationTouchIdEnabled = true
            } else {
                switchEnableTouchId.on = false
                Utilities.showAlertMessage(self, title: NSLocalizedString("TouchIdError",comment:""), error: error!)
            }
        } else {
            isDisablingPassword = false
            userAuthentication.requestOneShotAuthentication(NSLocalizedString("DisableTouchIdAuthentication",comment:""))
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
            switchEnableTouchId.enabled = false
            changePasswordButton.enabled = false
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


    @IBAction func changePassword(sender: UIButton) {
        performPasswordChange()
    }
    
    private func performPasswordChange() {
        let passwordChangeRequest = ChangePassword()
        passwordChangeRequest.requestNewPassword(self, delegate: self, oldPassword: UserPreferences.sharedInstance.authenticationPassword)
    }
    
    //MARK: PasswordConfigurationDelegate
    func passwordChangedSuccessfully(newPassword:String) {
        UserPreferences.sharedInstance.authenticationPasswordEnabled = true
        UserPreferences.sharedInstance.authenticationPassword = newPassword
        enableTouchId()
        enableChangePassword()
    }

    func passwordNotChanged() {
        if !UserPreferences.sharedInstance.authenticationPasswordEnabled {
            switchEnablePassword.on = false
        }
    }
    
    //MARK: Tableview delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                theMapView.mapType = .Standard
            } else {
                theMapView.mapType = .HybridFlyover
            }
            UserPreferences.sharedInstance.mapMode = theMapView.mapType
            updateCellMapMode()
        }
    }
}
