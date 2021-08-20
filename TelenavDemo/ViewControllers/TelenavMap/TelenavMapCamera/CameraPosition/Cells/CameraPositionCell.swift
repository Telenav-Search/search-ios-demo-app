//
//  CameraPositionCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 01.10.2021.
//

import UIKit

class CameraPositionCell: UITableViewCell {
    @IBOutlet private var laTextField: UITextField!
    @IBOutlet private var loTextField: UITextField!
    @IBOutlet private var zoomSlider: UISlider!
    @IBOutlet private var tiltSlider: UISlider!
    @IBOutlet private var bearingSlider: UISlider!
    @IBOutlet private var zoomValueLabel: UILabel!
    @IBOutlet private var tiltValueLabel: UILabel!
    @IBOutlet private var bearingValueLabel: UILabel!
    
    var la = 0.0 {
        didSet {
            laTextField.text = String(la)
        }
    }
    
    var lo = 0.0 {
        didSet {
            loTextField.text = String(lo)
        }
    }
    
    var zoom = 0.0 {
        didSet {
            zoomValueLabel.text = String(zoom)
            zoomSlider.value = Float(zoom)
        }
    }
    
    var tilt = 0.0 {
        didSet {
            // TODO: Fix it
            tilt += 90
            tiltValueLabel.text = String(tilt)
            tiltSlider.value = Float(tilt)
        }
    }
    
    var bearing = 0.0 {
        didSet {
            bearingValueLabel.text = String(bearing)
            bearingSlider.value = Float(bearing)
        }
    }
    
    var positionDidChanged: ((_ lo: String, _ la: String, _ zoom: Float, _ tilt: Float, _ bearing: Float) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        laTextField.addTarget(self, action: #selector(laTextFieldValueChanged(textField:)), for: .editingChanged)
        loTextField.addTarget(self, action: #selector(loTextFieldValueChanged(textField:)), for: .editingChanged)
        
        zoomSlider.minimumValue = 0
        zoomSlider.maximumValue = 16
        zoomSlider.addTarget(self, action: #selector(zoomSliderValueChanged), for: .valueChanged)
        
        tiltSlider.minimumValue = 0
        tiltSlider.maximumValue = 60
        tiltSlider.addTarget(self, action: #selector(tiltSliderValueChanged), for: .valueChanged)
        
        bearingSlider.minimumValue = 0
        bearingSlider.maximumValue = 360
        bearingSlider.addTarget(self, action: #selector(bearingSliderValueChanged), for: .valueChanged)
    }
    
    @objc func zoomSliderValueChanged() {
        zoomValueLabel.text = String(zoomSlider.value)
        someValuesChanged()
    }
    
    @objc func tiltSliderValueChanged() {
        tiltValueLabel.text = String(tiltSlider.value)
        someValuesChanged()
    }
    
    @objc func bearingSliderValueChanged() {
        bearingValueLabel.text = String(bearingSlider.value)
        someValuesChanged()
    }
    
    @objc func laTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    @objc func loTextFieldValueChanged(textField: UITextField) {
        someValuesChanged()
    }
    
    @IBAction func LAButtonTapped(_ sender: Any) {
        laTextField.text = "34.04576783242289"
        loTextField.text = "-118.245600897656"
        someValuesChanged()
    }
    
    @IBAction func NYButtonTapped(_ sender: Any) {
        laTextField.text = "40.694025853371116"
        loTextField.text = "-74.0483822456383"
        someValuesChanged()
    }
    
    func someValuesChanged() {
        if let la = laTextField.text,
           let lo = loTextField.text {
            positionDidChanged?(la, lo, zoomSlider.value, tiltSlider.value, bearingSlider.value)
        }
    }
}
