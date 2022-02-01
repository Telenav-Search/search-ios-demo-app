//
//  TelenavMapSettingsViewController.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividDriveSessionSDK

protocol TelenavMapSettingsViewControllerDelegate: AnyObject {
    func mapSettingsDidChange(vc: TelenavMapSettingsViewController, settings: TelenavMapSettingsModel)
}

class TelenavMapSettingsViewController: UIViewController, Storyboardable {
    @IBOutlet private var tableView: UITableView!

    var mapSettings: TelenavMapSettingsModel = TelenavMapSettingsModel() {
        didSet {
            verticalOffset = "\(mapSettings.verticalOffset)"
            horizontalOffset = "\(mapSettings.horizontalOffset)"
        }
    }
    weak var delegate: TelenavMapSettingsViewControllerDelegate?
    
    private let availableGestureTypes: [VNGestureType] = [
        .auto,
        .pan,
        .panAndZoom,
        .panAndZoomAndRotate,
        .rotate,
        .tilt,
        .zoom,
        .zoomAndRotate
    ]
    private var verticalOffset: String?
    private var horizontalOffset: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView(tableView)
        configureNavigationBar()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissInputView (_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupKeyboardListener()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        freeKeyboardListener()
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .plain,
            target: self,
            action: #selector(applyAction)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "telenavMapSettingsViewControllerApplyButton"
        navigationItem.backBarButtonItem?.accessibilityIdentifier = "telenavMapSettingsViewControllerBackButton"
    }
    
    private func configureTableView(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "ToggleableTableViewCell", bundle: nil),
            forCellReuseIdentifier: "ToggleableTableViewCell"
        )
        tableView.register(
            UINib(nibName: "TexteditableTableViewCell", bundle: nil),
            forCellReuseIdentifier: "TexteditableTableViewCell"
        )
        tableView.register(
            UINib(nibName: "DataSelectionTableViewCell", bundle: nil),
            forCellReuseIdentifier: "DataSelectionTableViewCell"
        )
        tableView.register(
            UINib(nibName: "CustomLocationTableViewCell", bundle: nil),
            forCellReuseIdentifier: "CustomLocationTableViewCell"
        )
        tableView.accessibilityIdentifier = "telenavMapSettingsViewControllerTableView"
    }
    
    private func setupKeyboardListener() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        /*
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.dismissInputView (_:)))
        self.view.addGestureRecognizer(tapGesture)
        */
    }
    
    private func freeKeyboardListener() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// actions
extension TelenavMapSettingsViewController {
    @objc func applyAction(_ sender: Any) {
        if let vOffset = Double(verticalOffset ?? ""),
           let hOffset = Double(horizontalOffset ?? "") {
            mapSettings.horizontalOffset = hOffset
            mapSettings.verticalOffset = vOffset
            delegate?.mapSettingsDidChange(vc: self, settings: mapSettings)
        } else {
            let alert = UIAlertController(title: "Error", message: "Settings are incorrect", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                self.tableView.contentInset = .init(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                self.tableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.tableView.contentInset = .zero
            self.tableView.scrollIndicatorInsets = .zero
        }
    }
    
    @objc func dismissInputView (_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
}

extension TelenavMapSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 8
        case 2:
            return 2
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return gestureParam(tableView: tableView, by: indexPath)
        case 1:
            return featureParam(tableView: tableView, by: indexPath)
        case 2:
            return layoutParam(tableView: tableView, by: indexPath)
        case 3:
            return mapDataParam(tableView: tableView, by: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Map gestures"
        case 1:
            return "Map features"
        case 2:
            return "Map layout"
        case 3:
            return "Map data"
        default:
            return ""
        }
    }
    
    private func gestureParam(tableView: UITableView, by indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataSelectionTableViewCell") as! DataSelectionTableViewCell
        guard let indexOfSelectedItem = availableGestureTypes.firstIndex(of: mapSettings.gestureType) else {
            // wrong data
            return UITableViewCell()
        }
        
        cell.titleLabel.text = "Available gestures"
        cell.textField.text = availableGestureTypes[indexOfSelectedItem].string
        cell.setItems(availableGestureTypes.map { $0.string }, selectedItemIndex: indexOfSelectedItem)
        cell.onSelectedItemIndexChange = { [weak self, weak cell] index in
            guard let self = self, let cell = cell else { return }
            self.mapSettings.gestureType = self.availableGestureTypes[index]
            cell.textField.text = self.availableGestureTypes[index].string
        }
        return cell
    }
    
    private func featureParam(tableView: UITableView, by indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show traffic"
            cell.isOn = mapSettings.isTrafficOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isTrafficOn = isOn
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show landmarks"
            cell.isOn = mapSettings.isLandmarksOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isLandmarksOn = isOn
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show buildings"
            cell.isOn = mapSettings.isBuildingsOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isBuildingsOn = isOn
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show terrain"
            cell.isOn = mapSettings.isTerrainOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isTerrainOn = isOn
            }
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show globe"
            cell.isOn = mapSettings.isGlobeOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isGlobeOn = isOn
            }
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show the compass"
            cell.isOn = mapSettings.isCompassOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isCompassOn = isOn
            }
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
            cell.titleLabel.text = "Show the scale bar"
            cell.isOn = mapSettings.isScaleBarOn
            cell.switchChanged = { [weak self] isOn in
                self?.mapSettings.isScaleBarOn = isOn
            }
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomLocationTableViewCell") as! CustomLocationTableViewCell
            cell.titleLabel.text = "ADI Line End point"
            cell.setLocation(mapSettings.endPoint, isOn: mapSettings.isEndPointOn)
            cell.stateChanged = { [weak self] location, isOn in
                self?.mapSettings.endPoint = location
                self?.mapSettings.isEndPointOn = isOn
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    private func layoutParam(tableView: UITableView, by indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TexteditableTableViewCell") as! TexteditableTableViewCell
            cell.titleLabel.text = "Layout's vertical offset"
            cell.textField.text = verticalOffset ?? ""
            cell.textDidChanged = { [weak self] text in
                self?.verticalOffset = text
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TexteditableTableViewCell") as! TexteditableTableViewCell
            cell.titleLabel.text = "Layout's horizontal offset"
            cell.textField.text = horizontalOffset ?? ""
            cell.textDidChanged = { [weak self] text in
                self?.horizontalOffset = text
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    private func mapDataParam(tableView: UITableView, by indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleableTableViewCell") as! ToggleableTableViewCell
        cell.titleLabel.text = "Listen to the map state"
        cell.isOn = mapSettings.isListenMapViewDataOn
        cell.switchChanged = { [weak self] isOn in
            self?.mapSettings.isListenMapViewDataOn = isOn
        }
        return cell
    }
}

extension VNGestureType {
    var string: String {
        switch self {
        case .auto:
            return "Auto"
        case .pan:
            return "Pan"
        case .panAndZoom:
            return "Pan and Zoom"
        case .panAndZoomAndRotate:
            return "Pan and Zoom and Rotate"
        case .rotate:
            return "Rotate"
        case .tilt:
            return "Tilt"
        case .zoom:
            return "Zoom"
        case .zoomAndRotate:
            return "Zoom and rotate"
        default:
            return "unknown"
        }
    }
}
