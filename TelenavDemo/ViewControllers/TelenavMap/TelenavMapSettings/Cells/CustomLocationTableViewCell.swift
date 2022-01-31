//
//  CustomLocationTableViewCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 19.08.2021.
//

import UIKit
import CoreLocation

class CustomLocationTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet private var subtitle0Label: UILabel!
    @IBOutlet private var subtitle1Label: UILabel!
    @IBOutlet private var `switch`: UISwitch!
    @IBOutlet private var textField0: UITextField!
    @IBOutlet private var textField1: UITextField!
    
    var stateChanged: ((_ location: CLLocation?, _ isOn: Bool) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        subtitle0Label.text = "Latitude"
        subtitle1Label.text = "Longitude"
        
        textField0.delegate = self
        textField0.keyboardType = .default
        textField1.delegate = self
        textField1.keyboardType = .default
        `switch`.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        
        titleLabel.accessibilityIdentifier = "customLocationTableViewCellTitleLabel"
        subtitle0Label.accessibilityIdentifier = "customLocationTableViewCellSubtitle0Label"
        subtitle1Label.accessibilityIdentifier = "customLocationTableViewCellSubtitle1Label"
        `switch`.accessibilityIdentifier = "customLocationTableViewCellSwitch"
        textField0.accessibilityIdentifier = "customLocationTableViewCellTextField0"
        textField1.accessibilityIdentifier = "customLocationTableViewCellTextField1"
    }
    
    @objc func switchValueDidChange(_ sender: UISwitch) {
        callDelegate(latString: textField0.text, lonString: textField1.text)
    }
    
    func setLocation(_ location: CLLocation?, isOn: Bool) {
        if location == nil {
            `switch`.isEnabled = false
            `switch`.isOn = false
        } else {
            `switch`.isEnabled = true
            `switch`.isOn = isOn
        }
    }
    
    private func callDelegate(latString: String?, lonString: String?) {
        guard let stateChanged = stateChanged else {
            return
        }
        
        if let latString = latString,
           let lonString = lonString,
           let latNumer = Double(latString),
           let lonNumber = Double(lonString),
           `switch`.isEnabled {
            let location = CLLocation(latitude: latNumer, longitude: lonNumber)
            stateChanged(location, `switch`.isOn)
        } else {
            stateChanged(nil, false)
        }
    }
}

extension CustomLocationTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let textRange = Range(range, in: text) else {
            return false
        }
        
        var latString = textField0.text
        var lonString = textField1.text
        
        let updatedText = text.replacingCharacters(in: textRange, with: string)
        
        if textField == textField0 {
            latString = updatedText
        } else
        if textField == textField1 {
            lonString = updatedText
        }
        
        if let latString = latString,
           let lonString = lonString,
           let latNumer = Double(latString),
           let lonNumber = Double(lonString),
           (-90...90).contains(latNumer) && (-180...180).contains(lonNumber) {
            `switch`.isEnabled = true
        } else {
            `switch`.isEnabled = false
            `switch`.isOn = false
        }
        callDelegate(latString: latString, lonString: lonString)
        
        return true
    }
}
