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
    
    weak var delegate: DirectionDetailsViewControllerDelegate?
    
    var routeSettings = RouteSettings() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        tableView?.dataSource = self
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
    }
    
    @IBAction func onApplySettings(_ sender: Any) {
        readSettingsFromFields()
        delegate?.directionDetails(self, didUpdateSettings: routeSettings)
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.delegate?.onBackButtonOfDirectionDetails(self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        switch indexPath.row {
        case 0, 1, 2, 3:
            cell = tableView.dequeueReusableCell(withIdentifier: "DirectionSettingsTextTableViewCell")
            (cell as? DirectionSettingsTextTableViewCell)?.textField.delegate = self
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
        default:
            return UITableViewCell()
        }
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
}
