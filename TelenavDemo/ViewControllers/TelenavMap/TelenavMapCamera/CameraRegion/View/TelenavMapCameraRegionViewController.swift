//
//  TelenavMapCamera.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividMapSDK

class TelenavMapCameraRegionViewController: UIViewController, Storyboardable {
    @IBOutlet private var tableView: UITableView!
    
    var cameraRegion: VNCameraRegion!
    var cameraRegionDidChange: ((_ position: VNCameraRegion) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView(tableView)
        configureNavigationBar()
    }
    
    private func configureTableView(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "CameraRegionCell", bundle: nil),
            forCellReuseIdentifier: "CameraRegionCell"
        )
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .plain,
            target: self,
            action: #selector(applyAction)
        )
    }
}

// nav bar
extension TelenavMapCameraRegionViewController {
    @objc func applyAction(_ sender: Any) {
        cameraRegionDidChange?(cameraRegion)
    }
}

extension TelenavMapCameraRegionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraRegionCell") as! CameraRegionCell
        cell.northLatitude = cameraRegion.northLatitude
        cell.eastLongitude = cameraRegion.eastLongitude
        cell.southLatitude = cameraRegion.southLatitude
        cell.westLongitude = cameraRegion.westLongitude
        cell.regionDidChange = { [weak self] nLa, wLo, sLa, eLo in
            self?.checkRegionParam(nLa: nLa, wLo: wLo, sLa: sLa, eLo: eLo)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Camera region"
    }
    
    func checkRegionParam(nLa: Double?, wLo: Double?, sLa: Double?, eLo: Double?) {
        if let nLa = nLa, let wLo = wLo, let sLa = sLa, let eLo = eLo {
            cameraRegion = VNCameraRegion(
                northLatitude: nLa,
                westLongitude: wLo,
                southLatitude: sLa,
                eastLongitude: eLo
            )
            
            if cameraRegion.isValid() {
                navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}
