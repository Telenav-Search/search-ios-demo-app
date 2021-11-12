//
//  TelenavMapViewController.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividDriveSessionSDK
import CoreLocation

class TelenavMapViewController: UIViewController {
    var mapViewSettingsModel = TelenavMapSettingsModel()
    var mapView: VNMapView!
    private var locationManager: CLLocationManager!
    private var cameraRenderMode = VNCameraRenderMode.M2D
    private var isListenData = false
    //Navigation Session

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var travelEstimationLbl: UILabel!

    private var latitude: Double = 0
    private var longitude: Double = 0
    private var heading: Double = 0
    private var speed: Double = 0

    private var driveSession: VNDriveSessionClient!
    private var navigationSession: VNNavigationSession!
    private var isNavigationSessionActive = false
    private var firstRoutePoint: VNGeoLocation?
    private var secondRoutePoint: VNGeoLocation?
    private var routeModels = [VNMapRouteModel]()
    private var selectedRouteModel: VNMapRouteModel?
    private var routes = [VNRoute]()
    private var selectedRoute: VNRoute?

    //Vehicle
    private var isVehicleTrackActive = false
    //Shapes
    private var isShapesPressed = false
    private var shapesPoints = [CLLocationCoordinate2D]()
    private var shapeCollectionIds = [VNShapeCollectionID]()
    private let carPoint = CLLocation(latitude: 40.595495107440506, longitude: -73.6566129026753)
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

    lazy var vehicleTrackButton: UIButton = {
        let vehicleTrackButton = UIButton(type: .system)
        vehicleTrackButton.translatesAutoresizingMaskIntoConstraints = false
        vehicleTrackButton.backgroundColor = .systemBackground
        vehicleTrackButton.setImage(UIImage(systemName: "car"), for: .normal)
        return vehicleTrackButton
    }()

    lazy var navigationSessionButton: UIButton = {
        let navigationSessionButton = UIButton(type: .system)
        navigationSessionButton.translatesAutoresizingMaskIntoConstraints = false
        navigationSessionButton.backgroundColor = .systemBackground
        navigationSessionButton.setImage(UIImage(systemName: "pencil.and.outline"), for: .normal)
        return navigationSessionButton
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

        driveSession = VNDriveSessionClient.factory().build()
        driveSession.positionEventDelegate = self

        setupUI()
        setupMapFeatures(settings: mapViewSettingsModel)
        setupMapCustomGestureRecognizers()
    }
    
