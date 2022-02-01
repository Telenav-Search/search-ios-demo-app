//
//  TexteditableTableViewCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit

class TexteditableTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textField: UITextField!
    
    var textDidChanged: ((_ text: String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        
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
        
        titleLabel.accessibilityIdentifier = "texteditableTableViewCellLabel"
        textField.accessibilityIdentifier = "texteditableTableViewCellTextField"
    }
}

extension TexteditableTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let textRange = Range(range, in: text) else {
            return false
        }
                
        let updatedText = text.replacingCharacters(in: textRange, with: string)
        textDidChanged?(updatedText)
        
        return true
    }
}
