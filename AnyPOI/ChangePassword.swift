//
//  ChangePassword.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 23/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol PasswordConfigurationDelegate: class {
    func passwordChangedSuccessfully(newPassword:String)
    func passwordNotChanged()
}

class ChangePassword {
    
    var userPasswordController:UIAlertController!
    var hasOldPassword = false
    
    let oldPasswordIndex = 0
    
    var passwordIndex:Int {
        get {
            return hasOldPassword ? 1 : 0
        }
    }
    
    var reTypedPasswordIndex:Int {
        get {
            return hasOldPassword ? 2 : 1
        }
    }
    
    
    var oldPassword:String? {
        get {
            return userPasswordController.textFields?[oldPasswordIndex].text
        }
    }

    var newPassword:String? {
        get {
            return userPasswordController.textFields?[passwordIndex].text
        }
    }

    var reTypedPassword:String? {
        get {
            return userPasswordController.textFields?[reTypedPasswordIndex].text
        }
    }

    
    let okButtonIndex = 0
    
    func requestNewPassword(parentViewController:UIViewController, delegate:PasswordConfigurationDelegate, oldPassword:String) {
        
        var message = NSLocalizedString("EnterPasswordChangePassword", comment: "")
        if !oldPassword.isEmpty {
            hasOldPassword = true
            message = NSLocalizedString("NewPasswordMustBeDifferentChangePassword", comment: "")
        }
        
        userPasswordController = UIAlertController(title: NSLocalizedString("PasswordConfigurationChangePassword", comment: ""), message: message, preferredStyle: .Alert)

        if hasOldPassword {
            userPasswordController.addTextFieldWithConfigurationHandler()  { textField in
                ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("OldPasswordChangePassword", comment: ""))
             }
        }
        
        userPasswordController.addTextFieldWithConfigurationHandler()  { textField in
            ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("NewPasswordChangePassword", comment: ""))
            textField.addTarget(self, action: #selector(ChangePassword.checkPassword(_:)), forControlEvents: .AllEditingEvents)
        }
        
        userPasswordController.addTextFieldWithConfigurationHandler()  { textField in
            ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("RetypeNewPasswordChangePassword", comment: ""))
            textField.addTarget(self, action: #selector(ChangePassword.checkPassword(_:)), forControlEvents: .AllEditingEvents)
        }

        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .Default) { alertAction in
            if !oldPassword.isEmpty {
                if let typedOldPassword = self.oldPassword,
                    newPassword = self.newPassword,
                    reTypedNewPassword = self.reTypedPassword
                    where newPassword == reTypedNewPassword && oldPassword == typedOldPassword {
                    delegate.passwordChangedSuccessfully(newPassword)
                } else {
                    Utilities.showAlertMessage(parentViewController, title: NSLocalizedString("Error", comment: ""), message:NSLocalizedString("OldOrNewPasswordWrongChangePassword", comment: ""))
                }
            } else {
                if let newPassword = self.newPassword,
                    reTypedNewPassword = self.reTypedPassword
                    where newPassword == reTypedNewPassword {
                    delegate.passwordChangedSuccessfully(newPassword)
                } else {
                    Utilities.showAlertMessage(parentViewController, title: NSLocalizedString("Error", comment: ""), message:NSLocalizedString("PasswordsNotEquals", comment: ""))
                }
            }
            
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Default) { alertAction in
            delegate.passwordNotChanged()
        }

        okButton.enabled = false
        userPasswordController.addAction(okButton)
        userPasswordController.addAction(cancelButton)
        parentViewController.presentViewController(userPasswordController, animated: true, completion: nil)
    }
    
    
    @objc private func checkPassword(sender:AnyObject) {
        if let passwordText = newPassword,
        reTypedPasswordText = reTypedPassword
            where !passwordText.isEmpty && passwordText == reTypedPasswordText {
            if hasOldPassword {
                if let oldPasswordText = oldPassword
                    where oldPasswordText != passwordText {
                    userPasswordController.actions[okButtonIndex].enabled = true
                } else {
                    userPasswordController.actions[okButtonIndex].enabled = false
                }
            } else {
                userPasswordController.actions[okButtonIndex].enabled = true
            }
        } else {
            userPasswordController.actions[okButtonIndex].enabled = false
        }
     }
    
    private static func initSecureTextField(textField:UITextField, withPlaceHolder:String) {
        textField.placeholder = withPlaceHolder
        textField.secureTextEntry = true
        textField.autocorrectionType = .No
        textField.autocapitalizationType = .None
        textField.spellCheckingType = .No
        textField.clearsOnBeginEditing = true
        textField.clearButtonMode = .Always
    }
}
