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
    var startDateCell: DirectionSettingsPickTableViewCell?
    
    var preferencesCells = [Int: DirectionSettingsSwitchTableViewCell]()
    
    @IBOutlet weak var pickerView: UIPickerView?
    var selectedPickCell: DirectionSettingsPickTableViewCell?
    var pickerSource = [String]()
    
    @IBOutlet weak var datePicker: UIDatePicker?
    weak var delegate: DirectionDetailsViewControllerDelegate?
    
    var routeSettings = RouteSettings() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        tableView?.dataSource = self
        pickerView?.dataSource = self
        pickerView?.delegate = self
        datePicker?.addTarget(self, action: #selector(onDatePickerChanged), for: .valueChanged)
        setupKeyboardAppearance()
    }
    
    @objc func onDatePickerChanged() {
        if let date = datePicker?.date {
            startDateCell?.textField.text = dateFormatter.string(from: date)
            readSettingsFromFields()
        }
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
        if let dateString = startDateCell?.textField.text,
           let date = dateFormatter.date(from: dateString) {
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
            return 7
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
                regionCell = tableView.dequeueReusableCell(withIdentifier: "Region") as? DirectionSettingsTextTableViewCell
                regionCell?.textField.delegate = self
                regionCell?.textField.text = routeSettings.region
                return regionCell!
            case 1:
                routesCountCell = tableView.dequeueReusableCell(withIdentifier: "RouteCount") as? DirectionSettingsTextTableViewCell
                routesCountCell?.textField.delegate = self
                routesCountCell?.textField.text = "\(routeSettings.routeCount)"
                return routesCountCell!
            case 2:
                headingCell = tableView.dequeueReusableCell(withIdentifier: "Heading") as? DirectionSettingsTextTableViewCell
                headingCell?.textField.delegate = self
                headingCell?.textField.text = "\(routeSettings.heading)"
                return headingCell!
            case 3:
                speedCell = tableView.dequeueReusableCell(withIdentifier: "Speed") as? DirectionSettingsTextTableViewCell
                speedCell?.textField.delegate = self
                speedCell?.textField.text = "\(routeSettings.speed)"
                return speedCell!
            case 4:
                routeStyleCell = tableView.dequeueReusableCell(withIdentifier: "RouteStyle") as? DirectionSettingsPickTableViewCell
                routeStyleCell?.textField.inputView = pickerView
                routeStyleCell?.textField.delegate = self
                routeStyleCell?.intValue = Int(routeSettings.routeStyle.rawValue)
                routeStyleCell?.textField.text = RouteSettings.label(forRouteStyle: routeSettings.routeStyle)
                return routeStyleCell!
            case 5:
                contentLevelCell = tableView.dequeueReusableCell(withIdentifier: "ContentLevel") as? DirectionSettingsPickTableViewCell
                contentLevelCell?.textField.inputView = pickerView
                contentLevelCell?.textField.delegate = self
                contentLevelCell?.intValue = Int(routeSettings.contentLevel.rawValue)
                contentLevelCell?.textField.text = RouteSettings.label(forContentLevel: routeSettings.contentLevel)
                return contentLevelCell!
            case 6:
                startDateCell = tableView.dequeueReusableCell(withIdentifier: "StartDate") as? DirectionSettingsPickTableViewCell
                startDateCell?.textField.inputView = datePicker
                startDateCell?.textField.delegate = self
                if let date = routeSettings.startDate {
                    startDateCell?.textField.text = dateFormatter.string(from: date)
                } else {
                    startDateCell?.textField.text = ""
                }
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
        if textField == startDateCell?.textField {
            datePicker?.isHidden = false
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
