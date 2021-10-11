//
//  ToggleableTableViewCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit

class ToggleableTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var `switch`: UISwitch!
    
    var isOn: Bool = false {
        didSet {
            `switch`.isOn = isOn
        }
    }
    
    var switchChanged: ((_ isOn: Bool) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        `switch`.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
    }
    
    @objc func switchValueDidChange(_ sender: UISwitch) {
        switchChanged?(sender.isOn)
    }
}
