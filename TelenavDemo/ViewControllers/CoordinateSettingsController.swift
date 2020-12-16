//
//  CoordinateSettingsController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 23.11.2020.
//

import UIKit
import CoreLocation

class CoordinateSettingsController: UIViewController, FiltersViewControllerDelegate {

    @IBOutlet weak var lngTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var cupertinoLocSwitch: UISwitch!
    @IBOutlet weak var realLocSwitch: UISwitch!
    @IBOutlet weak var inputSwitch: UISwitch!
    
    @IBOutlet weak var filterSwitch: UISwitch!
    
    weak var delegate: FiltersViewControllerDelegate?

    lazy var filtersVC: FiltersViewController = {
        let vc = storyboard!.instantiateViewController(withIdentifier: "FiltersViewController") as! FiltersViewController
        vc.delegate = self
        return vc
    }()
    
    var location: CLLocationCoordinate2D?
    var defaults = UserDefaults.standard
    var selectedFilters: [SelectableFilterItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lngTextField.delegate = self
        latTextField.delegate = self
        
        latTextField.text = defaults.string(forKey: "lat")
        lngTextField.text = defaults.string(forKey: "lng")
        
        inputSwitch.isEnabled = checkApplyButtonEnabled(for: lngTextField.text) && checkApplyButtonEnabled(for: latTextField.text)

        cupertinoLocSwitch.isOn = defaults.bool(forKey: "cupertino_loc_switch")
        realLocSwitch.isOn = defaults.bool(forKey: "real_loc_switch")
        inputSwitch.isOn = defaults.bool(forKey: "input_loc_switch")
        if cupertinoLocSwitch.isOn {
            cupertinoLocSwitchStateChange(cupertinoLocSwitch)
        } else if realLocSwitch.isOn {
            realLocSwitchStateChange(realLocSwitch)
        } else if inputSwitch.isOn {
            inputLocSwitchStateChange(inputSwitch)
        }
    }

    @IBAction func showFilterAction(_ sender: Any) {
        navigationController?.pushViewController(filtersVC, animated: true)
    }
    
    @IBAction func cupertinoLocSwitchStateChange(_ sender: UISwitch) {
        realLocSwitch.isOn = !cupertinoLocSwitch.isOn
        inputSwitch.isOn = !cupertinoLocSwitch.isOn
        if cupertinoLocSwitch.isOn {
            location = CLLocationCoordinate2D(latitude: 37.78074, longitude: -122.43052)
            postLocationNotif()
        }
        defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
        defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
        defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
    }
    
    @IBAction func realLocSwitchStateChange(_ sender: UISwitch) {
        cupertinoLocSwitch.isOn = !realLocSwitch.isOn
        inputSwitch.isOn = !realLocSwitch.isOn
        if realLocSwitch.isOn {
            location = nil
            postLocationNotif()
        }
        defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
        defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
        defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
    }
    
    @IBAction func inputLocSwitchStateChange(_ sender: UISwitch) {
        
        guard let lat = Double(latTextField.text ?? ""), let lng = Double(lngTextField.text ?? "") else {
            inputSwitch.isOn = false
            realLocSwitchStateChange(realLocSwitch)
            return
        }
        
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        postLocationNotif()
        realLocSwitch.isOn = false
        cupertinoLocSwitch.isOn = false
        
        defaults.set(latTextField.text, forKey: "lat")
        defaults.set(lngTextField.text, forKey: "lng")
        defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
        defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
        defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
    }
    
    private func postLocationNotif() {
        var userInfo = [String: Any]()

        if let location = self.location {
            userInfo["location"] = location
        } else {
            userInfo["useReal"] = true
        }
        
        
        NotificationCenter.default.post(name: Notification.Name("LocationChangedNotification"), object: nil, userInfo: userInfo)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func checkApplyButtonEnabled(for string: String?) -> Bool {
        guard let string = string else {
            return false
        }
        if string.count > 0 && !string.contains(where: { (char) -> Bool in
            !char.isNumber && char != "-"
        }) {
            return true
        }
        
        return false
    }
    
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem]) {
        self.selectedFilters = selectedFilters
        if filterSwitch.isOn {
            delegate?.updateSelectedFilters(selectedFilters: selectedFilters)
        }
    }

    @IBAction func filterSwitchChange(_ sender: Any) {
        if filterSwitch.isOn {
            delegate?.updateSelectedFilters(selectedFilters: selectedFilters)
        } else {
            delegate?.updateSelectedFilters(selectedFilters: [])
        }
    }
}

extension CoordinateSettingsController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            return false
        }
        
        let lat = latTextField == textField ?
            latTextField.text!.replacingCharacters(in: Range(range, in: latTextField.text!)!,
                                                  with: string)
            : latTextField.text
        let lon = lngTextField == textField ?
            lngTextField.text!.replacingCharacters(in: Range(range, in: lngTextField.text!)!,
                                                  with: string)
            : lngTextField.text
        var enabled = checkApplyButtonEnabled(for: lat) && checkApplyButtonEnabled(for: lon)
        
        if let lon = lon, let lat = lat,
           let latNumer = Double(lat),
           let lngNumber = Double(lon),
           !(-90...90).contains(latNumer) || !(-180...180).contains(lngNumber) {
            enabled = false
        }
        
        inputSwitch.isEnabled = enabled
        if !enabled {
            realLocSwitchStateChange(realLocSwitch)
            inputSwitch.isOn = false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        defaults.set(latTextField.text, forKey: "lat")
        defaults.set(lngTextField.text, forKey: "lng")
        
        guard let lat = Double(latTextField.text ?? ""),
              let lng = Double(lngTextField.text ?? ""),
              inputSwitch.isOn else {
            return
        }
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        postLocationNotif()
    }
}
