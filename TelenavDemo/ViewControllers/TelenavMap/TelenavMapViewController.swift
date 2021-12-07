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

    private let locationProvider = LocationProvider.shared
    private var currentLocation = LocationProvider.shared.location
    private var cameraRenderMode = VNCameraRenderMode.M2D
    private var isListenData = false
    //Navigation Session
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var travelEstimationLbl: UILabel!
    @IBOutlet weak var startNavigationButton: UIButton!
    @IBOutlet weak var followVehicleButton: UIButton!
    @IBOutlet weak var cameraModeButton: UIButton!
    
    private var accuracy: Float = 0
    
    private var driveSession: VNDriveSessionClient!
    private var navigationSession: VNNavigationSession!
    private var isNavigationSessionActive = false
    private var firstRoutePoint: VNGeoLocation?
    private var secondRoutePoint: VNGeoLocation?
    private var routeModels = [VNMapRouteModel]()
    private var selectedRouteModel: VNMapRouteModel?
    private var routes = [VNRoute]()
    private var selectedRoute: VNRoute?
    private var demoAnnotations = [AnnotationState]()
  
    private var fromAnnotation: VNAnnotation?
    private var toAnnotation: VNAnnotation?
    
    //Day night mode
    private var isNightModeActive = false
    
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
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var pinchGestureRecognizer: UIPinchGestureRecognizer!
    private var rotationGestureRecognizer: UIRotationGestureRecognizer!
  
    // Drive Session
    private var driveSessionLabelStack: UIStackView!
    private var addressLabel: UILabel!
    private var speedLimit: UILabel!
    private var cityName: UILabel!
    private var audioMessage: UILabel!
    private var alertMessage: UILabel!
    private var violationMessage: UILabel!
    private var violationWarningTitle: UILabel!

    private var currentCameraMode = VNCameraFollowVehicleMode.headingUp
  
    // Search
    private var isPoiSearchActive = false
    private var searchEngine: SearchEngine!
    
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
    
    lazy var switchColorScheme: UIButton = {
        let switchColorScheme = UIButton(type: .system)
        switchColorScheme.translatesAutoresizingMaskIntoConstraints = false
        switchColorScheme.backgroundColor = .systemBackground
        switchColorScheme.setImage(UIImage(systemName: "moon"), for: .normal)
        return switchColorScheme
    }()
  
    lazy var poiSearchButton: UIButton = {
        let poiSearchButton = UIButton(type: .system)
        poiSearchButton.translatesAutoresizingMaskIntoConstraints = false
        poiSearchButton.backgroundColor = .systemBackground
        poiSearchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        return poiSearchButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(showSettingsAction)
        )
        
        driveSession = VNDriveSessionClient.factory().build()
        driveSession.audioEventDelegate = self
        driveSession.alertEventDelegate = self
        
        setupUI()
        setupUIDriveSession()
        setupMapFeatures(settings: mapViewSettingsModel)
        setupMapCustomGestureRecognizers()
        setupLocationManager()
      
        searchEngine = SearchEngine.init()
        mapView.searchController().inject(searchEngine)
      
        locationProvider.addListner(listner: self)
    }
  
    deinit {
      locationProvider.removeListner(listner: self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle == .dark {
            VNSDK.sharedInstance.dayNightMode = .dayMode
        } else {
            VNSDK.sharedInstance.dayNightMode = .nightMode
        }
    }
  
    func startNavigation() {
      navigationSession = driveSession.createNavigationSession()
      navigationSession.delegate = self
      navigationSession?.updateRouteInfo(self.selectedRoute!)
      
      // Remove unselected routes
      let routeIds = self.routeModels.map { $0.getRouteId() }
      var removeRouteIds = Array<String>()
      for routeId in routeIds {
        if (routeId == selectedRouteModel?.getRouteId()) { continue }
        removeRouteIds.append(routeId)
      }
      mapView.routeController().removeRoutes(removeRouteIds)
      
      cameraRenderModeButton.isHidden = true
      cameraSettingsButton.isHidden = true
      diagnosisButton.isHidden = true
      shapesButton.isHidden = true
      vehicleTrackButton.isHidden = true
      switchColorScheme.isHidden = true
      poiSearchButton.isHidden = true
      
      travelEstimationLbl.isHidden = false
      // imageView hidden = false, when we show junction
      collectionView.isHidden = true
      cameraModeButton.isHidden = false
      
      mapView.vehicleController().setIcon(UIImage(named: "car-icon")!)
      mapView.featuresController().traffic.setEnabled()
      mapView.featuresController().compass.setEnabled()
      mapView.cameraController().renderMode = .M3D
      mapView.cameraController().enable(currentCameraMode, useAutoZoom: true)
      
      driveSession.positionEventDelegate = self
      self.navigationSession.startSimulateNavigation()
      self.driveSessionLabelStack.isHidden = false
      driveSession.enableAudioDefaultPlayback(true)
      
      setupInNavigationGestures()
    }
  
    func stopNavigation() {
      cameraRenderModeButton.isHidden = false
      cameraSettingsButton.isHidden = false
      diagnosisButton.isHidden = false
      shapesButton.isHidden = false
      vehicleTrackButton.isHidden = false
      switchColorScheme.isHidden = false
      poiSearchButton.isHidden = false
      
      travelEstimationLbl.isHidden = true
      imageView.isHidden = true
      
      mapView.vehicleController().setIcon(nil)
      mapView.featuresController().traffic.setDisabled()
      mapView.featuresController().compass.setDisabled()
      mapView.cameraController().renderMode = .M2D
      mapView.cameraController().disableFollowVehicle()
      
      driveSession.positionEventDelegate = nil
      self.navigationSession.stopNavigation()
      self.driveSessionLabelStack.isHidden = true
      driveSession.enableAudioDefaultPlayback(false)
      
      restoreGestures()
    }
    
    func setupUIDriveSession() {
        driveSessionLabelStack = UIStackView()
        driveSessionLabelStack.alignment = .leading
        driveSessionLabelStack.axis = .vertical

        driveSessionLabelStack.translatesAutoresizingMaskIntoConstraints = false
      
        let backgroundColor = UIColor.white.withAlphaComponent(0.6)

        let addressStack = UIStackView()
        addressStack.alignment = .leading
        addressStack.axis = .horizontal
        addressStack.spacing = 8
        addressStack.backgroundColor = backgroundColor

        let speedLimitStack = UIStackView()
        speedLimitStack.alignment = .leading
        speedLimitStack.axis = .horizontal
        speedLimitStack.spacing = 8
        speedLimitStack.backgroundColor = backgroundColor

        speedLimitStack.translatesAutoresizingMaskIntoConstraints = false

        let countryStack = UIStackView()
        countryStack.alignment = .leading
        countryStack.axis = .horizontal
        countryStack.spacing = 8
        countryStack.backgroundColor = backgroundColor

        countryStack.translatesAutoresizingMaskIntoConstraints = false
      
        let audioMessageStack = UIStackView()
        audioMessageStack.alignment = .leading
        audioMessageStack.axis = .horizontal
        audioMessageStack.spacing = 8
        audioMessageStack.backgroundColor = backgroundColor

        audioMessageStack.translatesAutoresizingMaskIntoConstraints = false
      
        let alertMessageStack = UIStackView()
        alertMessageStack.alignment = .leading
        alertMessageStack.axis = .horizontal
        alertMessageStack.spacing = 8
        alertMessageStack.backgroundColor = backgroundColor

        alertMessageStack.translatesAutoresizingMaskIntoConstraints = false

        let violationMessageStack = UIStackView()
        violationMessageStack.alignment = .leading
        violationMessageStack.axis = .horizontal
        violationMessageStack.spacing = 8
        violationMessageStack.backgroundColor = backgroundColor

        violationMessageStack.translatesAutoresizingMaskIntoConstraints = false

        let adrLabelTitle = UILabel()
        adrLabelTitle.text = "Street name: "
        adrLabelTitle.textColor = .red

        let speedLimitTitle = UILabel()
        speedLimitTitle.text = "Speed limit: "
        speedLimitTitle.textColor = .orange

        let cityTitle = UILabel()
        cityTitle.text = "City: "
        cityTitle.textColor = .purple

        violationWarningTitle = UILabel()
        violationWarningTitle.text = "Violation warning: "
        violationWarningTitle.textColor = .green

        addressLabel = UILabel()
        addressLabel.textColor = .red
        speedLimit = UILabel()
        speedLimit.textColor = .orange
        cityName = UILabel()
        cityName.textColor = .purple
      
        audioMessage = UILabel()
        audioMessage.textColor = .brown
        audioMessage.numberOfLines = 2
        audioMessage.adjustsFontSizeToFitWidth = true
        audioMessage.minimumScaleFactor = 0.8
        audioMessage.text = "Audio message: "
      
        alertMessage = UILabel()
        alertMessage.textColor = .blue
        alertMessage.numberOfLines = 7
        alertMessage.adjustsFontSizeToFitWidth = true
        alertMessage.minimumScaleFactor = 0.8
        alertMessage.text = "Alert message: "

        violationMessage = UILabel()
        violationMessage.textColor = violationWarningTitle.textColor

        addressStack.addArrangedSubview(adrLabelTitle)
        addressStack.addArrangedSubview(addressLabel)

        speedLimitStack.addArrangedSubview(speedLimitTitle)
        speedLimitStack.addArrangedSubview(speedLimit)

        countryStack.addArrangedSubview(cityTitle)
        countryStack.addArrangedSubview(cityName)
      
        audioMessageStack.addArrangedSubview(audioMessage)
      
        alertMessageStack.addArrangedSubview(alertMessage)

        violationMessageStack.addArrangedSubview(violationWarningTitle)
        violationMessageStack.addArrangedSubview(violationMessage)

        driveSessionLabelStack.addArrangedSubview(addressStack)
        driveSessionLabelStack.addArrangedSubview(speedLimitStack)
        driveSessionLabelStack.addArrangedSubview(countryStack)
        driveSessionLabelStack.addArrangedSubview(audioMessageStack)
        driveSessionLabelStack.addArrangedSubview(alertMessageStack)
        driveSessionLabelStack.addArrangedSubview(violationMessageStack)

        driveSessionLabelStack.isHidden = true

        mapView.addSubview(driveSessionLabelStack)
      
        NSLayoutConstraint.activate([
            driveSessionLabelStack.topAnchor.constraint(equalTo: mapView.topAnchor),
            driveSessionLabelStack.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            driveSessionLabelStack.trailingAnchor.constraint(equalTo: mapView.trailingAnchor)
        ])
    }
    
    func setupUI() {
        mapView = VNMapView()
        overrideUserInterfaceStyle = .unspecified
        mapView.preferredFPS = 30
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.annotationTouchDelegate = self
        view.addSubview(mapView)
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
      
        view.addSubview(navigationSessionButton)
        
        NSLayoutConstraint.activate([
            navigationSessionButton.widthAnchor.constraint(equalToConstant: 40),
            navigationSessionButton.heightAnchor.constraint(equalToConstant: 40),
            navigationSessionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16.0),
            navigationSessionButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        navigationSessionButton.addTarget(
            self,
            action: #selector(navigationSessionButtonTapped),
            for: .touchUpInside
        )
        
        view.addSubview(cameraSettingsButton)
        
        NSLayoutConstraint.activate([
            cameraSettingsButton.widthAnchor.constraint(equalToConstant: 40),
            cameraSettingsButton.heightAnchor.constraint(equalToConstant: 40),
            cameraSettingsButton.bottomAnchor.constraint(equalTo: navigationSessionButton.topAnchor, constant: -16.0),
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
      
        view.addSubview(cameraRenderModeButton)
        
        NSLayoutConstraint.activate([
            cameraRenderModeButton.widthAnchor.constraint(equalToConstant: 40),
            cameraRenderModeButton.heightAnchor.constraint(equalToConstant: 40),
            cameraRenderModeButton.bottomAnchor.constraint(equalTo: vehicleTrackButton.topAnchor, constant: -16.0),
            cameraRenderModeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        cameraRenderModeButtonUpdate(mode: cameraRenderMode)
        cameraRenderModeButton.setTitle("3D", for: .normal)
        cameraRenderModeButton.addTarget(self, action: #selector(cameraRenderModeButtonTapped), for: .touchUpInside)
        
        view.addSubview(switchColorScheme)
        
        NSLayoutConstraint.activate([
            switchColorScheme.widthAnchor.constraint(equalToConstant: 40),
            switchColorScheme.heightAnchor.constraint(equalToConstant: 40),
            switchColorScheme.bottomAnchor.constraint(equalTo: cameraRenderModeButton.topAnchor, constant: -16.0),
            switchColorScheme.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
        
        switchColorScheme.addTarget(
            self,
            action: #selector(switchColorSchemeButtonTapped),
            for: .touchUpInside
        )
      
        view.addSubview(poiSearchButton)
        
        NSLayoutConstraint.activate([
          poiSearchButton.widthAnchor.constraint(equalToConstant: 40),
          poiSearchButton.heightAnchor.constraint(equalToConstant: 40),
          poiSearchButton.bottomAnchor.constraint(equalTo: switchColorScheme.topAnchor, constant: -16.0),
          poiSearchButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
        ])
      
        poiSearchButton.addTarget(
            self,
            action: #selector(poiSearchButtonTapped),
            for: .touchUpInside
        )
      
        startNavigationButton.isHidden = true
      
        startNavigationButton.addTarget(
            self,
            action: #selector(startNavigationButtonTapped),
            for: .touchUpInside
        )
      
        followVehicleButton.isHidden = true
      
        followVehicleButton.addTarget(
            self,
            action: #selector(followVehicleButtonTapped),
            for: .touchUpInside
        )
      
        cameraModeButton.isHidden = true
      
        cameraModeButton.addTarget(
            self,
            action: #selector(cameraModeButtonTapped),
            for: .touchUpInside
        )
        
        mapView.addSubview(collectionView)
        mapView.addSubview(imageView)
        mapView.addSubview(travelEstimationLbl)
        mapView.addSubview(startNavigationButton)
        mapView.addSubview(followVehicleButton)
        mapView.addSubview(cameraModeButton)
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
            let image = UIImage(named: "car-icon")!

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
    
    @objc func switchColorSchemeButtonTapped() {
        isNightModeActive.toggle()
        VNSDK.sharedInstance.dayNightMode = isNightModeActive ? .nightMode : .dayMode
        
        renderUpdateFor(button: switchColorScheme, with: isNightModeActive)
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
        
        collectionView.isHidden = !isNavigationSessionActive
        
        if isNavigationSessionActive == false {
            setupMapCustomGestureRecognizers()
            startNavigationButton.isHidden = true
            followVehicleButton.isHidden = true
            cameraModeButton.isHidden = true
            if navigationSession != nil {
                stopNavigation()
                navigationSession = nil
            }
            selectedRoute = nil
            firstRoutePoint = nil
            secondRoutePoint = nil
            
            if (fromAnnotation != nil) {
                mapView.annotationsController().remove([fromAnnotation!])
                fromAnnotation = nil
            }
            if (toAnnotation != nil) {
                mapView.annotationsController().remove([toAnnotation!])
                toAnnotation = nil
            }

            routes.removeAll()
            let routeIds = self.routeModels.map { $0.getRouteId() }
            mapView.routeController().removeRoutes(routeIds)
            collectionView.reloadData()
            return
        }
        
        setupNavLongPressGestures()
    }
  
    @objc func startNavigationButtonTapped() {
      self.startNavigation()
      self.startNavigationButton.isHidden = true
    }
  
    @objc func followVehicleButtonTapped() {
      mapView.cameraController().enable(currentCameraMode, useAutoZoom: true)
      setupInNavigationGestures()
      followVehicleButton.isHidden = true
      cameraModeButton.isHidden = false
    }
  
    @objc func cameraModeButtonTapped() {
      if (currentCameraMode == .headingUp) {
        currentCameraMode = .northUp
        cameraModeButton.setTitle(" North Up ", for: .normal)
      } else if (currentCameraMode == .northUp) {
        currentCameraMode = .static
        cameraModeButton.setTitle(" Static ", for: .normal)
      } else if (currentCameraMode == .static) {
        currentCameraMode = .headingUp
        cameraModeButton.setTitle(" Heading Up ", for: .normal)
      }
      
      mapView.cameraController().enable(currentCameraMode, useAutoZoom: true)
    }
  
    @objc func poiSearchButtonTapped() {
      isPoiSearchActive.toggle()
      
      renderUpdateFor(
          button: poiSearchButton,
          with: isPoiSearchActive
      )
      
      if (isPoiSearchActive) {
        searchEngine.currentLocation = mapView.cameraController().position.location;
        mapView.searchController().displayPOI(["811"]) // Fuel
      } else {
        mapView.searchController().clear()
      }
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
  
    func addFromPointAnnotation(location: VNGeoPoint) {
        let annotationController = mapView.annotationsController()
        let pushPinImage = UIImage(named: "map-push-pin-s")!
        
        if let annotation = fromAnnotation {

            annotationController.remove([annotation])
            fromAnnotation = nil
        }
        
        let fromAnnotation = annotationController.factory().create(
            with: pushPinImage,
            location: .init(latitude: location.latitude, longitude: location.longitude)
        )
        
        fromAnnotation.verticalOffset = -0.05
        fromAnnotation.style = .screenFlagNoCulling
        
        self.fromAnnotation = fromAnnotation
        annotationController.add([fromAnnotation])
    }
  
    func addToPointAnnotation(location: VNGeoPoint) {
        let annotationController = mapView.annotationsController()
        let pushPinImage = UIImage(named: "map-push-pin-f")!
        
        if let annotation = toAnnotation {
            annotationController.remove([annotation])
            toAnnotation = nil
        }
        
        let finishAnnotation = annotationController.factory().create(
            with: pushPinImage,
            location: .init(latitude: location.latitude, longitude: location.longitude)
        )
        
        finishAnnotation.verticalOffset = -0.05
        finishAnnotation.style = .screenFlagNoCulling
        
        self.toAnnotation = finishAnnotation
        annotationController.add([finishAnnotation])
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
  
    private func setupInNavigationGestures() {
        if tapGestureRecognizer != nil {
          mapView.removeGestureRecognizer(tapGestureRecognizer)
        }
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(inNavigationGestureAction))
        mapView.addGestureRecognizer(tapGestureRecognizer)
      
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(inNavigationGestureAction))
        mapView.addGestureRecognizer(panGestureRecognizer)
      
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(inNavigationGestureAction))
        mapView.addGestureRecognizer(pinchGestureRecognizer)
      
        rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(inNavigationGestureAction))
        mapView.addGestureRecognizer(rotationGestureRecognizer)
    }
  
    private func restoreGestures() {
        if tapGestureRecognizer != nil {
          mapView.removeGestureRecognizer(tapGestureRecognizer)
          tapGestureRecognizer = nil
        }
      
        if panGestureRecognizer != nil {
          mapView.removeGestureRecognizer(panGestureRecognizer)
          panGestureRecognizer = nil
        }
      
        if pinchGestureRecognizer != nil {
          mapView.removeGestureRecognizer(pinchGestureRecognizer)
          pinchGestureRecognizer = nil
        }
      
        if rotationGestureRecognizer != nil {
          mapView.removeGestureRecognizer(rotationGestureRecognizer)
          rotationGestureRecognizer = nil
        }
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
        annotationMenuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
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
            let geoPoint = VNGeoPoint.init(latitude: geoLocation.latitude, longitude: geoLocation.longitude)
            self?.addFromPointAnnotation(location: geoPoint!)
            self?.createRoute()
        })
        alertController.addAction(fromAction)
        
        let toAction = UIAlertAction(title: "To here", style: .default, handler: { [weak self] (action) in
            self?.secondRoutePoint = VNGeoLocation(latitude: geoLocation.latitude, longitude: geoLocation.longitude)
            let geoPoint = VNGeoPoint.init(latitude: geoLocation.latitude, longitude: geoLocation.longitude)
            self?.addToPointAnnotation(location: geoPoint!)
            self?.createRoute()
        })
        alertController.addAction(toAction)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
  
    @objc private func inNavigationGestureAction(_ gestureRecognizer: UITapGestureRecognizer) {
      if (followVehicleButton.isHidden) {
        mapView.cameraController().disableFollowVehicle()
        restoreGestures()
        followVehicleButton.isHidden = false
        cameraModeButton.isHidden = true
      }
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
        
        if let image = UIImage(named: "demo-annotaion-pushpin-green") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            mapView.annotationsController().add([annotation])
          
            let annotationState = AnnotationState(isSelected: false, annotaton: annotation)
            demoAnnotations.append(annotationState)
        }
    }
    
    private func addTextAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = mapView.annotationsController().factory()
        
        if let image = UIImage(named: "demo-annotaion-pushpin-green") {
            let annotation = annotationsFactory.create(with: image, location: location)
            annotation.style = .screenFlagNoCulling
            
            let textDisplay = VNTextDisplayInfo(centeredText: "face.smiling")
            textDisplay.textColor = .black
            textDisplay.textFontSize = 14
            
            annotation.displayText = textDisplay
            mapView.annotationsController().add([annotation])
          
            let annotationState = AnnotationState(isSelected: false, annotaton: annotation)
            demoAnnotations.append(annotationState)
        }
    }
  
    private func addExplicitStyleAnnotationTo(location: CLLocationCoordinate2D) {
        let annotationsFactory = mapView.annotationsController().factory()
        
        let annotation = annotationsFactory.create(with: .lightCongestionBubble, location: location)
        
        let textDisplay = VNTextDisplayInfo(centeredText: "Bubble")
        textDisplay.textColor = .black
        textDisplay.textFontSize = 14
        
        annotation.displayText = textDisplay
        mapView.annotationsController().add([annotation])
      
        let annotationState = AnnotationState(isSelected: false, annotaton: annotation)
        demoAnnotations.append(annotationState)
    }
  
    private func removeAllAnnotation() {
        let annotations = demoAnnotations.compactMap { $0.annotaton }
        mapView.annotationsController().remove( annotations )
        demoAnnotations.removeAll()
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
      
        self.startNavigationButton.isHidden = true
    }
  
    func moveMapCameraTo(to coordinate: CLLocationCoordinate2D, zoomLevel: Int? = nil) {
        let point = VNGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let position = self.mapView.cameraController().position
        var currentZoomLevel = position.zoomLevel
        if let zoomLevel = zoomLevel {
          currentZoomLevel = NSNumber.init(value: zoomLevel)
        }
        let cameraPosition = VNCameraPosition(bearing: position.bearing, tilt: position.tilt, zoomLevel: currentZoomLevel, location: point)
        self.mapView.cameraController().position = cameraPosition
    }
}


//MARK: - Route collection view

extension TelenavMapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let routeCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouteCell", for: indexPath as IndexPath) as? RouteCell {
            routeCell.titleLabel.text = "Route: \(indexPath.row + 1)"
            routeCell.isSelected = false
            return routeCell
            
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        DispatchQueue.main.async {
            let route = self.routes[indexPath.row]
            let routeModel = self.routeModels[indexPath.row]
            
            let routeDuration = route.duration.secondsToHoursMinutesSeconds() ?? ""
            let durationText = "Route duration: \(routeDuration)"
            self.travelEstimationLbl.text = durationText
          
            self.selectedRoute = route
            self.selectedRouteModel = routeModel
            self.showTurnArrows(routeName: routeModel.getRouteId(), route: route)
            self.mapView.routeController().unhighlight()
            self.mapView.routeController().highlight(routeModel.getRouteId())
            self.startNavigationButton.isHidden = false
        }
    }
}

extension TelenavMapViewController: VNNavigationSessionDelegate {
    
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
  
    func onUpdate(_ navStatus: VNNavStatus!) {
        if navStatus.navigationSignal.count != 0 {
            processNavigationSignals(signals: navStatus.navigationSignal)
        }
      
        // Set turnAction
        var turnAction = VNManeuverAction.NONE
        let route = navStatus.route
        
        let legs = route.legs
        let legIndex = Int(navStatus.currentLegIndex)
        if (legIndex >= 0 && legIndex < legs.count) {
          let steps = legs[legIndex].steps
          let stepIndex = Int(navStatus.currentStepIndex)
          if (stepIndex >= 0 && stepIndex < steps.count) {
            turnAction = steps[stepIndex].maneuver.action
          }
        }
        
        // Fill stepInfo
        let MPH_TO_MS = Float(1.609344) / Float(3.6)
        let KPH_TO_MS = Float(1.0) / Float(3.6)
        let stepInfo = VNStepInfo.init(routeId: selectedRouteModel?.getRouteId() ?? "",
                                       currentLegIndex: navStatus.currentLegIndex,
                                       currentStep: navStatus.currentStepIndex,
                                       currentEdgeIndex: navStatus.currentEdgeIndex,
                                       currentPointIndex: navStatus.currentEdgePointIndex,
                                       currentRoadType: Int32(navStatus.roadType.rawValue),
                                       currentRoadSubType: Int32(navStatus.roadSubtype.rawValue),
                                       turnAction: Int32(turnAction.rawValue),
                                       distanceToTurn: Float(navStatus.distanceToTurn),
                                       speedLimit: (navStatus.speedLimit.unit == .MPH
                                                      ? Float(navStatus.speedLimit.value) * MPH_TO_MS
                                                      : Float(navStatus.speedLimit.value) * KPH_TO_MS),
                                       vehicleSpeed: navStatus.vehicleSpeed,
                                       heading: Float(navStatus.vehicleHeading),
                                       passedDistance: navStatus.traveledDistance,
                                       isNextTightTurn: navStatus.isNextStepTightTurn)
        
        // Fill location
        let location = CLLocation.init(
          coordinate: .init(latitude: navStatus.vehicleLocation.latitude, longitude: navStatus.vehicleLocation.longitude),
          altitude: 0, // not used
          horizontalAccuracy: CLLocationAccuracy(accuracy),
          verticalAccuracy: CLLocationAccuracy(accuracy),
          course: CLLocationDirection(navStatus.vehicleHeading),
          speed: CLLocationSpeed(navStatus.vehicleSpeed),
          timestamp: Date() // not used
        )
        
        mapView.vehicleController().setStepInfoAndLocation(stepInfo, location: location)
    }
}

extension TelenavMapViewController: VNPositionEventDelegate {
    
    func onLocationUpdated(_ vehicleLocation: VNVehicleLocationInfo) {
        accuracy = vehicleLocation.locationAccuracy
    }
  
    func onStreetUpdated(_ curStreetInfo: VNStreetInfo) {
      DispatchQueue.main.async {
        self.addressLabel.text = curStreetInfo.streetName ?? "Null received"
        
        let speedLimitValue = curStreetInfo.speedLimit?.value ?? VN_INVALID_SPEED_LIMIT
        if (speedLimitValue == VN_MAX_SPEED_UNLIMITED) {
          self.speedLimit.text = "Max Speed Unlimited"
        } else if (speedLimitValue == VN_INVALID_SPEED_LIMIT) {
          self.speedLimit.text = "Null received"
        } else {
          let unitValue = SpeedLimitUnit(rawValue: curStreetInfo.speedLimit?.unit.rawValue ?? VNSpeedUnit.MPH.rawValue)
          self.speedLimit.text = "\(speedLimitValue) \(unitValue?.unitStringRepresentation ?? "")"
        }
        
        self.cityName.text = curStreetInfo.adminInfo?.city ?? "Null received"
      }
    }
}

extension TelenavMapViewController: VNAudioEventDelegate {
    func onAudioInstructionUpdated(_ audioInstruction: VNAudioInstruction) {
        DispatchQueue.main.async {
          let audioString = audioInstruction.audioOrthographyString ?? "Null received"
          self.audioMessage.text = "Audio message: \(audioString)"
        }
    }
}

extension TelenavMapViewController: VNAlertServiceDelegate {
    func onAlertInfoUpdate(_ alertInfo: VNAlertInfo!) {
        DispatchQueue.main.async {
            let alersString = self.alertsToString(alerts: alertInfo.aheadAlerts)
            let separator = alersString.isEmpty ? "" : "\n"
            self.alertMessage.text = "Alert message: \(separator)\(alersString)"
        }
    }

    func onViolationWarningUpdate(_ violationWarning: VNViolationWarning!) {
        if violationWarning.warnings.isEmpty == false {
            violationWarning.warnings.forEach { warning in
                let warnings = ViolationType(rawValue: warning.type.rawValue)
                DispatchQueue.main.async {
                    switch warnings {
                    case .invalidAttention:
                        self.violationWarningTitle.textColor = .green
                        self.violationMessage.textColor = self.violationWarningTitle.textColor
                    case .overSpeedAttention:
                        self.violationWarningTitle.textColor = .red
                        self.violationMessage.textColor =  self.violationWarningTitle.textColor

                    case .none:
                        self.violationWarningTitle.textColor = .green
                        self.violationMessage.textColor = self.violationWarningTitle.textColor
                    }
                    let text = warnings?.violationTypeStringRepresentation ?? ""
                    self.violationMessage.text = text
                }
            }
        }
    }

    func alertsToString(alerts: [VNAlertItem]) -> String {
      var alertsAsString = ""
      for alert in alerts {
        alertsAsString += alert.type.asString
        alertsAsString += "\n"
        alertsAsString += "to vehicle: \(alert.distanceToVehicle)"
        alertsAsString += "\n"
      }
      return alertsAsString
    }
}

extension TelenavMapViewController: VNMapViewAnnotationTouchDelegate {
  func mapView(_ mapView: VNMapView, touchedAnnotaion annotaion: VNAnnotation?) {
    guard let annotaion = annotaion else {
      return
    }
    
    guard let demoAnnotation = demoAnnotations.first(where: { $0.annotaton === annotaion }) else {
      return
    }
    
    if demoAnnotation.isSelected {
      if demoAnnotation.annotaton.displayText != nil {
        let textDisplay = VNTextDisplayInfo(centeredText: "did touche")
        textDisplay.textColor = .black
        textDisplay.textFontSize = 14
        
        demoAnnotation.annotaton.displayText = textDisplay
        mapView.annotationsController().add([demoAnnotation.annotaton])
      } else {
        demoAnnotation.annotaton.image = UIImage(named: "demo-annotaion-pushpin-green")
        mapView.annotationsController().add([demoAnnotation.annotaton])
      }
    } else {
      if demoAnnotation.annotaton.displayText != nil {
        let textDisplay = VNTextDisplayInfo(centeredText: "did touche")
        textDisplay.textColor = .red
        textDisplay.textFontSize = 14
        
        demoAnnotation.annotaton.displayText = textDisplay
        mapView.annotationsController().add([demoAnnotation.annotaton])
      } else {
        demoAnnotation.annotaton.image = UIImage(named: "demo-annotaion-pushpin-red")
        mapView.annotationsController().add([demoAnnotation.annotaton])
      }
    }
    
    demoAnnotation.isSelected.toggle()
  }
}

extension TelenavMapViewController {
    func setupLocationManager() {
      // need to init CoordinateSettingsController
      if let viewControllers = tabBarController?.viewControllers {
          for navVC in viewControllers {
              if let navVC = navVC as? UINavigationController,
                 let coordVC = navVC.topViewController as? CoordinateSettingsController {
                  let _ = coordVC.view
              }
          }
      }
      
      currentLocation = locationProvider.location
      moveMapCameraTo(to: currentLocation, zoomLevel: 8)
    }
}

extension TelenavMapViewController: LocationProviderDelegate {
  func locationProvider(provider: LocationProvider, locationDidChanged location: CLLocationCoordinate2D) {
    let from = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
    let to = CLLocation(latitude: location.latitude, longitude: location.longitude)
    
    if to.distance(from: from) > 500 /* meters */ {
      moveMapCameraTo(to: location)
    }
    
    currentLocation = location
  }
}
