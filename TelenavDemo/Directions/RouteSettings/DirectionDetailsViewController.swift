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
    
    func isRouteCalculated() -> Bool
}

class DirectionDetailsViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView?
    
    var routesCountCell: DirectionSettingsTextTableViewCell?
    var headingCell: DirectionSettingsTextTableViewCell?
    var speedCell: DirectionSettingsTextTableViewCell?
    
    var routeStyleCell: DirectionSettingsPickTableViewCell?
    var contentLevelCell: DirectionSettingsPickTableViewCell?
    var startDateCell: DirectionSettingsDateTableViewCell?
    
    var preferencesCells = [Int: DirectionSettingsSwitchTableViewCell]()
    
    @IBOutlet weak var applyButton: UIButton?
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
        if let delegate = delegate,
           delegate.isRouteCalculated() {
            applyButton?.setTitle("Apply settings", for: .normal)
        } else {
            applyButton?.setTitle("Save settings", for: .normal)
        }
        setupKeyboardAppearance()
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onDatePickerChanged() {
        readSettingsFromFields()
    }
    
    func readSettingsFromFields() {
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
        if let date = startDateCell?.datePicker.date {
            routeSettings.startDate = date
        }
        for i in 0..<preferencesCells.count {
            let cell = preferencesCells[i]
            routeSettings.set(preference: cell!.switchControl.isOn, atIndex: UInt(i))
        }
    }
    
    @IBAction func onApplySettings(_ sender: Any) {
        readSettingsFromFields()
        delegate?.directionDetails(self, didUpdateSettings: routeSettings)
    }
    
    @IBAction func onReset(_ sender: Any) {
        routeSettings = RouteSettings()
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
            return RouteSettings.preferencesLabels.count
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell: UITableViewCell?
            switch indexPath.row {
            case 4, 5:
                cell = tableView.dequeueReusableCell(withIdentifier: "RouteStyle")
                (cell as? DirectionSettingsPickTableViewCell)?.textField.inputView = pickerView
                (cell as? DirectionSettingsPickTableViewCell)?.textField.delegate = self
            default:
                cell = UITableViewCell()
            }
            switch indexPath.row {
            case 0:
                routesCountCell = tableView.dequeueReusableCell(withIdentifier: "RouteCount") as? DirectionSettingsTextTableViewCell
                routesCountCell?.textField.delegate = self
                routesCountCell?.textField.text = "\(routeSettings.routeCount)"
                return routesCountCell!
            case 1:
                headingCell = tableView.dequeueReusableCell(withIdentifier: "Heading") as? DirectionSettingsTextTableViewCell
                headingCell?.textField.delegate = self
                headingCell?.textField.text = "\(routeSettings.heading)"
                return headingCell!
            case 2:
                speedCell = tableView.dequeueReusableCell(withIdentifier: "Speed") as? DirectionSettingsTextTableViewCell
                speedCell?.textField.delegate = self
                speedCell?.descriptionLabel.text = routeSettings.speedDescriptionLabel
                speedCell?.textField.text = "\(routeSettings.speed)"
                return speedCell!
            case 3:
                routeStyleCell = tableView.dequeueReusableCell(withIdentifier: "RouteStyle") as? DirectionSettingsPickTableViewCell
                routeStyleCell?.textField.inputView = pickerView
                routeStyleCell?.textField.delegate = self
                routeStyleCell?.intValue = Int(routeSettings.routeStyle.rawValue)
                routeStyleCell?.textField.text = RouteSettings.label(forRouteStyle: routeSettings.routeStyle)
                return routeStyleCell!
            case 4:
                contentLevelCell = tableView.dequeueReusableCell(withIdentifier: "ContentLevel") as? DirectionSettingsPickTableViewCell
                contentLevelCell?.textField.inputView = pickerView
                contentLevelCell?.textField.delegate = self
                contentLevelCell?.intValue = Int(routeSettings.contentLevel.rawValue)
                contentLevelCell?.textField.text = RouteSettings.label(forContentLevel: routeSettings.contentLevel)
                return contentLevelCell!
            case 5:
                startDateCell = tableView.dequeueReusableCell(withIdentifier: "StartDate") as? DirectionSettingsDateTableViewCell
                startDateCell?.datePicker.addTarget(self,
                                                    action: #selector(onDatePickerChanged),
                                                    for: .valueChanged)
                startDateCell?.datePicker.date = routeSettings.startDate
                return startDateCell!
            default:
                return UITableViewCell()
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switch\(indexPath.row)") as? DirectionSettingsSwitchTableViewCell
            preferencesCells[indexPath.row] = cell
            cell?.switchControl.addTarget(self,
                                          action: #selector(switchStateDidChange(switchControl:)),
                                          for: .valueChanged)
            cell?.label.text = RouteSettings.label(forPreferenceAtIndex: indexPath.row)
            cell?.switchControl.isOn = routeSettings.preference(atIndex: indexPath.row)
            return cell!
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
            VNRouteStyle.demoAppStyles().forEach {
                pickerSource.append(RouteSettings.label(forRouteStyle: $0))
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

// Picker
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
            let routeStyle = VNRouteStyle.demoAppStyles()[row]
            routeStyleCell?.textField.text = RouteSettings.label(forRouteStyle: routeStyle)
            routeStyleCell?.intValue = Int(routeStyle.rawValue)
        }
        if selectedPickCell == contentLevelCell {
            let level = VNContentLevel(rawValue: UInt(row)) ?? .full
            contentLevelCell?.textField.text = RouteSettings.label(forContentLevel: level)
            contentLevelCell?.intValue = Int(level.rawValue)
        }
        readSettingsFromFields()
    }
}

extension VNRouteStyle {
    // Available styles in the demo app.
    static func demoAppStyles() -> [VNRouteStyle] {
        return [.fastest, .shortest, .easy]
    }
}
