//
//  UserAuthentication.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 10/07/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import LocalAuthentication

protocol UserAuthenticationDelegate: class {
    func authenticationDone()
    func authenticationFailure()
}

class UserAuthentication {
    
    // Global authentication status for the App
    private(set) static var isUserAuthenticated = false
    
    private var authenticationOnGoing = false
    
    private weak var delegate:UserAuthenticationDelegate!
    
    init(delegate:UserAuthenticationDelegate) {
        self.delegate = delegate
    }
    
    static func resignAuthentication() {
        isUserAuthenticated = false
    }
    
    func loopWhileNotAuthenticated() {
        if UserPreferences.sharedInstance.authenticationPasswordEnabled {
            
            if authenticationOnGoing {
                return
            }
            
            authenticationOnGoing = true
            UserAuthentication.isUserAuthenticated = false
            if UserPreferences.sharedInstance.authenticationTouchIdEnabled {
                loopOnTouchIdAuthentication()
            } else {
                loopOnPasswordAuthentication()
            }
        } else {
            UserAuthentication.isUserAuthenticated = true
            delegate.authenticationDone()
        }
    }
    
    func requestOneShotAuthentication(reason:String) {
        if UserPreferences.sharedInstance.authenticationTouchIdEnabled {
            oneShotAuthenticationWithTouchId(reason)
        } else {
            oneShotAuthenticationWithPassword(reason)
        }
    }

    
    // MARK: Blocking Authentication
    // Block user while the user password is not correct
    private func loopOnPasswordAuthentication() {
        let userPasswordController = getUserPasswordController(NSLocalizedString("AuthenticationUserAuthentication", comment: ""), message:NSLocalizedString("EnterPasswordUserAuthentication", comment: ""))
        
        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default) { alertAction in
            if let password = userPasswordController.textFields?[0].text {
                if password == UserPreferences.sharedInstance.authenticationPassword {
                    UserAuthentication.isUserAuthenticated = true
                    self.authenticationOnGoing = false
                    self.delegate.authenticationDone()
                } else {
                    self.loopOnInvalidPassword()
                }
            } else {
                self.loopOnInvalidPassword()
            }
        }
        
        userPasswordController.addAction(okButton)
        if let theWindow = UIApplication.sharedApplication().delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                rootVC.presentViewController(userPasswordController, animated: true, completion: nil)
                
            }
        }
    }
    
    // When the user password is invalid it displays an error message and it requests
    // immediately again the password to unlock
    private func loopOnInvalidPassword() {
        if let theWindow = UIApplication.sharedApplication().delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                let alertView = UIAlertController.init(title: NSLocalizedString("InvalidPasswordUserAuthentication", comment: ""), message: NSLocalizedString("TryAgainPasswordUserAuthentication", comment: ""), preferredStyle: .Alert)
                let actionClose = UIAlertAction(title: "Close", style: .Cancel) { alertAction in
                    alertView.dismissViewControllerAnimated(true, completion: nil)
                    self.loopOnPasswordAuthentication()
                }
                
                alertView.addAction(actionClose)
                rootVC.presentViewController(alertView, animated: true, completion: nil)
            }
        }
    }
    
    // Block user while the Biometric authentication is wrong or if the user password is not correct
    private func loopOnTouchIdAuthentication() {
        let context = LAContext()
        var error:NSError?
        if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("AccessPrivateDataUserAuthentication", comment: "")) { result, error in
                if result {
                    // Must be called on the Main thread because some GUI operations will be done
                    dispatch_async(dispatch_get_main_queue()) {
                        UserAuthentication.isUserAuthenticated = true
                        self.authenticationOnGoing = false
                        self.delegate.authenticationDone()
                    }
                } else {
                    // Must be called on the Main thread because we need to display a new AlertController to request the password
                    dispatch_async(dispatch_get_main_queue()) {
                        switch (error!.code) {
                        case Int(kLAErrorUserFallback):
                            self.loopOnPasswordAuthentication()
                        case Int(kLAErrorUserCancel):
                            self.loopOnPasswordAuthentication()
                        default:
                            self.loopOnPasswordAuthentication()
                        }
                    }
                }
            }
        } else {
            loopOnPasswordAuthentication()
        }
    }
    
    // MARK: One short Authentication
    // Show a UIAlertController to request the password. It adds also a cancel button to abort the authentication
    // authenticationDone() is called on the delegate only when the password has been validated otherwise
    // authenticationFailure() is called
    private func oneShotAuthenticationWithPassword(reason:String) {
        let userPasswordController = getUserPasswordController(NSLocalizedString("AuthenticationUserAuthentication", comment: ""), message:reason)
        
        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default) { alertAction in
            if let password = userPasswordController.textFields?[0].text {
                if password == UserPreferences.sharedInstance.authenticationPassword {
                    self.delegate.authenticationDone()
                } else {
                    self.delegate.authenticationFailure()
                }
                
            } else {
                self.delegate.authenticationFailure()
            }
        }
        
        // On cancel button we consider the authentication has failed
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { alertAction in
            self.delegate.authenticationFailure()
        }
        
        userPasswordController.addAction(cancelButton)
        userPasswordController.addAction(okButton)
        
        if let theWindow = UIApplication.sharedApplication().delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                rootVC.presentViewController(userPasswordController, animated: true, completion: nil)
            } else {
                delegate.authenticationFailure()
            }
        } else {
            delegate.authenticationFailure()
        }
    }
    
    // Perform the authentication using TouchId
    // authenticationSuccess() is called on the delegate only if the biometric data have been validated otherwise
    // authenticationFailure().
    // Only in case of fallback we redirect the user to password authentication
    private func oneShotAuthenticationWithTouchId(authenticationReason:String) {
        // We disable authentication
        let context = LAContext()
        var error:NSError?
        if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: authenticationReason) { result, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if result {
                        self.delegate.authenticationDone()
                    } else {
                        // Must be called on the Main thread because we need to display a new AlertController to request the password
                        dispatch_async(dispatch_get_main_queue()) {
                            switch (error!.code) {
                            case Int(kLAErrorUserFallback):
                                self.oneShotAuthenticationWithPassword(authenticationReason)
                            case Int(kLAErrorUserCancel):
                                self.delegate.authenticationFailure()
                                break
                            default:
                                self.oneShotAuthenticationWithPassword(authenticationReason)
                                break
                            }
                        }
                    }
                }
            }
        } else {
            oneShotAuthenticationWithPassword(authenticationReason)
        }
    }

    //MARK: Utilities
    private func getUserPasswordController(title:String, message:String) -> UIAlertController {
        let userPasswordController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        userPasswordController.addTextFieldWithConfigurationHandler()  { textField in
            textField.placeholder = NSLocalizedString("YourPasswordUserAuthentication", comment: "")
            textField.secureTextEntry = true
            textField.autocorrectionType = .No
            textField.autocapitalizationType = .None
            textField.spellCheckingType = .No
        }
        
        return userPasswordController
    }
}
