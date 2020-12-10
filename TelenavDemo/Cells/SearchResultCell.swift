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

    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var starView: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func fillSearchResultItem(_ item: TNEntity, itemNumber: Int) {
        self.numberLabel.text = "\(itemNumber)."
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
       
        if let rating = item.facets?.rating?.first {
            
            let avgRating = rating.averageRating ?? 0
            
            ratingView.isHidden = false
            
            var rem = ""
            if avgRating.truncatingRemainder(dividingBy: 1) > 0 {
                rem = "_half"
            }
            
            starView.image = UIImage(named: "large_\(Int(avgRating))\(rem)")
        } else {
            ratingView.isHidden = true
        }
    }
}
