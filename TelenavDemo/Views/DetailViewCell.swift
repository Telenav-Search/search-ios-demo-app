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
        
        setupView()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    func setupView() {
        
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
