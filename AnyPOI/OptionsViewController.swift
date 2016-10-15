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

    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }

    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            tableView.isUserInteractionEnabled = enable
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: UIImage(named: "Menu-30"), style: .plain, target: self, action: #selector(OptionsViewController.menuButtonPushed(_:)))
            
            navigationItem.leftBarButtonItem = menuButton
        }

 
        userAuthentication = UserAuthentication(delegate: self)

        switchApplePOIs.isOn = UserPreferences.sharedInstance.mapShowPointsOfInterest
        switchTraffic.isOn = UserPreferences.sharedInstance.mapShowTraffic
        
        
        let defaultTransportType = UserPreferences.sharedInstance.routeDefaultTransportType
        switch(defaultTransportType) {
        case MKDirectionsTransportType.automobile:
            switchDefaultTransportType.selectedSegmentIndex = 0
        case MKDirectionsTransportType.walking:
            switchDefaultTransportType.selectedSegmentIndex = 1
        default:
            switchDefaultTransportType.selectedSegmentIndex = 0
        }

        switchEnablePassword.isOn = UserPreferences.sharedInstance.authenticationPasswordEnabled
        enableChangePassword()
        enableTouchId()
        updateCellMapMode()
    }
    
    
    
    fileprivate func updateWikipediaDescription() {
        let userPrefs = UserPreferences.sharedInstance
        let language = WikipediaLanguages.LanguageForISOcode(userPrefs.wikipediaLanguageISOcode)
        
        let distanceFormatter = LengthFormatter()
        distanceFormatter.unitStyle = .short
        let distance = distanceFormatter.string(fromMeters: Double(userPrefs.wikipediaNearByDistance))
        
        wikiLanguage.text = "\(NSLocalizedString("LanguageWikipediaOptionVC", comment: "")) \(language)"
        wikiDistanceAndResults.text = String.localizedStringWithFormat(NSLocalizedString("Range %@, maxResult %@", comment: ""), distance, "\(userPrefs.wikipediaMaxResults)")
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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Contacts sync
    @IBAction func synchronizeContacts(_ sender: UIButton) {
        let contactSync = ContactsSynchronization()
        
        PKHUD.sharedHUD.dimsBackground = true
        HUD.show(.progress)
        let hudBaseView = PKHUD.sharedHUD.contentView as! PKHUDSquareBaseView
        hudBaseView.titleLabel.text = NSLocalizedString("Geocoding",comment:"")
        hudBaseView.subtitleLabel.text = "\(contactSync.contactsToSynchronize()) \(NSLocalizedString("Adresses",comment:""))"

        contactSync.synchronize()
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
        
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 {
                theMapView.mapType = .standard
            } else {
                theMapView.mapType = .hybridFlyover
            }
            UserPreferences.sharedInstance.mapMode = theMapView.mapType
            updateCellMapMode()
        }
    }
}
