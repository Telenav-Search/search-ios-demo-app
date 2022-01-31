//
//  SearchResultCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavEntitySDK

class SearchResultCell: UITableViewCell {

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var starView: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var ratingNumber: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        numberLabel.accessibilityIdentifier = "searchResultCellNumberLabel"
        nameLabel.accessibilityIdentifier = "searchResultCellNameLabel"
        distanceLabel.accessibilityIdentifier = "searchResultCellDistanceLabel"
        categoryLabel.accessibilityIdentifier = "searchResultCellCategoryLabel"
        
        ratingView.accessibilityIdentifier = "searchResultCellRatingStackView"
        starView.accessibilityIdentifier = "searchResultCellStarImageView"
        
        addressLabel.accessibilityIdentifier = "searchResultCellAddressLabel"
        priceLabel.accessibilityIdentifier = "searchResultCellPriceLabel"
        
        ratingNumber.accessibilityIdentifier = "searchResultCellRatingNumberLabel"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func fillSearchResultItem(_ item: TNEntity, itemNumber: Int) {
        self.numberLabel.text = "\(itemNumber)."
        categoryLabel.text = item.place?.categories?.first?.name
        if let distance = item.formattedDistance {
            self.distanceLabel.text = distance
            self.distanceLabel.isHidden = false
        } else {
            self.distanceLabel.isHidden = true
        }

        if let place = item.place {
            self.nameLabel.text = place.name
            self.addressLabel.text = place.address?.formattedAddress
        } else if let address = item.address {
            self.nameLabel.text = address.formattedAddress
            self.addressLabel.text = address.addressLines?.joined(separator: "\n")
        }
        
        if let prices = item.facets?.priceInfo?.priceDetails, prices.count > 0,
           let symbol = prices[0].symbol, let amount = prices[0].amount, let unit = prices[0].unit {
            
            priceLabel.text = "\(symbol) \(String(format: "%.3f", amount)) / \(unit)"
        } else {
            priceLabel.text = ""
        }
       
        if let rating = item.facets?.rating?.first {
            
            let avgRating = rating.averageRating ?? 0
            
            ratingView.isHidden = false
            
            var rem = ""
            if avgRating.truncatingRemainder(dividingBy: 1) > 0 {
                rem = "_half"
            }
            
            starView.image = UIImage(named: "large_\(Int(avgRating))\(rem)")
            
            if let reviewsNum = rating.totalCount {
                ratingNumber.text = "(\(reviewsNum))"
            } else {
                ratingNumber.text = ""
            }
        } else {
            ratingView.isHidden = true
        }
    }
}
