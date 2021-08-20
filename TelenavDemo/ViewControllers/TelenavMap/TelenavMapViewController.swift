//
//  TelenavMapViewController.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividMapSDK

class TelenavMapViewController: UIViewController {
    var mapViewSettingsModel = TelenavMapSettingsModel()
    var map: VNMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Telenav Map"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(showSettingsAction)
        )
        
        map = VNMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: guide.topAnchor),
            map.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            map.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
        
        setupMapFeatures(settings: mapViewSettingsModel)
    }
    
    func setupMapFeatures(settings: TelenavMapSettingsModel) {
        let features = map.featuresController()
        
        settings.isTerrainOn ? features.terrain.setEnabled() : features.terrain.setDisabled()
        settings.isBuildingsOn ? features.buildings.setEnabled() : features.buildings.setDisabled()
        settings.isGlobeOn ? features.globe.setEnabled() : features.globe.setDisabled()
        settings.isCompassOn ? features.compass.setEnabled() : features.compass.setDisabled()
        settings.isLandmarksOn ? features.landmarks.setEnabled() : features.landmarks.setDisabled()
        settings.isScaleBarOn ? features.scaleBar.setEnabled() : features.scaleBar.setDisabled()
        settings.isTrafficOn ? features.traffic.setEnabled() : features.traffic.setDisabled()
        
        if let endPoint = settings.endPoint, settings.isEndPointOn {
            features.adiLine.setEnabledEndPoint(endPoint)
        } else {
            features.adiLine.setDisabled()
        }
        
        map.setActiveGestures(settings.gestureType)
    }
}

// actions
extension TelenavMapViewController {
    @IBAction func showSettingsAction(_ sender: Any) {
        let vc = TelenavMapSettingsViewController.storyboardViewController()
        vc.delegate = self
        vc.mapSettings = mapViewSettingsModel
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension TelenavMapViewController: TelenavMapSettingsViewControllerDelegate {
    func mapSettingsDidChange(vc: TelenavMapSettingsViewController, settings: TelenavMapSettingsModel) {
        mapViewSettingsModel = settings
        
        setupMapFeatures(settings: settings)
        navigationController?.popViewController(animated: true)
    }
}
