//
//  PurchaseTableViewCell.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 27/02/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import UIKit
import StoreKit

class PurchaseTableViewCell: UITableViewCell {

    @IBOutlet weak var priceButton: UIButton!
    @IBOutlet weak var purchaseTitle: UILabel!
    @IBOutlet weak var purchaseDescription: UILabel!
    
    func initWith(product: SKProduct, id:Int) {
        let priceFormatter = NumberFormatter()
        priceFormatter.formatterBehavior = .behavior10_4
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        if let price = priceFormatter.string(from: product.price) {
            priceButton.setTitle(price, for: .normal)
            priceButton.isEnabled = true
            priceButton.tag = id
        } else {
            priceButton.setTitle("Unknown Price", for: .normal)
            priceButton.isEnabled = false
        }
        
        purchaseDescription.text = product.localizedDescription
        purchaseTitle.text = product.localizedTitle
    }
    
    func initAsAlreadyPurchased(product: SKProduct) {
        priceButton.setTitle(NSLocalizedString("ProductPurchased", comment: ""), for: .normal)
        priceButton.setTitleColor(UIColor.lightGray, for: .normal)
        priceButton.isEnabled = false
        
        purchaseDescription.text = product.localizedDescription
        purchaseTitle.text = product.localizedTitle       
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
