//
//  CoordinateSettingsController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 23.11.2020.
//

import UIKit
import CoreLocation
import VividDriveSessionSDK

protocol CoordinateSettingsDelegate: class {
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem])
    func regionDidChange(region: String)
}

class CoordinateSettingsController: UIViewController, FiltersViewControllerDelegate {

    @IBOutlet weak var lngTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var regionTextField: UITextField!
    var activeField: UITextField?
    @IBOutlet weak var cupertinoLocSwitch: UISwitch!
    @IBOutlet weak var realLocSwitch: UISwitch!
    @IBOutlet weak var inputSwitch: UISwitch!
    
    @IBOutlet weak var filterSwitch: UISwitch!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerToolbar: UIToolbar!
    
    @IBOutlet weak var regionBottomConstraint: NSLayoutConstraint!
    weak var delegate: CoordinateSettingsDelegate?

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
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let bundle = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        versionLabel.text = "Version: " + (version ?? "Unknown") + " (\((bundle ?? "Unknown")))"
        
        regionTextField.inputView = pickerView
        regionTextField.inputAccessoryView = pickerToolbar
        regionTextField.delegate = self
        pickerView.dataSource = self
        pickerView.delegate = self
        setupKeyboardAppearance()
        
        setupAccessibilityIdentifiers()
    }
    
    func setupAccessibilityIdentifiers() {
        lngTextField.accessibilityIdentifier = "coordinateSettingsViewControllerLngTextField"
        lngLabel.accessibilityIdentifier = "coordinateSettingsViewControllerLngLabel"
        latTextField.accessibilityIdentifier = "coordinateSettingsViewControllerLatTextField"
        latLabel.accessibilityIdentifier = "coordinateSettingsViewControllerLatLabel"
        regionTextField.accessibilityIdentifier = "coordinateSettingsViewControllerRegionTextField"
        regionLabel.accessibilityIdentifier = "coordinateSettingsViewControllerRegionLabel"
        activeField?.accessibilityIdentifier = "coordinateSettingsViewControllerActiveTextField"
        cupertinoLocSwitch.accessibilityIdentifier = "coordinateSettingsViewControllerCupertinoLocSwitch"
        cupertinoLocLabel.accessibilityIdentifier = "coordinateSettingsViewControllerCupertinoLocLabel"
        realLocSwitch.accessibilityIdentifier = "coordinateSettingsViewControllerRealLocSwitch"
        realLocLabel.accessibilityIdentifier = "coordinateSettingsViewControllerRealLocLabel"
        setCustomLocLabel.accessibilityIdentifier = "coordinateSettingsViewControllerSetCustomLocLabel"
        inputSwitch.accessibilityIdentifier = "coordinateSettingsViewControllerInputSwitch"
        inputLabel.accessibilityIdentifier = "coordinateSettingsViewControllerInputLabel"
        filterSwitch.accessibilityIdentifier = "coordinateSettingsViewControllerFilterSwitchSwitch"
        filterLabel.accessibilityIdentifier = "coordinateSettingsViewControllerFilterLabel"
        showEVFiltersButton.accessibilityIdentifier = "coordinateSettingsViewControllerShowEVFiltersButton"
        versionLabel.accessibilityIdentifier = "coordinateSettingsViewControllerVersionLabel"
        scrollView.accessibilityIdentifier = "coordinateSettingsViewControllerScrollView"
        pickerView.accessibilityIdentifier = "coordinateSettingsViewControllerPickerView"
        pickerToolbar.accessibilityIdentifier = "coordinateSettingsViewControllerPickerToolbar"
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func showFilterAction(_ sender: Any) {
        navigationController?.pushViewController(filtersVC, animated: true)
    }
    
    @IBAction func cupertinoLocSwitchStateChange(_ sender: UISwitch) {
        realLocSwitch.isOn = !cupertinoLocSwitch.isOn
        inputSwitch.isOn = false
        if cupertinoLocSwitch.isOn {
            LocationProvider.shared.fakeLocation(location: DemoConstants.defaultLocation)
        }
        defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
        defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
        defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
    }
    
    @IBAction func realLocSwitchStateChange(_ sender: UISwitch) {
        cupertinoLocSwitch.isOn = !realLocSwitch.isOn
        inputSwitch.isOn = false
        if realLocSwitch.isOn {
            LocationProvider.shared.fakeLocation(location: nil)
        }
        defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
        defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
        defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
    }
    
    @IBAction func inputLocSwitchStateChange(_ sender: UISwitch) {
        
        guard let _ = Double(latTextField.text ?? ""),
              let _ = Double(lngTextField.text ?? "") else {
            inputSwitch.isOn = false
            realLocSwitchStateChange(realLocSwitch)
            return
        }
        
        if inputSwitch.isOn {
            LocationProvider.shared.fakeLocation(location: location)
          
            realLocSwitch.isOn = false
            cupertinoLocSwitch.isOn = false
                
            defaults.set(latTextField.text, forKey: "lat")
            defaults.set(lngTextField.text, forKey: "lng")
            defaults.set(cupertinoLocSwitch.isOn, forKey: "cupertino_loc_switch")
            defaults.set(realLocSwitch.isOn, forKey: "real_loc_switch")
            defaults.set(inputSwitch.isOn, forKey: "input_loc_switch")
        } else {
            cupertinoLocSwitch.isOn = false
            realLocSwitch.isOn = true
            realLocSwitchStateChange(realLocSwitch)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func checkApplyButtonEnabled(for string: String?) -> Bool {
        guard let string = string else {
            return false
        }
        if string.count > 0 && !string.contains(where: { (char) -> Bool in
            !char.isNumber && char != "-" && char != "."
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

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
//        if textField == regionTextField {
//            pickerView?.isHidden = false
//            pickerToolbar?.isHidden = false
//            pickerView?.reloadAllComponents()
//            let height = pickerView.frame.height
//            let insets = UIEdgeInsets(top: 0, left: 0,
//                                      bottom: height, right: 0)
//            scrollView.contentInset = insets
//            var aRect = self.view.frame;
//            aRect.size.height -= height;
//            if !aRect.contains(regionTextField.frame.origin) {
//                let y = regionTextField.frame.origin.y - height
//                scrollView.setContentOffset(CGPoint(x: 0,y: y), animated: true)
//            }
//        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveCoordinates()
    }
    
    func saveCoordinates() {
        defaults.set(latTextField.text, forKey: "lat")
        defaults.set(lngTextField.text, forKey: "lng")
        
        guard let lat = Double(latTextField.text ?? ""),
              let lng = Double(lngTextField.text ?? ""),
              inputSwitch.isOn else {
            return
        }
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        LocationProvider.shared.fakeLocation(location: location)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        activeField?.resignFirstResponder()
        activeField = nil
        return true
    }
    
    func setupKeyboardAppearance() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                           name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                           name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardDidHide(notification:)),
                           name: UIResponder.keyboardDidHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.dismissInputView (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            regionBottomConstraint.constant = keyboardSize.height
            if activeField == regionTextField {
                pickerView?.isHidden = false
                pickerToolbar?.isHidden = false
                pickerView?.reloadAllComponents()
                scrollView.setContentOffset(CGPoint(x: 0, y: keyboardSize.height), animated: true)
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    @objc private func keyboardDidHide(notification: NSNotification) {
        regionBottomConstraint.constant = 20
    }
    @objc func dismissInputView (_ sender: UITapGestureRecognizer) {
        activeField?.resignFirstResponder()
        activeField = nil
        saveCoordinates()
    }
}

// Picker
extension CoordinateSettingsController: UIPickerViewDataSource, UIPickerViewDelegate
{
    var pickerSource: [String] {
        return [
            "NA",
            "EU"
        ]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        return pickerSource.count
    }

    func pickerView( _ pickerView: UIPickerView,
                     titleForRow row: Int,
                     forComponent component: Int) -> String? {
        return pickerSource[row]
    }
    
    func recreateNavigationSDK(withRegion region: String) {
        var cloudEndPoint = "https://apinastg.telenav.com/"
        switch region {
        case "EU":
            cloudEndPoint = "https://apieustg.telenav.com/"
        default:
            break
        }
        if let oldOptions = VNSDK.sharedInstance.sdkOptions,
           oldOptions.region != region,
           let newOptions = VNSDKOptions.builder()
            .apiKey(oldOptions.apiKey ?? "")
            .apiSecret(oldOptions.apiSecret ?? "")
            .cloudEndPoint(cloudEndPoint)
            .region(region)
            .build() {
            delegate?.regionDidChange(region: region)
            VNSDK.sharedInstance.dispose()
            VNSDK.sharedInstance.initialize(with: newOptions)
        }
    }
    
    @IBAction func onPickerDone(_ sender: Any) {
        let row = pickerView.selectedRow(inComponent: 0)
        regionTextField.text = pickerSource[row]
        recreateNavigationSDK(withRegion: pickerSource[row])
        regionTextField.resignFirstResponder()
    }
}
