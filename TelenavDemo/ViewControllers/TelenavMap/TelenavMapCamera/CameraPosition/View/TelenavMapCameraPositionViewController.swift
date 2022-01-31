//
//  TelenavMapCamera.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividDriveSessionSDK

class TelenavMapCameraPositionViewController: UIViewController, Storyboardable {
    @IBOutlet private var tableView: UITableView!
    
    var cameraPosition: VNCameraPosition!
    var cameraPositionDidChange: ((_ position: VNCameraPosition) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView(tableView)
        configureNavigationBar()
    }
    
    private func configureTableView(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "CameraPositionCell", bundle: nil),
            forCellReuseIdentifier: "CameraPositionCell"
        )
        tableView.accessibilityIdentifier = "telenavMapCameraPositionViewControllerTableView"
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .plain,
            target: self,
            action: #selector(applyAction)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "telenavMapCameraPositionViewControllerApplyButton"
        navigationItem.backBarButtonItem?.accessibilityIdentifier = "telenavMapCameraPositionViewControllerBackButton"
    }
}

// nav bar
extension TelenavMapCameraPositionViewController {
    @objc func applyAction(_ sender: Any) {
        cameraPositionDidChange?(cameraPosition)
    }
}

extension TelenavMapCameraPositionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraPositionCell") as! CameraPositionCell
        cell.la = cameraPosition.location?.latitude ?? 0
        cell.lo = cameraPosition.location?.longitude ?? 0
        cell.bearing = cameraPosition.bearing?.doubleValue ?? 0
        cell.zoom = cameraPosition.zoomLevel?.doubleValue ?? 0
        cell.tilt = cameraPosition.tilt?.doubleValue ?? 0
        
        cell.positionDidChanged = { [weak self] la, lo, zoom, tilt, bearing in
            self?.checkPositionParam(la: la, lo: lo, zoom: zoom, tilt: tilt, bearing: bearing)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Camera position"
    }
    
    func checkPositionParam(la: String, lo: String, zoom: Float, tilt: Float, bearing: Float) {
        if let la = Float(la), let lo = Float(lo) {
            let location = VNGeoPoint(latitude: Double(la), longitude: Double(lo))
            let position = VNCameraPosition(
                bearing: NSNumber(floatLiteral: Double(bearing)),
                tilt: NSNumber(floatLiteral: Double(tilt)),
                zoomLevel: NSNumber(floatLiteral: Double(zoom)),
                location: location
            )
            
            cameraPosition = position
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}
