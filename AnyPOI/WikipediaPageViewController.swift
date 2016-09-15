//
//  WikipediaPageViewController.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 26/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class WikipediaPageViewController: UIViewController {

    @IBOutlet weak var theWebView: UIWebView!
    
    var url = "https://wikipedia.org"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        theWebView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
