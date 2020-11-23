//
//  CoordinateSettingsController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 23.11.2020.
//

import UIKit
import CoreLocation

class CoordinateSettingsController: UIViewController {

    @IBOutlet weak var lngTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var applyBtn: UIButton!
    
    var location: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lngTextField.delegate = self
        latTextField.delegate = self
    }

    @IBAction func didClickUseCupertinoLocation(_ sender: Any) {

        location = CLLocationCoordinate2D(latitude: 37.78274, longitude: -122.43152)
        
        postLocationNotif()
    }
    
    @IBAction func didClickApplyLocation(_ sender: Any) {
        
        guard let lat = Double(latTextField.text ?? ""), let lng = Double(lngTextField.text ?? "") else {
            return
        }
        
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        postLocationNotif()
    }
    
    private func postLocationNotif() {
        
        guard let location = self.location else {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("LocationChangedNotification"), object: nil, userInfo: ["location" : location])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func checkApplyButtonEnabled() -> Bool {
        
        guard let lng = lngTextField.text, let lat = latTextField.text else {
            return false
        }
        
        if lng.count > 0 && lng.contains(where: { (char) -> Bool in
            char.isNumber
        }) && lat.count > 0 && lat.contains(where: { (char) -> Bool in
            char.isNumber
        }) {
            return true
        }
        
        return false
    }
}

extension CoordinateSettingsController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        applyBtn.isEnabled = checkApplyButtonEnabled()
        
        return true
    }
}
