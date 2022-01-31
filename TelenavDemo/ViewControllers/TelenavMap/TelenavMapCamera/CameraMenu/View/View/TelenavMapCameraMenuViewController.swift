//
//  TelenavMapCamera.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividDriveSessionSDK

class TelenavMapCameraMenuViewController: UIViewController, Storyboardable {
    @IBOutlet private var tableView: UITableView!
    
    var menuCameraPositionTapped: (() -> Void)?
    var menuCameraRegionTapped: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView(tableView)
    }
    
    private func configureTableView(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UINib(nibName: "CameraMenuCell", bundle: nil),
            forCellReuseIdentifier: "CameraMenuCell"
        )
        tableView.accessibilityIdentifier = "telenavMapCameraMenuViewControllerTableView"
        navigationItem.backBarButtonItem?.accessibilityIdentifier = "telenavMapCameraMenuViewControllerBackButton"
    }
}

extension TelenavMapCameraMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraMenuCell")!
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Position"
            cell.accessoryType = .disclosureIndicator
        } else
        if (indexPath.row == 1) {
            cell.textLabel?.text = "Region"
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Camera menu"
    }
}

extension TelenavMapCameraMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0 {
            menuCameraPositionTapped?()
        } else
        if indexPath.row == 1 {
            menuCameraRegionTapped?()
        }
    }
}
