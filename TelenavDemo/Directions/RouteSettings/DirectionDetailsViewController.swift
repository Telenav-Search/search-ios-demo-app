//
//  DirectionDetailsViewController.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 22.07.2021.
//

import UIKit
import VividNavigationSDK

protocol DirectionDetailsViewControllerDelegate: AnyObject {
    
    func onBackButtonOfDirectionDetails(_ viewController: DirectionDetailsViewController)
    
    func directionDetails(_ viewController: DirectionDetailsViewController,
                          didUpdateSettings settings: RouteSettings)
}

class DirectionDetailsViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView?
    
    var regionCell: DirectionSettingsTextTableViewCell?
    var routesCountCell: DirectionSettingsTextTableViewCell?
    var headingCell: DirectionSettingsTextTableViewCell?
    var speedCell: DirectionSettingsTextTableViewCell?
    var routeStyleCell: DirectionSettingsPickTableViewCell?
    var contentLevelCell: DirectionSettingsPickTableViewCell?
    var avoidHOVLaneCell: DirectionSettingsSwitchTableViewCell?
    
    @IBOutlet weak var pickerView: UIPickerView?
    var selectedPickCell: DirectionSettingsPickTableViewCell?
    var pickerSource = [String]()
    
    weak var delegate: DirectionDetailsViewControllerDelegate?
    
    var routeSettings = RouteSettings() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        tableView?.dataSource = self
        pickerView?.dataSource = self
        pickerView?.delegate = self
        setupKeyboardAppearance()
    }
    
    func readSettingsFromFields() {
        if let region = regionCell?.textField.text {
            routeSettings.region = region
        }
        if let count = Int32(routesCountCell?.textField.text ?? "") {
            routeSettings.routeCount = count
        }
        if let heading = Int32(headingCell?.textField.text ?? "") {
            routeSettings.heading = heading
        }
        if let speed = Int32(speedCell?.textField.text ?? "") {
            routeSettings.speed = speed
        }
        if let style = routeStyleCell?.intValue {
            routeSettings.routeStyle = VNRouteStyle(rawValue: UInt(style)) ?? .fastest
        }
        if let level = contentLevelCell?.intValue {
            routeSettings.contentLevel = VNContentLevel(rawValue: UInt(level)) ?? .full
        }
        routeSettings.preferences.avoidHovLanes = avoidHOVLaneCell?.switchControl.isOn ?? false
    }
    
    @IBAction func onApplySettings(_ sender: Any) {
        readSettingsFromFields()
        delegate?.directionDetails(self, didUpdateSettings: routeSettings)
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.delegate?.onBackButtonOfDirectionDetails(self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 6
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0, 1, 2, 3:
                cell = tableView.dequeueReusableCell(withIdentifier: "DirectionSettingsTextTableViewCell")
                (cell as? DirectionSettingsTextTableViewCell)?.textField.delegate = self
            case 4, 5:
                cell = tableView.dequeueReusableCell(withIdentifier: "DirectionSettingsPickTableViewCell")
                (cell as? DirectionSettingsPickTableViewCell)?.textField.inputView = pickerView
                (cell as? DirectionSettingsPickTableViewCell)?.textField.delegate = self
            default:
                cell = UITableViewCell()
            }
            switch indexPath.row {
            case 0:
                regionCell = cell as? DirectionSettingsTextTableViewCell
                regionCell?.label.text = "Region"
                regionCell?.textField.text = routeSettings.region
                regionCell?.descriptionLabel.text = "Region name. The default value is NA."
                return regionCell!
            case 1:
                routesCountCell = cell as? DirectionSettingsTextTableViewCell
                routesCountCell?.label.text = "Number of routes"
                routesCountCell?.textField.text = "\(routeSettings.routeCount)"
                routesCountCell?.descriptionLabel.text = "The maximum route count requested."
                return routesCountCell!
            case 2:
                headingCell = cell as? DirectionSettingsTextTableViewCell
                headingCell?.label.text = "Heading"
                headingCell?.textField.text = "\(routeSettings.heading)"
                headingCell?.descriptionLabel.text = "Heading angle of the vehicle, based on the north clockwise. By default is -1 (unspecific heading)"
                return headingCell!
            case 3:
                speedCell = cell as? DirectionSettingsTextTableViewCell
                speedCell?.label.text = "Speed"
                speedCell?.textField.text = "\(routeSettings.speed)"
                speedCell?.descriptionLabel.text = "Set the speed of the vehicle in Mps. Default is 0"
                return speedCell!
            case 4:
                routeStyleCell = cell as? DirectionSettingsPickTableViewCell
                routeStyleCell?.label.text = "Style of route"
                routeStyleCell?.intValue = Int(routeSettings.routeStyle.rawValue)
                routeStyleCell?.textField.text = RouteSettings.label(forRouteStyle: routeSettings.routeStyle)
                routeStyleCell?.descriptionLabel.text = "Set route style. Default is Fastest"
                return routeStyleCell!
            case 5:
                contentLevelCell = cell as? DirectionSettingsPickTableViewCell
                contentLevelCell?.label.text = "Level of content"
                contentLevelCell?.intValue = Int(routeSettings.contentLevel.rawValue)
                contentLevelCell?.textField.text = RouteSettings.label(forContentLevel: routeSettings.contentLevel)
                contentLevelCell?.descriptionLabel.text = "The content's level of detail. Default is Full"
                return contentLevelCell!
            default:
                return UITableViewCell()
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "DirectionSettingsSwitchTableViewCell")
            (cell as? DirectionSettingsSwitchTableViewCell)?.switchControl
                .addTarget(self,
                           action: #selector(switchStateDidChange(switchControl:)),
                           for: .valueChanged)
            switch indexPath.row {
            case 0:
                avoidHOVLaneCell = cell as? DirectionSettingsSwitchTableViewCell
                avoidHOVLaneCell?.label.text = "Avoid HOV Lanes"
                avoidHOVLaneCell?.switchControl.isOn = routeSettings.preferences.avoidHovLanes
                return avoidHOVLaneCell!
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Preferences"
        }
        return nil
    }
    
    @objc func switchStateDidChange(switchControl: UISwitch) {
        readSettingsFromFields()
    }
}

