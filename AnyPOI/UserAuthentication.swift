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
    fileprivate(set) static var isUserAuthenticated = false
    
    fileprivate var authenticationOnGoing = false
    
    fileprivate weak var delegate:UserAuthenticationDelegate!
    
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
            oneShotAuthenticationWithTouchId(reason:reason)
        } else {
            oneShotAuthenticationWithPassword(reason:reason)
        }
    }

    
    // MARK: Blocking Authentication
    // Block user while the user password is not correct
    fileprivate func loopOnPasswordAuthentication() {
        let userPasswordController = getUserPasswordController(title:NSLocalizedString("AuthenticationUserAuthentication", comment: ""), message:NSLocalizedString("EnterPasswordUserAuthentication", comment: ""))
        
        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default) { alertAction in
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
        if let theWindow = UIApplication.shared.delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                rootVC.present(userPasswordController, animated: true, completion: nil)
                
            }
        }
    }
    
    // When the user password is invalid it displays an error message and it requests
    // immediately again the password to unlock
    fileprivate func loopOnInvalidPassword() {
        if let theWindow = UIApplication.shared.delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                let alertView = UIAlertController.init(title: NSLocalizedString("InvalidPasswordUserAuthentication", comment: ""), message: NSLocalizedString("TryAgainPasswordUserAuthentication", comment: ""), preferredStyle: .alert)
                let actionClose = UIAlertAction(title: "Close", style: .cancel) { alertAction in
                    alertView.dismiss(animated: true, completion: nil)
                    self.loopOnPasswordAuthentication()
                }
                
                alertView.addAction(actionClose)
                rootVC.present(alertView, animated: true, completion: nil)
            }
        }
    }
    
    // Block user while the Biometric authentication is wrong or if the user password is not correct
    fileprivate func loopOnTouchIdAuthentication() {
        let context = LAContext()
        var error:NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("AccessPrivateDataUserAuthentication", comment: "")) { result, theError in
                if result {
                    // Must be called on the Main thread because some GUI operations will be done
                    DispatchQueue.main.async {
                        UserAuthentication.isUserAuthenticated = true
                        self.authenticationOnGoing = false
                        self.delegate.authenticationDone()
                    }
                } else {
                    // Must be called on the Main thread because we need to display a new AlertController to request the password
                    // SEB: Swift3 to be checked if error handling is correct
                    DispatchQueue.main.async {
                        switch (theError!) {
                        case  LAError.userFallback:
                            self.loopOnPasswordAuthentication()
                        case  LAError.userCancel:
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
    fileprivate func oneShotAuthenticationWithPassword(reason:String) {
        let userPasswordController = getUserPasswordController(title:NSLocalizedString("AuthenticationUserAuthentication", comment: ""), message:reason)
        
        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default) { alertAction in
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
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { alertAction in
            self.delegate.authenticationFailure()
        }
        
        userPasswordController.addAction(cancelButton)
        userPasswordController.addAction(okButton)
        
        if let theWindow = UIApplication.shared.delegate?.window {
            if let rootVC = theWindow?.rootViewController {
                rootVC.present(userPasswordController, animated: true, completion: nil)
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
    fileprivate func oneShotAuthenticationWithTouchId(reason:String) {
        // We disable authentication
        let context = LAContext()
        var error:NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { result, theError in
                DispatchQueue.main.async {
                    if result {
                        self.delegate.authenticationDone()
                    } else {
                        // Must be called on the Main thread because we need to display a new AlertController to request the password
                        DispatchQueue.main.async {
                            // SEB: Swift3 to be check the error handling
                            switch (theError!) {
                            case LAError.userFallback:
                                self.oneShotAuthenticationWithPassword(reason: reason)
                            case LAError.userCancel:
                                self.delegate.authenticationFailure()
                                break
                            default:
                                self.oneShotAuthenticationWithPassword(reason:reason)
                                break
                            }

                        }
                    }
                }
            }
        } else {
            oneShotAuthenticationWithPassword(reason: reason)
        }
    }

    //MARK: Utilities
    fileprivate func getUserPasswordController(title:String, message:String) -> UIAlertController {
        let userPasswordController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        userPasswordController.addTextField()  { textField in
            textField.placeholder = NSLocalizedString("YourPasswordUserAuthentication", comment: "")
            textField.isSecureTextEntry = true
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.spellCheckingType = .no
        }
        
        return userPasswordController
    }
}
