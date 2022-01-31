//
//  RouteCell.swift
//  TelenavDemo
//
//  Created by Anatol Uarmolovich on 9.11.21.
//

import UIKit

class RouteCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? .systemRed : .systemBlue
        }
    }

    override class func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.accessibilityIdentifier = "routeCellTitleLabel"
    }
}
