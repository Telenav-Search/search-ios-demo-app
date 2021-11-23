//
//  DriveSessionViewController.swift
//  TelenavDemo
//
//  Created by Anatol Uarmolovich on 26.10.21.
//

import UIKit
import VividDriveSessionSDK

class DriveSessionViewController: UIViewController {

    private var mapView: VNMapView!
    private var driveSession: VNDriveSessionClient!
    private var navigationSession: VNNavigationSession!
    private var route: VNRoute!
  
    private var addressLabel: UILabel!
    private var speedLimit: UILabel!
    private var cityName: UILabel!
    private var audioMessage: UILabel!
    private var alertMessage: UILabel!
    private var violationMessage: UILabel!
    private var violationWarningTitle: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDriveSessionService()
        setupAudioGuidanceService()
        setupNavigationSession()
        startSimulateNavigation()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle == .dark {
            VNSDK.sharedInstance.dayNightMode = .dayMode
        } else {
            VNSDK.sharedInstance.dayNightMode = .nightMode
        }
    }

    deinit {
      driveSession.dispose()
    }
}

private extension DriveSessionViewController {

    func setupUI() {

        title = "Drive Session"

        mapView = VNMapView()

        mapView.preferredFPS = 30

        mapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mapView)

        let safeAreaLayoutGuide = view.safeAreaLayoutGuide

        let mainLabelStack = UIStackView()
        mainLabelStack.alignment = .leading
        mainLabelStack.axis = .vertical

        mainLabelStack.translatesAutoresizingMaskIntoConstraints = false

        let addressStack = UIStackView()
        addressStack.alignment = .leading
        addressStack.axis = .horizontal
        addressStack.spacing = 8

        let speedLimitStack = UIStackView()
        speedLimitStack.alignment = .leading
        speedLimitStack.axis = .horizontal
        speedLimitStack.spacing = 8

        speedLimitStack.translatesAutoresizingMaskIntoConstraints = false

        let countryStack = UIStackView()
        countryStack.alignment = .leading
        countryStack.axis = .horizontal
        countryStack.spacing = 8

        countryStack.translatesAutoresizingMaskIntoConstraints = false
      
        let audioMessageStack = UIStackView()
        audioMessageStack.alignment = .fill
        audioMessageStack.axis = .horizontal
        audioMessageStack.spacing = 8

        audioMessageStack.translatesAutoresizingMaskIntoConstraints = false

        let alertMessageStack = UIStackView()
        alertMessageStack.alignment = .leading
        alertMessageStack.axis = .horizontal
        alertMessageStack.spacing = 8

        alertMessageStack.translatesAutoresizingMaskIntoConstraints = false

        let violationMessageStack = UIStackView()
        violationMessageStack.alignment = .leading
        violationMessageStack.axis = .horizontal
        violationMessageStack.spacing = 8

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
      
        let audioMessageTitle = UILabel()
        audioMessageTitle.text = "Audio message: "
        audioMessageTitle.textColor = .brown

        let alertMessageTitle = UILabel()
        alertMessageTitle.text = "Alert message: "
        alertMessageTitle.textColor = .blue

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
        audioMessage.numberOfLines = 2
        audioMessage.lineBreakMode = .byWordWrapping
        audioMessage.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        audioMessage.textColor = audioMessageTitle.textColor

        alertMessage = UILabel()
        alertMessage.textColor = alertMessageTitle.textColor
        alertMessage.numberOfLines = 6
        alertMessage.adjustsFontSizeToFitWidth = true
        alertMessage.minimumScaleFactor = 0.8

        violationMessage = UILabel()
        violationMessage.textColor = violationWarningTitle.textColor
        violationMessage.numberOfLines = 2

        addressStack.addArrangedSubview(adrLabelTitle)
        addressStack.addArrangedSubview(addressLabel)

        speedLimitStack.addArrangedSubview(speedLimitTitle)
        speedLimitStack.addArrangedSubview(speedLimit)

        countryStack.addArrangedSubview(cityTitle)
        countryStack.addArrangedSubview(cityName)
      
        audioMessageStack.addArrangedSubview(audioMessageTitle)
        audioMessageStack.addArrangedSubview(audioMessage)

        alertMessageStack.addArrangedSubview(alertMessageTitle)
        alertMessageStack.addArrangedSubview(alertMessage)

