//
//  CameraRegionCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 01.10.2021.
//

import UIKit

class CameraRegionCell: UITableViewCell {
    @IBOutlet private var nLaTextField: UITextField!
    @IBOutlet private var sLaTextField: UITextField!
    @IBOutlet private var wLoTextField: UITextField!
    @IBOutlet private var eLoTextField: UITextField!
    
    var northLatitude = 0.0 {
        didSet {
            nLaTextField.text = String(northLatitude)
        }
    }
    
    var westLongitude = 0.0 {
        didSet {
            wLoTextField.text = String(westLongitude)
        }
    }
    
    var southLatitude = 0.0 {
        didSet {
            sLaTextField.text = String(southLatitude)
        }
    }
    
    var eastLongitude = 0.0 {
        didSet {
            eLoTextField.text = String(eastLongitude)
        }
    }
    
    var regionDidChange: ((_ nLa: Double?, _ wLo: Double?,_ sLa: Double?, _ eLo: Double?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        nLaTextField.addTarget(self, action: #selector(nLaTextFieldValueChanged(textField:)), for: .editingChanged)
        sLaTextField.addTarget(self, action: #selector(sLaTextFieldValueChanged(textField:)), for: .editingChanged)
        wLoTextField.addTarget(self, action: #selector(wLoTextFieldValueChanged(textField:)), for: .editingChanged)
        eLoTextField.addTarget(self, action: #selector(eLoTextFieldValueChanged(textField:)), for: .editingChanged)
        
        setupAccessibilityIdentifiers()
    }
    
    func setupAccessibilityIdentifiers() {
        nLaTextField.accessibilityIdentifier = "cameraRegionCellNLaTextField"
        sLaTextField.accessibilityIdentifier = "cameraRegionCellSLaTextField"
        wLoTextField.accessibilityIdentifier = "cameraRegionCellWLoTextField"
        eLoTextField.accessibilityIdentifier = "cameraRegionCellELoTextField"
    }
    
    @objc func nLaTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    @objc func sLaTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    @objc func wLoTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    @objc func eLoTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    func someValuesChanged() {
        var nLa: Double? = nil
        var sLa: Double? = nil
        var wLo: Double? = nil
        var eLo: Double? = nil
        
        if let nLaText = nLaTextField.text {
            nLa = Double(nLaText)
        }
        
        if let sLaText = sLaTextField.text {
            sLa = Double(sLaText)
        }
        
        if let wLoText = wLoTextField.text {
            wLo = Double(wLoText)
        }
        
        if let eLoText = eLoTextField.text {
            eLo = Double(eLoText)
        }
        
        regionDidChange?(nLa, wLo, sLa, eLo)
    }
    
    @IBAction func LAButtonTapped(_ sender: Any) {
        nLaTextField.text = "34.25689101792032"
        sLaTextField.text = "33.77892333703834"
        wLoTextField.text = "-118.46286677455927"
        eLoTextField.text = "-117.90614642948708"
        
        someValuesChanged()
    }
    
    @IBAction func NYButtonTapped(_ sender: Any) {
        nLaTextField.text = "41.14136903740544"
        sLaTextField.text = "40.539523632789695"
        wLoTextField.text = "-74.43263286323155"
        eLoTextField.text = "-72.80793966251214"
        
        someValuesChanged()
    }
}
