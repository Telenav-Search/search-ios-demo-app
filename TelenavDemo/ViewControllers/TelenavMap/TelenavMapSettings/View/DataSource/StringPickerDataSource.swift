//
//  StringPickerDataSource.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 19.08.2021.
//

import UIKit

class StringPickerDataSource: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    private let items: [String]
    var onSelectedItem: ((_ index: Int) -> Void)?
    
    init(items: [String]) {
        self.items = items
    }
    
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
        onSelectedItem?(row)
    }
}
