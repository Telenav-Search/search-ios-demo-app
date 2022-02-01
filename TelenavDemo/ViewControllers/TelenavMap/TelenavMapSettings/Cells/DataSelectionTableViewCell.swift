//
//  DataSelectionTableViewCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 19.08.2021.
//

import UIKit

class DataSelectionTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textField: UITextField!
    
    lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()
    
    private var items = [String]()
    private var selectedItemIndex = -1
    private var selectedItemIndexTemporary = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField.inputView = pickerView
        textField.inputAccessoryView = makeGestureInputAccessoryView()
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
        
        titleLabel.accessibilityIdentifier = "dataSelectionTableViewCellLabel"
        textField.accessibilityIdentifier = "dataSelectionTableViewCellTextField"
    }
    
    func setItems(_ items: [String], selectedItemIndex: Int) {
        self.items = items
        self.selectedItemIndex = selectedItemIndex
        self.selectedItemIndexTemporary = selectedItemIndex
    }
    
    var onSelectedItemIndexChange: ((_ index: Int) -> Void)?
}

extension DataSelectionTableViewCell {
    private func makeGestureInputAccessoryView() -> UIView {
        let toolbar = UIToolbar()
        let reset = UIBarButtonItem(title: "Apply", style: .plain, target: self, action: #selector(onApplyGestureType))
        toolbar.items = [reset]
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc private func onApplyGestureType() {
        textField.endEditing(false)
        onSelectedItemIndexChange?(selectedItemIndexTemporary)
    }
}

extension DataSelectionTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedItemIndexTemporary = row
    }
}

extension DataSelectionTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}
