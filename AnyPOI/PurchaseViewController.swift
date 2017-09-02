//
//  PurchaseViewController.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 27/02/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import StoreKit

class PurchaseViewController: UIViewController, ContainerViewControllerDelegate  {

    @IBOutlet weak var theTableView: UITableView! {
        didSet {
            if let tableView = theTableView {
                tableView.delegate = self
                tableView.dataSource = self
                theTableView.estimatedRowHeight = 94
                theTableView.rowHeight = UITableViewAutomaticDimension
                theTableView.tableFooterView = UIView(frame: CGRect.zero) // remove separator for empty lines
            }
        }
    }
    @IBOutlet weak var restorePurchaseButton: UIButton!
    
    fileprivate var productRequest:SKProductsRequest?
    
    fileprivate var products = [SKProduct]()
    fileprivate var isLoadingProducts = true
    
    var isStartedByLeftMenu = false
    weak var container:ContainerViewController?
    
    @objc fileprivate func menuButtonPushed(_ button:UIBarButtonItem) {
        container?.toggleLeftPanel()
    }
    
    func enableGestureRecognizer(_ enable:Bool) {
        if isViewLoaded {
            theTableView.isUserInteractionEnabled = enable
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PurchaseViewController.productPurchased(_:)), name:  Notification.Name(rawValue: AppDelegate.Notifications.purchasedProduct), object: UIApplication.shared.delegate)

        
        if isStartedByLeftMenu {
            let menuButton =  UIBarButtonItem(image: #imageLiteral(resourceName: "Menu-30"), style: .plain, target: self, action: #selector(PurchaseViewController.menuButtonPushed(_:)))
            navigationItem.leftBarButtonItem = menuButton
        }
        
        getProducts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func productPurchased(_ notification:Notification) {
        restorePurchaseButton.isEnabled = false
        theTableView.reloadData()
    }
    
    func getProducts() {
        restorePurchaseButton.isEnabled = false
        
        if let url = Bundle.main.url(forResource: "ProductIds", withExtension: "plist"), let productsIds = NSArray(contentsOf: url) {
            
            if SKPaymentQueue.canMakePayments() {
                let newProductRequest = SKProductsRequest(productIdentifiers: [productsIds[0] as! String])
                productRequest = newProductRequest
                productRequest?.delegate = self
                productRequest?.start()
            } else {
                NSLog("\(#function) user cannot make payement")
                isLoadingProducts = false
                theTableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func restorePurchasePushed(_ sender: UIButton) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    @IBAction func purchaseButtonPushed(_ sender: UIButton) {
        if sender.tag < products.count {
            let productToPurchase = products[sender.tag]
            let payment = SKPayment(product: productToPurchase)
            SKPaymentQueue.default().add(payment)
        }
    }
 }


extension PurchaseViewController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        isLoadingProducts = false
        if response.products.count > 0 && !UserPreferences.sharedInstance.isAnyPoiUnlimited {
            restorePurchaseButton.isEnabled = true
        }
        
        if response.invalidProductIdentifiers.count > 0 {
            for invalidProduct in response.invalidProductIdentifiers {
                NSLog("\(#function) found invalid product: \(invalidProduct) ")
            }
        }
        
        products = response.products
        theTableView.reloadData()
    }
}

extension PurchaseViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoadingProducts {
            return 1
        } else {
            return products.count
        }
    }
    
    struct storyboard {
        static let purchaseCellId = "PurchaseCellId"
        static let loadingCellId = "loadingCellId"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoadingProducts {
            let cell = tableView.dequeueReusableCell(withIdentifier: storyboard.loadingCellId, for: indexPath) as! LoadingTableViewCell
            cell.theLabel.text = NSLocalizedString("LoadingProducts", comment: "")
            cell.theActivityIndicator.startAnimating()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: storyboard.purchaseCellId, for: indexPath) as! PurchaseTableViewCell
            
            if UserPreferences.sharedInstance.isAnyPoiUnlimited {
                cell.initAsAlreadyPurchased(product:products[indexPath.row])
            } else {
                cell.initWith(product:products[indexPath.row], id:indexPath.row)
            }
            
            return cell
            
        }
    }
    
}