        violationMessageStack.addArrangedSubview(violationWarningTitle)
        violationMessageStack.addArrangedSubview(violationMessage)

        mainLabelStack.addArrangedSubview(addressStack)
        mainLabelStack.addArrangedSubview(speedLimitStack)
        mainLabelStack.addArrangedSubview(countryStack)
        mainLabelStack.addArrangedSubview(audioMessageStack)
        mainLabelStack.addArrangedSubview(alertMessageStack)
        mainLabelStack.addArrangedSubview(violationMessageStack)

        mainLabelStack.backgroundColor = .white
        mainLabelStack.alpha = 0.9

        mapView.addSubview(mainLabelStack)


        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            mainLabelStack.topAnchor.constraint(equalTo: mapView.topAnchor),
            mainLabelStack.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            mainLabelStack.trailingAnchor.constraint(equalTo: mapView.trailingAnchor)
        ])

        mapView.vehicleController().setIcon(UIImage(named: "car-icon"))
        mapView.featuresController().traffic.setEnabled()
        mapView.featuresController().compass.setEnabled()
        mapView.cameraController().renderMode = .M3D
        mapView.cameraController().enable(.headingUp, useAutoZoom: true)
    }

    func setupDriveSessionService() {
        driveSession = VNDriveSessionClient.factory().build()
        driveSession.positionEventDelegate = self
        driveSession.alertEventDelegate = self
    }
  
    func setupAudioGuidanceService() {
        driveSession.enableAudioDefaultPlayback(true);
        driveSession.audioEventDelegate = self
    }
  
    func setupNavigationSession() {
        navigationSession = driveSession.createNavigationSession()
        //navigationSession.delegate = self
    }
  
    func startSimulateNavigation() {
        requestTestRoute { [weak self, weak navigationSession] route in
            if let route = route {
                self?.route = route
                navigationSession?.updateRouteInfo(route)
                navigationSession?.startSimulateNavigation()
            }
        }
    }
  
    func requestTestRoute(completion: @escaping (_ route: VNRoute?) -> Void) {
        let client = VNDirectionClient.factory().build()
        let origin = VNGeoLocation(latitude: 37.73141671, longitude: -122.42359098)
        let destination = VNGeoLocation(latitude: 37.73175391, longitude: -121.42104766)
        
        let routeRequest = VNRouteRequest.builder()
            .setOrigin(origin)
            .setDestination(destination)
            .build()!
        
        let task = client?.createRouteCalculationTask(routeRequest)
        task?.runAsync({ response, error in
            if let response = response {
                completion(response.routes[0])
            }
        })
    }
}

extension DriveSessionViewController: VNPositionEventDelegate {
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
    }

    func onStreetUpdated(_ curStreetInfo: VNStreetInfo) {
        DispatchQueue.main.async {
            self.addressLabel.text = curStreetInfo.streetName ?? "Null received"

            if let value = curStreetInfo.speedLimit?.value,
               let unit = curStreetInfo.speedLimit?.unit {

                let unitValue = SpeedLimitUnit(rawValue: unit.rawValue)

                let speedLimit = "\(value) \(unitValue?.unitStringRepresentation ?? "Null received")"

                self.speedLimit.text = speedLimit

            } else {
                self.speedLimit.text = "Null received"
            }

            if let city = curStreetInfo.adminInfo?.city  {
                self.cityName.text = city
            } else {
                self.cityName.text = "Null received"
            }

        }
    }

    func onCandidateRoadDetected(_ roadCalibrator: VNRoadCalibrator) {}
}

extension DriveSessionViewController: VNAudioEventDelegate {
    func onAudioInstructionUpdated(_ audioInstruction: VNAudioInstruction) {
        DispatchQueue.main.async {
            if let audioString = audioInstruction.audioOrthographyString {
                self.audioMessage.text = audioString
            } else {
                self.audioMessage.text = "Null received"
            }
        }
    }
}

extension DriveSessionViewController: VNAlertServiceDelegate {
    func onAlertInfoUpdate(_ alertInfo: VNAlertInfo!) {
        if alertInfo.aheadAlerts.isEmpty == false {
            DispatchQueue.main.async {
                self.alertMessage.text = self.alertsToString(alerts: alertInfo.aheadAlerts)
            }
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
