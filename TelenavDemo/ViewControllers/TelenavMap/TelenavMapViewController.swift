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
    private var cameraRenderMode = VNCameraRenderMode.M2D
    private var isListenData = false
    //Shapes
    private var isShapesPressed = false
    private var selectedShapeType: VNShapeType?
    private var shapesPoints = [CLLocationCoordinate2D]()
    private var shapeCollectionIds = [VNShapeCollectionID]()
    //Gestures
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
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

    lazy var shapesButton: UIButton = {
        let shapesButton = UIButton(type: .system)
        shapesButton.translatesAutoresizingMaskIntoConstraints = false
        shapesButton.backgroundColor = .systemBackground
        let buttonImage = UIImage(systemName: "square.and.pencil")
        shapesButton.setImage(buttonImage, for: .normal)
        return shapesButton
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
        setupMapCustomGestureRecognizers()
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

        view.addSubview(shapesButton)

        NSLayoutConstraint.activate([
            shapesButton.widthAnchor.constraint(equalToConstant: 40),
            shapesButton.heightAnchor.constraint(equalToConstant: 40),
            shapesButton.bottomAnchor.constraint(equalTo: diagnosisButton.topAnchor, constant: -16.0),
            shapesButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])

        shapesButton.addTarget(self, action: #selector(shapesButtonTapped), for: .touchUpInside)

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

    func shapesRenderModeButtonUpdate() {
        shapesButton.backgroundColor = isShapesPressed ? .systemBlue : .systemBackground
        shapesButton.tintColor = isShapesPressed ? .systemBackground : .systemBlue
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
    
    @objc func diagnosisButtonTapped() {
        let mapDiagnosis = map.mapDiagnosis()
        let mapViewState = mapDiagnosis.getMapViewStatus()
        
        let vc = TelenavMapDiagnosisViewController.storyboardViewController()
        vc.mapViewState = isListenData ? mapViewState : nil
        vc.title = "Map diagnosis"
        
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func shapesButtonTapped() {
        isShapesPressed.toggle()

        shapesRenderModeButtonUpdate()

        if isShapesPressed == false {
            map.removeGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer = nil
            shapesPoints.removeAll()

            shapeCollectionIds.forEach { self.map.shapesController().removeCollection($0)}
            shapeCollectionIds.removeAll()

            return
        }

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))
        map.addGestureRecognizer(tapGestureRecognizer)

        let annotationMenuAlert = UIAlertController(title: "Add shapes", message: "Please select shape type", preferredStyle: .actionSheet)

        annotationMenuAlert.addAction(UIAlertAction(title: "Polylines", style: .default, handler: { [weak self] _ in
            self?.selectedShapeType = .polyline

        }))

        annotationMenuAlert.addAction(UIAlertAction(title: "Polygon", style: .default, handler: { [weak self] _ in
            self?.selectedShapeType = .polygon

        }))

        self.present(annotationMenuAlert, animated: true, completion: nil)
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

// Recognizer's
extension TelenavMapViewController {

    private func setupMapCustomGestureRecognizers() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizerAction))
        map.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func longPressGestureRecognizerAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        guard let geoLocation = getCoordinatesFrom(gestureRecognizer: gestureRecognizer) else {
            return
        }
        
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

    @objc private func tapGestureRecognizerAction(_ gestureRecognizer: UITapGestureRecognizer) {

        if isShapesPressed == false { return }

        guard
            let geoLocation = getCoordinatesFrom(gestureRecognizer: gestureRecognizer),
            let selectedShapeType = selectedShapeType
        else {
            return
        }

        self.shapesPoints.append(geoLocation)

        switch selectedShapeType {
        case .polyline:
            self.addPolylineShapeTo(coordinates: shapesPoints)
        case .polygon:
            self.addPolygonShapeTo(coordinates: shapesPoints)
        default: break
        }
    }

    private func addPolylineShapeTo(coordinates: [CLLocationCoordinate2D]) {

        if coordinates.count < 2 { return }

        let coordinates = coordinates.compactMap {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        let shapeAttributes = VNShapeAttributes
            .builder()
            .lineWidth(2.0)
            .color(.red)
            .shapeStyle("route.ADI_LINE")
            .build()

        let shape = VNShape(
            type: .polyline,
            attributes: shapeAttributes,
            coordinates: coordinates
        )

        let shapeCollection = VNShapeCollection
            .builder()
            .add(shape)
            .build()

        if let shapeCollectionId = map.shapesController().add(shapeCollection) {
            shapeCollectionIds.append(shapeCollectionId)
        }
    }

    private func addPolygonShapeTo(coordinates: [CLLocationCoordinate2D]) {

        if coordinates.count < 4 { return }

        let coordinates = coordinates.compactMap {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        let shapeAttributes = VNShapeAttributes
            .builder()
            .shapeStyle("route.ADI_LINE")
            .build()

        let shape = VNShape(
            type: .texturedQuad,
            attributes: shapeAttributes,
            coordinates: coordinates
        )


        let shapeCollection = VNShapeCollection
            .builder()
            .add(shape)
            .build()

        if let shapeCollectionId = map.shapesController().add(shapeCollection) {
            shapeCollectionIds.append(shapeCollectionId)
        }
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

    private func getCoordinatesFrom(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        let tapPressLocation = gestureRecognizer.location(in: gestureRecognizer.view)

        let scale = UIScreen.main.scale
        let viewPoint = VNViewPoint(
            x: Float(tapPressLocation.x * scale), // in pixels
            y: Float(tapPressLocation.y * scale)  // in pixels
        )

        guard let mapLocation = map.cameraController().viewport(toWorld: viewPoint) else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: mapLocation.latitude,
            longitude: mapLocation.longitude
        )
    }
    
    private func addExplicitStyleAnnotationTo(location: CLLocationCoordinate2D) {
        // TODO: Now explicit style annotations don't work.
    }
    
    private func removeAllAnnotation() {
        map.annotationsController().clearAllAnnotations()
    }
}
