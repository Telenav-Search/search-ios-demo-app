//
//  SearchResultCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavSDK

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

    func fillSearchResultItem(_ item: TelenavEntity, itemNumber: Int) {
        self.numberLabel.text = "\(itemNumber)"
        self.nameLabel.text = item.place?.name
        self.addressLabel.text = item.place?.address?.formattedAddress
        
        if let distance = item.formattedDistance {
            self.distanceLabel.text = distance
            self.distanceLabel.isHidden = false
        } else {
            self.distanceLabel.isHidden = true
        }
    }
}
