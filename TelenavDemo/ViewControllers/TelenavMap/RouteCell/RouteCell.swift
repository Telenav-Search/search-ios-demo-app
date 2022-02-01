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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        
        titleLabel.accessibilityIdentifier = "routeCellTitleLabel"
    }

    override class func awakeFromNib() {
        super.awakeFromNib()

    }
}
