//
//  GeoFilterCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit
import TelenavEntitySDK

class GeoFilterCell: UITableViewCell {

    @IBOutlet weak var filerTypeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }

    func fillItem(_ item: TNEntityGeoFilterTypeDisplayModel) {
        filerTypeLabel.text = item.geoFilterType.rawValue
    }
}
