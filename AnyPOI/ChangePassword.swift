//
//  ChangePassword.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 23/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

protocol PasswordConfigurationDelegate: class {
    func passwordChangedSuccessfully(_ newPassword:String)
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
    
    func requestNewPassword(_ parentViewController:UIViewController, delegate:PasswordConfigurationDelegate, oldPassword:String) {
        
        var message = NSLocalizedString("EnterPasswordChangePassword", comment: "")
        if !oldPassword.isEmpty {
            hasOldPassword = true
            message = NSLocalizedString("NewPasswordMustBeDifferentChangePassword", comment: "")
        }
        
        userPasswordController = UIAlertController(title: NSLocalizedString("PasswordConfigurationChangePassword", comment: ""), message: message, preferredStyle: .alert)

        if hasOldPassword {
            userPasswordController.addTextField()  { textField in
                ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("OldPasswordChangePassword", comment: ""))
             }
        }
        
        userPasswordController.addTextField()  { textField in
            ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("NewPasswordChangePassword", comment: ""))
            textField.addTarget(self, action: #selector(ChangePassword.checkPassword(_:)), for: .allEditingEvents)
        }
        
        userPasswordController.addTextField()  { textField in
            ChangePassword.initSecureTextField(textField, withPlaceHolder: NSLocalizedString("RetypeNewPasswordChangePassword", comment: ""))
            textField.addTarget(self, action: #selector(ChangePassword.checkPassword(_:)), for: .allEditingEvents)
        }

        let okButton = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default) { alertAction in
            if !oldPassword.isEmpty {
                if let typedOldPassword = self.oldPassword,
                    let newPassword = self.newPassword,
                    let reTypedNewPassword = self.reTypedPassword
                    , newPassword == reTypedNewPassword && oldPassword == typedOldPassword {
                    delegate.passwordChangedSuccessfully(newPassword)
                } else {
                    Utilities.showAlertMessage(parentViewController, title: NSLocalizedString("Error", comment: ""), message:NSLocalizedString("OldOrNewPasswordWrongChangePassword", comment: ""))
                }
            } else {
                if let newPassword = self.newPassword,
                    let reTypedNewPassword = self.reTypedPassword
                    , newPassword == reTypedNewPassword {
                    delegate.passwordChangedSuccessfully(newPassword)
                } else {
                    Utilities.showAlertMessage(parentViewController, title: NSLocalizedString("Error", comment: ""), message:NSLocalizedString("PasswordsNotEquals", comment: ""))
                }
            }
            
        }
        
        let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { alertAction in
            delegate.passwordNotChanged()
        }

        okButton.isEnabled = false
        userPasswordController.addAction(okButton)
        userPasswordController.addAction(cancelButton)
        parentViewController.present(userPasswordController, animated: true, completion: nil)
    }
    
    
    @objc fileprivate func checkPassword(_ sender:AnyObject) {
        if let passwordText = newPassword,
        let reTypedPasswordText = reTypedPassword
            , !passwordText.isEmpty && passwordText == reTypedPasswordText {
            if hasOldPassword {
                if let oldPasswordText = oldPassword
                    , oldPasswordText != passwordText {
                    userPasswordController.actions[okButtonIndex].isEnabled = true
                } else {
                    userPasswordController.actions[okButtonIndex].isEnabled = false
                }
            } else {
                userPasswordController.actions[okButtonIndex].isEnabled = true
            }
        } else {
            userPasswordController.actions[okButtonIndex].isEnabled = false
        }
     }
    
    fileprivate static func initSecureTextField(_ textField:UITextField, withPlaceHolder:String) {
        textField.placeholder = withPlaceHolder
        textField.isSecureTextEntry = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.clearsOnBeginEditing = true
        textField.clearButtonMode = .always
    }
}
