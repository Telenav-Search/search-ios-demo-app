//
//  DetailViewCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit


class DetailViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var detailTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        nameLabel.accessibilityIdentifier = "detailViewCellNameLabel"
        titleLabel.accessibilityIdentifier = "detailViewCellTitleLabel"
        detailTextView.accessibilityIdentifier = "detailViewCellDetailTextView"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fillDetail(_ detailInfo: DetailViewDisplayModel) {
        nameLabel.text = detailInfo.fieldName
        detailTextView.text = detailInfo.fieldValue
    }
}
