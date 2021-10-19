//
//  TelenavMapViewController.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividMapSDK
import CoreLocation

class TelenavMapViewController: UIViewController {
    var mapViewSettingsModel = TelenavMapSettingsModel()
    var map: VNMapView!
    private var locationManager: CLLocationManager!
    private var cameraRenderMode = VNCameraRenderMode.M2D
    private var isListenData = false
    private var isVehicleTrackActive = false
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
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
    
    lazy var diagnosisButton: UIButton = {
        let diagnosisButton = UIButton(type: .system)
        diagnosisButton.translatesAutoresizingMaskIntoConstraints = false
        diagnosisButton.backgroundColor = .systemBackground
        diagnosisButton.setImage(UIImage(systemName: "waveform.path.ecg"), for: .normal)
        return diagnosisButton
    }()

    lazy var vehicleTrackButton: UIButton = {
        let diagnosisButton = UIButton(type: .system)
        diagnosisButton.translatesAutoresizingMaskIntoConstraints = false
        diagnosisButton.backgroundColor = .systemBackground
        diagnosisButton.setImage(UIImage(systemName: "car"), for: .normal)
        return diagnosisButton
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

        setupCoreLocation()
        setupUI()
        setupMapFeatures(settings: mapViewSettingsModel)
        setupLongPressGestureRecognizer()
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
        
        view.addSubview(diagnosisButton)
        
        NSLayoutConstraint.activate([
            diagnosisButton.widthAnchor.constraint(equalToConstant: 40),
            diagnosisButton.heightAnchor.constraint(equalToConstant: 40),
            diagnosisButton.bottomAnchor.constraint(equalTo: cameraSettingsButton.topAnchor, constant: -16.0),
            diagnosisButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        diagnosisButton.addTarget(self, action: #selector(diagnosisButtonTapped), for: .touchUpInside)

        view.addSubview(vehicleTrackButton)

        NSLayoutConstraint.activate([
            vehicleTrackButton.widthAnchor.constraint(equalToConstant: 40),
            vehicleTrackButton.heightAnchor.constraint(equalToConstant: 40),
            vehicleTrackButton.bottomAnchor.constraint(equalTo: diagnosisButton.topAnchor, constant: -16.0),
            vehicleTrackButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])

        vehicleTrackButton.addTarget(self, action: #selector(vehicleTrackButtonTapped), for: .touchUpInside)
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
        
        isListenData = settings.isListenMapViewDataOn
        map.listenData(settings.isListenMapViewDataOn)
    }
    
    func cameraRenderModeButtonUpdate(mode: VNCameraRenderMode) {
        cameraRenderModeButton.backgroundColor = mode == .M2D ? .systemBackground : .systemGreen
        cameraRenderModeButton.setTitleColor(mode == .M2D ? .black : .white, for: .normal)
    }

    func vehicleTrackButtonRenderUpdate() {
        vehicleTrackButton.backgroundColor = isVehicleTrackActive ? .systemBlue : .systemBackground
        vehicleTrackButton.tintColor = isVehicleTrackActive ? .systemBackground : .systemBlue
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

    @objc func vehicleTrackButtonTapped() {
        isVehicleTrackActive.toggle()

        if isVehicleTrackActive {
            let image = UIImage(systemName: "car")!
            image.withRenderingMode(.alwaysTemplate)
            image.withTintColor(.red)
            map.vehicleController().setIcon(image)
        }

        if isVehicleTrackActive == false {
            stopUpdateLocation()
            map.vehicleController().setIcon(nil)
        }

        vehicleTrackButtonRenderUpdate()
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
    
    @objc func diagnosisButtonTapped() {
        let mapDiagnosis = map.mapDiagnosis()
        let mapViewState = mapDiagnosis.getMapViewStatus()
        
        let vc = TelenavMapDiagnosisViewController.storyboardViewController()
        vc.mapViewState = isListenData ? mapViewState : nil
        vc.title = "Map diagnosis"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func positionDidChange(position: VNCameraPosition) {
        self.map.cameraController().position = position
    }
    
    func regionDidChange(region: VNCameraRegion) {
        self.map.cameraController().show(region)
    }
    
    func getCurrentRegion() -> VNCameraRegion? {
        let scale = UIScreen.main.scale
        
        guard
            let location0 = self.map.cameraController().viewport(toWorld: VNViewPoint(x: 0, y: 0)),
            let location1 = self.map.cameraController().viewport(toWorld: VNViewPoint(x: Float(map.bounds.size.width * scale), y: Float(map.bounds.size.height * scale))) else {
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

// Recognizers
extension TelenavMapViewController {
    private func setupLongPressGestureRecognizer() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizerAction))
        map.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func longPressGestureRecognizerAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        let longPressLocation = gestureRecognizer.location(in: gestureRecognizer.view)
        
        let scale = UIScreen.main.scale
        let viewPoint = VNViewPoint(
            x: Float(longPressLocation.x * scale), // in pixels
            y: Float(longPressLocation.y * scale)  // in pixels
        )
        
        guard let mapLocation = map.cameraController().viewport(toWorld: viewPoint) else {
            return
        }
        
        let geoLocation = CLLocationCoordinate2D(latitude: mapLocation.latitude, longitude: mapLocation.longitude)
        
        let annotationMenuAlert = UIAlertController(title: "Add annotation", message: "Please select annotations type", preferredStyle: .actionSheet)
        
        annotationMenuAlert.addAction(UIAlertAction(title: "Image", style: .default, handler: { [weak self] _ in
            self?.addImageAnnotationTo(location: geoLocation)
        }))
        annotationMenuAlert.addAction(UIAlertAction(title: "Image and text", style: .default, handler: { [weak self] _ in
            self?.addTextAnnotationTo(location: geoLocation)
        }))
        annotationMenuAlert.addAction(UIAlertAction(title: "Explicit style", style: .default, handler: { [weak self] _ in
            self?.addExplicitStyleAnnotationTo(location: geoLocation)
        }))
        annotationMenuAlert.addAction(UIAlertAction(title: "Remove all annotations", style: .destructive, handler: { [weak self] _ in
            self?.removeAllAnnotation()
        }))
        
        self.present(annotationMenuAlert, animated: true, completion: nil)
    }
    
    private func addImageAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = map.annotationsController().factory()
        
        if let image = UIImage(systemName: "face.smiling") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            map.annotationsController().add([annotation])
        }
    }
    
    private func addTextAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = map.annotationsController().factory()
        
        if let image = UIImage(systemName: "face.smiling") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            
            let textDisplay = VNTextDisplayInfo(centeredText: "face.smiling")
            textDisplay.textColor = .red
            textDisplay.textFontSize = 20
            
            annotation.displayText = textDisplay
            map.annotationsController().add([annotation])
        }
    }
    
    private func addExplicitStyleAnnotationTo(location: CLLocationCoordinate2D) {
        // TODO: Now explicit style annotations don't work.
    }
    
    private func removeAllAnnotation() {
        map.annotationsController().clearAllAnnotations()
    }
}

//MARK: CoreLocation

private extension TelenavMapViewController {

     func setupCoreLocation() {
         locationManager = CLLocationManager()
         locationManager.delegate = self
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
         locationManager.requestAlwaysAuthorization()
         locationManager.startUpdatingLocation()
    }

    func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
    }
}

//MARK: CoreLocation delegate

extension TelenavMapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let lastPoint = locations.last else {
            return
        }

        if isVehicleTrackActive {
            map.vehicleController().setLocation(lastPoint)
        }

    }
}
