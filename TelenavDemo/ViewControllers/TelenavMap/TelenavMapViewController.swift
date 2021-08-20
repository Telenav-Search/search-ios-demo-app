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
    var cameraRenderMode = VNCameraRenderMode.M2D
    
    lazy var cameraRenderModeButton: UIButton = {
        let cameraRenderModeButton = UIButton(type: .system)
        cameraRenderModeButton.translatesAutoresizingMaskIntoConstraints = false
        return cameraRenderModeButton
    }()
    
    lazy var cameraSettingsButton: UIButton = {
        let cameraSettingsButton = UIButton(type: .system)
        cameraSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        cameraSettingsButton.backgroundColor = .systemBackground
        cameraSettingsButton.setImage(UIImage(systemName: "viewfinder"), for: .normal)
        return cameraSettingsButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Telenav Map"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(showSettingsAction)
        )
        
        setupUI()
        setupMapFeatures(settings: mapViewSettingsModel)
    }
    
    func setupUI() {
        map = VNMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            map.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            map.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
        
        view.addSubview(cameraRenderModeButton)
        
        NSLayoutConstraint.activate([
            cameraRenderModeButton.widthAnchor.constraint(equalToConstant: 40),
            cameraRenderModeButton.heightAnchor.constraint(equalToConstant: 40),
            cameraRenderModeButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16.0),
            cameraRenderModeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        cameraRenderModeButtonUpdate(mode: cameraRenderMode)
        cameraRenderModeButton.setTitle("3D", for: .normal)
        cameraRenderModeButton.addTarget(self, action: #selector(cameraRenderModeButtonTapped), for: .touchUpInside)
        
        view.addSubview(cameraSettingsButton)
        
        NSLayoutConstraint.activate([
            cameraSettingsButton.widthAnchor.constraint(equalToConstant: 40),
            cameraSettingsButton.heightAnchor.constraint(equalToConstant: 40),
            cameraSettingsButton.bottomAnchor.constraint(equalTo: cameraRenderModeButton.topAnchor, constant: -16.0),
            cameraSettingsButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        cameraSettingsButton.addTarget(self, action: #selector(cameraSettingsButtonTapped), for: .touchUpInside)
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
        
        let layoutController = map.layoutController()
        layoutController.setOffsets(settings.horizontalOffset, vertical: settings.verticalOffset)
    }
    
    func cameraRenderModeButtonUpdate(mode: VNCameraRenderMode) {
        cameraRenderModeButton.backgroundColor = mode == .M2D ? .systemBackground : .systemGreen
        cameraRenderModeButton.setTitleColor(mode == .M2D ? .black : .white, for: .normal)
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
    
    @objc func cameraRenderModeButtonTapped() {
        cameraRenderMode = cameraRenderMode == .M2D ? .M3D : .M2D
        cameraRenderModeButtonUpdate(mode: cameraRenderMode)
        
        map.cameraController().renderMode = cameraRenderMode
    }
    
    @objc func cameraSettingsButtonTapped() {
        let vc = TelenavMapCameraMenuViewController.storyboardViewController()
        vc.menuCameraPositionTapped = { [weak self, weak vc] in
            guard let self = self, let vc = vc else {
                return
            }
            let positionVC = TelenavMapCameraPositionViewController.storyboardViewController()
            positionVC.cameraPosition = self.map.cameraController().position
            positionVC.cameraPositionDidChange = { [weak self, weak vc] position in
                guard let self = self else {
                    return
                }
                self.positionDidChange(position: position)
                vc?.navigationController?.popToViewController(self, animated: true)
            }
            vc.navigationController?.pushViewController(positionVC, animated: true)
        }
        vc.menuCameraRegionTapped = { [weak self, weak vc] in
            guard let self = self, let vc = vc, let currentRegion = self.getCurrentRegion() else {
                return
            }
            let regionVC = TelenavMapCameraRegionViewController.storyboardViewController()
            regionVC.cameraRegion = currentRegion
            regionVC.cameraRegionDidChange = { [weak self, weak vc] region in
                guard let self = self else {
                    return
                }
                self.regionDidChange(region: region)
                vc?.navigationController?.popToViewController(self, animated: true)
            }
            vc.navigationController?.pushViewController(regionVC, animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func positionDidChange(position: VNCameraPosition) {
        self.map.cameraController().position = position
    }
    
    func regionDidChange(region: VNCameraRegion) {
        self.map.cameraController().show(region)
    }
    
    func getCurrentRegion() -> VNCameraRegion? {
        guard
            let location0 = self.map.cameraController().viewport(toWorld: VNViewPoint(x: 0, y: 0)),
            let location1 = self.map.cameraController().viewport(toWorld: VNViewPoint(x: Float(map.bounds.size.width), y: Float(map.bounds.size.height))) else {
            return nil
        }
        
        let region = VNCameraRegion(
            northLatitude: location0.latitude,
            westLongitude: location0.longitude,
            southLatitude: location1.latitude,
            eastLongitude: location1.longitude
        )
        
        return region
    }
}

extension TelenavMapViewController: TelenavMapSettingsViewControllerDelegate {
    func mapSettingsDidChange(vc: TelenavMapSettingsViewController, settings: TelenavMapSettingsModel) {
        mapViewSettingsModel = settings
        
        setupMapFeatures(settings: settings)
        navigationController?.popViewController(animated: true)
    }
}
