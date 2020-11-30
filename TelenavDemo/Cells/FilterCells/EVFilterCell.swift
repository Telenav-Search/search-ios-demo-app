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

    private var currentFilter: EVFilter?
    
    func fillEVFilters(_ item: EVFilter) {
        itemTitleLabel.text = item.evFilterTitle
        
        self.currentFilter = item
        
        for (idx, elem) in item.evFilterContent.enumerated() {
            let btn = UIButton()
            
            btn.layer.cornerRadius = 9
            btn.tag = idx
            
            if btn.isSelected {
                btn.setTitleColor(.white, for: .selected)
                btn.backgroundColor = .link
            } else {
                btn.setTitleColor(.black, for: .normal)
                btn.backgroundColor = .white
            }
            
            switch elem.evFilterType {
            case .chargerBrands:
                btn.setTitle((elem as! ChargerBrand).chargerBrandType.rawValue, for: .normal)
            case .connectorTypes:
                btn.setTitle((elem as! Connector).connectorType.fullName, for: .normal)
            case .powerFeeds:
                btn.setTitle((elem as! PowerFeedLevel).level.levelName, for: .normal)
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
        
        guard let item = currentFilter else {
            return
        }
        
        item.evFilterContent[sender.tag].isSelected.toggle()
        
        sender.isSelected.toggle()
        
        if sender.isSelected {
            sender.setTitleColor(.white, for: .selected)
            sender.backgroundColor = .link
        } else {
            sender.setTitleColor(.black, for: .normal)
            sender.backgroundColor = .white
        }
    }
}
