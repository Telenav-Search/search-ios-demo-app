//
//  EVFilterCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit

class EVFilterCell: UITableViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    
    @IBOutlet weak var itemsStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func fillEVFilters(_ item: EVFilter) {
        itemTitleLabel.text = item.evFilterTitle
        
        for (idx, elem) in item.evFilterContent.enumerated() {
            let btn = UIButton()
            
            btn.layer.cornerRadius = 9
            btn.tag = idx
            
            if btn.isSelected {
                btn.setTitleColor(.white, for: .selected)
                btn.backgroundColor = .blue
            } else {
                btn.setTitleColor(.black, for: .normal)
                btn.backgroundColor = .white
            }
            
            switch elem.evFilterType {
            case .chargerBrands:
                btn.setTitle((elem as! ChargerBrand).rawValue, for: .normal)
            case .connectorTypes:
                btn.setTitle((elem as! SupportedConnectorTypes).fullName, for: .normal)
            case .powerFeeds:
                btn.setTitle((elem as! PowerFeedLevels).levelName, for: .normal)
            }
            
            btn.frame = CGRect(x: 0, y: 0, width: itemsStackView.frame.width, height: 44)
            
            btn.addTarget(self, action: #selector(didSelectElement), for: .touchUpInside)
            
            if itemsStackView.arrangedSubviews.contains(where: { (v) -> Bool in
                v.tag == idx
            }) == false {
                itemsStackView.addArrangedSubview(btn)
            }
        }
    }
    
    @objc private func didSelectElement(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        if sender.isSelected {
            sender.setTitleColor(.white, for: .selected)
            sender.backgroundColor = .blue
        } else {
            sender.setTitleColor(.black, for: .normal)
            sender.backgroundColor = .white
        }
    }
}
