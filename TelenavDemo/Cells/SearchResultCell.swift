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
    @IBOutlet var starViews: [UIImageView]!
    
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
            
            for (idx,sb) in ratingView.arrangedSubviews.enumerated() {
                if let imgView = sb as? UIImageView {
                    if idx < Int(avgRating) {
                        imgView.image = UIImage(systemName: "star.fill")
                    } else {
                        imgView.image = UIImage(systemName: "star")
                    }
                }
            }
        } else {
            ratingView.isHidden = true
        }
    }
}
