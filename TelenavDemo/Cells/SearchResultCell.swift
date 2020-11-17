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

    func fillSearchResultItem(_ item: TelenavEntity) {
        self.numberLabel.text = ""
        self.nameLabel.text = item.place?.name
        self.addressLabel.text = item.place?.address?.formattedAddress
        
        if let distance = item.distance {
            self.distanceLabel.text = "\(distance) km"
            self.distanceLabel.isHidden = false
        } else {
            self.distanceLabel.isHidden = true
        }
    }
}
