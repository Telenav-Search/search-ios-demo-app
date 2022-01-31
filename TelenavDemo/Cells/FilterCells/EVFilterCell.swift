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
        
        itemTitleLabel.accessibilityIdentifier = "EVFilterCellItemTitleLabel"
        itemsStackView.accessibilityIdentifier = "EVFilterCellItemsStackView"
    }

    private var currentFilter: EVFilter?
    
    func fillEVFilters(_ item: EVFilter) {
        itemTitleLabel.text = item.evFilterTitle
        
        for view in itemsStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        self.currentFilter = item
        for (idx, elem) in item.evFilterContent.enumerated() {
            let btn = UIButton()
            
            btn.layer.cornerRadius = 9
            btn.tag = idx + 1
            
            if btn.isSelected {
                btn.setTitleColor(.white, for: .selected)
                btn.backgroundColor = .link
            } else {
                btn.setTitleColor(.black, for: .normal)
                btn.backgroundColor = .white
            }
            
            switch elem.evFilterType {
            case .chargerBrands:
                btn.setTitle((elem as! ChargerBrand).chargerBrandType.fullName, for: .normal)
            case .connectorTypes:
                btn.setTitle((elem as! Connector).connectorType.fullName, for: .normal)
            case .powerFeeds:
                btn.setTitle((elem as! PowerFeedLevel).level.levelName, for: .normal)
            }
            
            btn.frame = CGRect(x: 0, y: 0, width: itemsStackView.frame.width, height: 44)
            
            btn.addTarget(self, action: #selector(didSelectElement), for: .touchUpInside)
            
            if itemsStackView.arrangedSubviews.contains(where: { (v) -> Bool in
                v.tag == idx + 1
            }) == false {
                itemsStackView.addArrangedSubview(btn)
            }
            
            btn.isSelected = item.evFilterContent[idx].isSelected
            toggleSelectedState(btn)
        }
    }
    
    @objc private func didSelectElement(_ sender: UIButton) {
        
        guard let item = currentFilter else {
            return
        }
        
        item.evFilterContent[sender.tag - 1].isSelected.toggle()
        
        sender.isSelected.toggle()
        
        toggleSelectedState(sender)
     }
    
    func toggleSelectedState(_ button: UIButton) {
        if button.isSelected {
            button.setTitleColor(.white, for: .selected)
            button.backgroundColor = .link
        } else {
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = .white
        }
    }
}