    func setupUI() {
        mapView = VNMapView()
        mapView.preferredFPS = 30
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
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


        view.addSubview(vehicleTrackButton)

        NSLayoutConstraint.activate([
            vehicleTrackButton.widthAnchor.constraint(equalToConstant: 40),
            vehicleTrackButton.heightAnchor.constraint(equalToConstant: 40),
            vehicleTrackButton.bottomAnchor.constraint(equalTo: shapesButton.topAnchor, constant: -16.0),
            vehicleTrackButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])

        vehicleTrackButton.addTarget(self, action: #selector(vehicleTrackButtonTapped), for: .touchUpInside)

        view.addSubview(navigationSessionButton)

        NSLayoutConstraint.activate([
            navigationSessionButton.widthAnchor.constraint(equalToConstant: 40),
            navigationSessionButton.heightAnchor.constraint(equalToConstant: 40),
            navigationSessionButton.bottomAnchor.constraint(equalTo: vehicleTrackButton.topAnchor, constant: -16.0),
            navigationSessionButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])

        navigationSessionButton.addTarget(
            self,
            action: #selector(navigationSessionButtonTapped),
            for: .touchUpInside
        )

        mapView.addSubview(collectionView)
        mapView.addSubview(imageView)
        mapView.addSubview(travelEstimationLbl)

    }
    
    func setupMapFeatures(settings: TelenavMapSettingsModel) {
        let features = mapView.featuresController()
        
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
        
        mapView.setActiveGestures(settings.gestureType)
        
        let layoutController = mapView.layoutController()
        layoutController.setOffsets(settings.horizontalOffset, vertical: settings.verticalOffset)
        
        isListenData = settings.isListenMapViewDataOn
        mapView.listenData(settings.isListenMapViewDataOn)
    }
    
    func cameraRenderModeButtonUpdate(mode: VNCameraRenderMode) {
        cameraRenderModeButton.backgroundColor = mode == .M2D ? .systemBackground : .systemGreen
        cameraRenderModeButton.setTitleColor(mode == .M2D ? .black : .white, for: .normal)
    }

    func renderUpdateFor(button: UIButton, with state: Bool) {
        button.backgroundColor = state ? .systemBlue : .systemBackground
        button.tintColor = state ? .systemBackground : .systemBlue
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
        
        mapView.cameraController().renderMode = cameraRenderMode
    }

    @objc func vehicleTrackButtonTapped() {
        isVehicleTrackActive.toggle()

        if isVehicleTrackActive {
            let image = UIImage(systemName: "car")!

            mapView.vehicleController().setIcon(image)
            mapView.vehicleController().setLocation(carPoint)

            let region = VNCameraRegion(
                northLatitude: 40.596872279198394,
                westLongitude: -73.65836739330247,
                southLatitude: 40.594640327481486,
                eastLongitude: -73.65516483569407
            )

            mapView.cameraController().show(region)
        }

        if isVehicleTrackActive == false {
            mapView.vehicleController().setIcon(nil)
            mapView.vehicleController().setLocation(nil)
        }

        renderUpdateFor(button: vehicleTrackButton, with: isVehicleTrackActive)
    }
    
    @objc func cameraSettingsButtonTapped() {
        let vc = TelenavMapCameraMenuViewController.storyboardViewController()
        vc.menuCameraPositionTapped = { [weak self, weak vc] in
            guard let self = self, let vc = vc else {
                return
            }
            let positionVC = TelenavMapCameraPositionViewController.storyboardViewController()
            positionVC.cameraPosition = self.mapView.cameraController().position
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
        let mapDiagnosis = mapView.mapDiagnosis()
        
        let vc = TelenavMapDiagnosisViewController.storyboardViewController()
        vc.mapViewState = mapDiagnosis.getMapViewStatus()
        vc.title = "Map diagnosis"
        
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func shapesButtonTapped() {
        isShapesPressed.toggle()

        renderUpdateFor(button: shapesButton, with: isShapesPressed)

        if isShapesPressed == false {
            mapView.removeGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer = nil
            shapesPoints.removeAll()

            shapeCollectionIds.forEach { self.mapView.shapesController().removeCollection($0)}
            shapeCollectionIds.removeAll()
            let routeIds = self.routeModels.map { $0.getRouteId() }
            mapView.routeController().removeRoutes(routeIds)

            return
        }

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))
        mapView.addGestureRecognizer(tapGestureRecognizer)

    }

    @objc func navigationSessionButtonTapped() {
        isNavigationSessionActive.toggle()

        renderUpdateFor(
            button: navigationSessionButton,
            with: isNavigationSessionActive
        )

        travelEstimationLbl.isHidden = !isNavigationSessionActive
        collectionView.isHidden = !isNavigationSessionActive
        imageView.isHidden = !isNavigationSessionActive

        if isNavigationSessionActive == false {
            setupMapCustomGestureRecognizers()
            mapView.featuresController().traffic.setDisabled()
            mapView.featuresController().compass.setDisabled()
            mapView.cameraController().renderMode = .M2D
            mapView.cameraController().disableFollowVehicle()
            if navigationSession != nil {
                navigationSession.stopNavigation()
                navigationSession = nil
            }
            selectedRoute = nil
            firstRoutePoint = nil
            secondRoutePoint = nil
            routes.removeAll()
            let routeIds = self.routeModels.map { $0.getRouteId() }
            mapView.routeController().removeRoutes(routeIds)
            collectionView.reloadData()
            return
        }

        setupNavLongPressGestures()
    }

    func positionDidChange(position: VNCameraPosition) {
        self.mapView.cameraController().position = position
    }
    
    func regionDidChange(region: VNCameraRegion) {
        self.mapView.cameraController().show(region)
    }
    
    func getCurrentRegion() -> VNCameraRegion? {
        let scale = UIScreen.main.scale
        
        guard
            let location0 = self.mapView.cameraController().viewport(toWorld: VNViewPoint(x: 0, y: 0)),
            let location1 = self.mapView.cameraController().viewport(toWorld: VNViewPoint(x: Float(mapView.bounds.size.width * scale), y: Float(mapView.bounds.size.height * scale))) else {
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
        if longPressGestureRecognizer != nil {
            mapView.removeGestureRecognizer(longPressGestureRecognizer)
        }
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizerAction))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }

    private func setupNavLongPressGestures() {
        mapView.removeGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(navGestureAction))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
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
            let geoLocation = getCoordinatesFrom(gestureRecognizer: gestureRecognizer)
        else {
            return
        }

        shapesPoints.append(geoLocation)

