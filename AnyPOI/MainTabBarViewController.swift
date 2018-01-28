//
//  MainTabBarViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 28/01/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {
    
    static public var instance:MainTabBarViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        MainTabBarViewController.instance = self
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    public func showMap() {
        selectedIndex = 0
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