// Keyboard appearance
extension DirectionDetailsViewController: UITextFieldDelegate {
    
    func setupKeyboardAppearance() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView?.contentInset = .zero
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        regionCell?.textField.resignFirstResponder()
        routesCountCell?.textField.resignFirstResponder()
        headingCell?.textField.resignFirstResponder()
        speedCell?.textField.resignFirstResponder()
        readSettingsFromFields()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        readSettingsFromFields()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        pickerSource = [String]()
        if textField == routeStyleCell?.textField {
            selectedPickCell = routeStyleCell
            for i: UInt in 0...4 {
                let style = VNRouteStyle(rawValue: i) ?? .fastest
                pickerSource.append(RouteSettings.label(forRouteStyle: style))
            }
            pickerView?.isHidden = false
            pickerView?.reloadAllComponents()
            return
        }
        if textField == contentLevelCell?.textField {
            selectedPickCell = contentLevelCell
            for i: UInt in 0...2 {
                let level = VNContentLevel(rawValue: i) ?? .full
                pickerSource.append(RouteSettings.label(forContentLevel: level))
            }
            pickerView?.isHidden = false
            pickerView?.reloadAllComponents()
            return
        }
    }
}


extension DirectionDetailsViewController: UIPickerViewDelegate, UIPickerViewDataSource
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        return pickerSource.count
    }

    func pickerView( _ pickerView: UIPickerView,
                     titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerSource[row]
    }

    func pickerView( _ pickerView: UIPickerView,
                     didSelectRow row: Int,
                     inComponent component: Int) {
        if selectedPickCell == routeStyleCell {
            let style = VNRouteStyle(rawValue: UInt(row)) ?? .fastest
            routeStyleCell?.textField.text = RouteSettings.label(forRouteStyle: style)
            routeStyleCell?.intValue = Int(style.rawValue)
        }
        if selectedPickCell == contentLevelCell {
            let level = VNContentLevel(rawValue: UInt(row)) ?? .full
            contentLevelCell?.textField.text = RouteSettings.label(forContentLevel: level)
            contentLevelCell?.intValue = Int(level.rawValue)
        }
        readSettingsFromFields()
    }
}