        addPolylineShapeTo(coordinates: shapesPoints)
    }

    @objc private func navGestureAction(_ gestureRecognizer: UITapGestureRecognizer) {

        guard
            let geoLocation = getCoordinatesFrom(gestureRecognizer: gestureRecognizer)
        else {
            return
        }

        let title = "Do you want to create a route for navigation session?"
        let alertController = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .actionSheet
        )

        let fromAction = UIAlertAction(title: "From here", style: .default, handler: { [weak self] (action) in
            self?.firstRoutePoint = VNGeoLocation(latitude: geoLocation.latitude, longitude: geoLocation.longitude)
            self?.createRoute()
        })

        alertController.addAction(fromAction)

        let toAction = UIAlertAction(title: "Till here", style: .default, handler: { [weak self] (action) in
            self?.secondRoutePoint = VNGeoLocation(latitude: geoLocation.latitude, longitude: geoLocation.longitude)
            self?.createRoute()
        })

        alertController.addAction(toAction)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alertController, animated: true)
    }

    private func calculateRoute(startPoint: VNGeoLocation, endPoint: VNGeoLocation, completion: @escaping ([VNRoute]) -> ()) {

        let request = VNRouteRequest.builder()
            .setOrigin(startPoint)
            .setDestination(endPoint)
            .setRouteCount(3)
            .build()

        let client = VNDirectionClient.factory().build()
        let task = client?.createRouteCalculationTask(request)

        task?.runAsync({ response, error  in

            guard error == nil, let routes = response?.routes, routes.count > 0 else {
                return
            }

            completion(routes)

        })

    }
    private func createRoute() {
        if
            let startPoint = firstRoutePoint,
            let endPoint = secondRoutePoint {

            mapView.vehicleController().setIcon(UIImage(systemName: "car"))
            mapView.featuresController().traffic.setEnabled()
            mapView.featuresController().compass.setEnabled()
            mapView.cameraController().renderMode = .M3D
            mapView.cameraController().enable(.headingUp, useAutoZoom: true)

            navigationSession = driveSession.createNavigationSession()
            navigationSession.delegate = self
            calculateRoute(
                startPoint: startPoint,
                endPoint: endPoint) {  [weak self] routes in
                    DispatchQueue.main.async {
                        self?.routes = routes
                        self?.showRoute(routes: routes)
                        self?.collectionView.reloadData()
                    }
                }
        }
        else {
            return
        }

    }

    private func addPolylineShapeTo(coordinates: [CLLocationCoordinate2D]) {

        if coordinates.count < 2 { return }

        let coordinates = coordinates.compactMap {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        let shapeAttributes = VNShapeAttributes
            .builder()
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

        if let shapeCollectionId = mapView.shapesController().add(shapeCollection) {
            shapeCollectionIds.append(shapeCollectionId)
        }
    }
    
    private func addImageAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = mapView.annotationsController().factory()
        
        if let image = UIImage(systemName: "face.smiling") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            mapView.annotationsController().add([annotation])
        }
    }
    
    private func addTextAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = mapView.annotationsController().factory()
        
        if let image = UIImage(systemName: "face.smiling") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            
            let textDisplay = VNTextDisplayInfo(centeredText: "face.smiling")
            textDisplay.textColor = .red
            textDisplay.textFontSize = 20
            
            annotation.displayText = textDisplay
            mapView.annotationsController().add([annotation])
        }
    }

    private func getCoordinatesFrom(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        let tapPressLocation = gestureRecognizer.location(in: gestureRecognizer.view)

        let scale = UIScreen.main.scale
        let viewPoint = VNViewPoint(
            x: Float(tapPressLocation.x * scale), // in pixels
            y: Float(tapPressLocation.y * scale)  // in pixels
        )

        guard
            let mapLocation = mapView.cameraController().viewport(toWorld: viewPoint)
        else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: mapLocation.latitude,
            longitude: mapLocation.longitude
        )
    }

    private func showTurnArrows(routeName: String, route: VNRoute) {
        mapView.routeController().disableAllTurnArrows()
        for (legIndex, leg) in route.legs.enumerated() {
            for (stepIndex, _) in leg.steps.enumerated() {
                mapView.routeController().enableTurnArrow(
                    forRouteName: routeName,
                    legIndex: Int32(legIndex),
                    step: Int32(stepIndex)
                )
            }
        }
    }

    private func showRoute(routes: [VNRoute]) {
        let routeModels = routes.enumerated().map { (index, element) in
            return VNMapRouteConverter.convert(element, routeId: "\(index)")
        }

        let routeController = mapView.routeController()

        if !self.routeModels.isEmpty {
            let routeIds = self.routeModels.map { $0.getRouteId() }
            routeController.removeRoutes(routeIds)
        }

        if !routeModels.isEmpty {
            routeController.addRoutes(routeModels)
            routeController.unhighlight()
            self.routeModels = routeModels
        }
    }

    private func addExplicitStyleAnnotationTo(location: CLLocationCoordinate2D) {
        // TODO: Now explicit style annotations don't work.
    }
    
    private func removeAllAnnotation() {
        mapView.annotationsController().clearAllAnnotations()
    }
}


//MARK: - Route collection view

