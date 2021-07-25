//
//  DirectionDetailsViewController.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 22.07.2021.
//

import UIKit

class DirectionDetailsViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var regionCell: DirectionSettingsTextTableViewCell?
    var routesNumberCell: DirectionSettingsTextTableViewCell?
    var headingCell: DirectionSettingsTextTableViewCell?
    var speedCell: DirectionSettingsTextTableViewCell?
    
    override func viewDidLoad() {
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        regionCell?.textField.resignFirstResponder()
        routesNumberCell?.textField.resignFirstResponder()
        headingCell?.textField.resignFirstResponder()
        speedCell?.textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func onApplySettings(_ sender: Any) {
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
            regionCell?.textField.text = "NA"
            regionCell?.descriptionLabel.text = "Region name. The default value is NA."
            return regionCell!
        case 1:
            routesNumberCell = cell as? DirectionSettingsTextTableViewCell
            routesNumberCell?.label.text = "Number of routes"
            routesNumberCell?.textField.text = "1"
            routesNumberCell?.descriptionLabel.text = "The maximum route count requested."
            return routesNumberCell!
        case 2:
            headingCell = cell as? DirectionSettingsTextTableViewCell
            headingCell?.label.text = "Heading"
            headingCell?.textField.text = "-1"
            headingCell?.descriptionLabel.text = "Heading angle of the vehicle, based on the north clockwise. By default is -1 (unspecific heading)"
            return headingCell!
        case 3:
            speedCell = cell as? DirectionSettingsTextTableViewCell
            speedCell?.label.text = "Speed"
            speedCell?.textField.text = "0"
            speedCell?.descriptionLabel.text = "Set the speed of the vehicle in Mps. Default is 0"
            return speedCell!
        default:
            return UITableViewCell()
        }
    }
    
}