extension TelenavMapViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let routeCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouteCell", for: indexPath as IndexPath) as? RouteCell {
            routeCell.titleLabel.text = "Route: \(indexPath.row)"
            routeCell.isSelected = false
            return routeCell

        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if selectedRoute != nil {
            return
        }

        DispatchQueue.main.async {
            let route = self.routes[indexPath.row]
            let routeModel = self.routeModels[indexPath.row]

            let routeDuration = route.duration.secondsToHoursMinutesSeconds() ?? ""

            let durationText = "Route duration: \(routeDuration)"
            self.travelEstimationLbl.text = durationText
            self.selectedRoute = route
            self.selectedRouteModel = routeModel
            self.showTurnArrows(routeName: routeModel.getRouteId(), route: route)
            self.mapView.routeController().highlight(routeModel.getRouteId())
            self.navigationSession?.updateRouteInfo(route)
            self.navigationSession.startSimulateNavigation()
        }
    }
}

extension TelenavMapViewController: VNNavigationSessionDelegate {

    func onRouteInfoUpdated(_ onRoadInfo: VNOnRouteInfo) {

        if (onRoadInfo.isVehicleOnTrack) {
            let routeId = selectedRouteModel?.getRouteId() ?? ""
            mapView.routeController().vehicle(
                onRouteInfoRouteName: routeId,
                routeId: routeId,
                legIndex: UInt32(onRoadInfo.legIndex),
                step: UInt32(onRoadInfo.stepIndex),
                edgeIndex: UInt32(onRoadInfo.edgeIndex),
                pointIndex: UInt32(onRoadInfo.pointIndex),
                position: .init(latitude: latitude, longitude: longitude, heightMeters: 0),
                heading: heading,
                passedDistance: onRoadInfo.distFromStart,
                vehicleSpeed: speed,
                headingTolerance: 10,
                isEatingRoute: true)
        }
    }

    func processNavigationSignals(signals: [VNNavigationSignal]) {
        for signal in signals {
            if let signalReachWaypoint = signal as? VNNavigationSignalReachWaypoint {
                print("signalReachWaypoint = \(signalReachWaypoint)")
            } else
            if let signalUpdateJunctionView = signal as? VNNavigationSignalUpdateJunctionView {
                print("signalUpdateJunctionView = \(signalUpdateJunctionView)")
                processUpdateJunctionView(signalUpdateJunctionView: signalUpdateJunctionView)
            } else
            if let signalUpdateTurnByTurnList = signal as? VNNavigationSignalUpdateTurnByTurnList {
                print("signalUpdateTurnByTurnList = \(signalUpdateTurnByTurnList)")

            } else
            if let signalTimedRestriction = signal as? VNNavigationSignalTimedRestriction {
                print("signalTimedRestriction = \(signalTimedRestriction)")
            } else
            if let signalAlongRouteTrafficInfo = signal as? VNNavigationSignalAlongRouteTrafficInfo {
                print("signalAlongRouteTrafficInfo = \(signalAlongRouteTrafficInfo)")
            }
        }
    }

    func processUpdateJunctionView(signalUpdateJunctionView: VNNavigationSignalUpdateJunctionView) {
        if signalUpdateJunctionView.junctionViewStatus == .entered ||
            signalUpdateJunctionView.junctionViewStatus == .inTransition {
            let junctionViewRender = driveSession.getJunctionViewRender()

            guard let route = selectedRoute else { return }
            let bitmap = junctionViewRender.getJunctionViewImage(
                forRoure: route,
                legIndex: signalUpdateJunctionView.legIndex,
                step: signalUpdateJunctionView.stepIndex,
                width: 120,
                height: 60,
                dayNightMode: .dayMode
            )

            if let image = bitmap?.image {
                DispatchQueue.main.async { [weak self] in
                    self?.imageView.image = image
                    self?.imageView.isHidden = false
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.imageView.isHidden = true
            }
        }
    }
}

extension TelenavMapViewController: VNPositionEventDelegate {

    func onLocationUpdated(_ vehicleLocation: VNVehicleLocationInfo) {
        let location = CLLocation.init(
            coordinate: .init(latitude: vehicleLocation.lat, longitude: vehicleLocation.lon),
            altitude: 0, // not used
            horizontalAccuracy: CLLocationAccuracy(vehicleLocation.locationAccuracy),
            verticalAccuracy: CLLocationAccuracy(vehicleLocation.locationAccuracy),
            course: CLLocationDirection(vehicleLocation.heading),
            speed: CLLocationSpeed(vehicleLocation.speed),
            timestamp: Date() // not used
        )
        mapView.vehicleController().setLocation(location)

        latitude = vehicleLocation.lat
        longitude = vehicleLocation.lon
        heading = Double(vehicleLocation.heading)
        speed = Double(vehicleLocation.speed)

    }
    func onUpdate(_ navStatus: VNNavStatus!) {
        if navStatus.navigationSignal.count != 0 {
            processNavigationSignals(signals: navStatus.navigationSignal)
        }
    }
}
