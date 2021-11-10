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
    private var country: UILabel!
    private var audioMessage: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDriveSessionService()
        setupAudioGuidanceService()
        setupNavigationSession()
        startSimulateNavigation()
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

        let adrLabelTitle = UILabel()
        adrLabelTitle.text = "Street name: "
        adrLabelTitle.textColor = .red

        let speedLimitTitle = UILabel()
        speedLimitTitle.text = "Speed limit: "
        speedLimitTitle.textColor = .orange

        let countryTitle = UILabel()
        countryTitle.text = "Country: "
        countryTitle.textColor = .purple
      
        let audioMessageTitle = UILabel()
        audioMessageTitle.text = "Audio message: "
        audioMessageTitle.textColor = .brown

        addressLabel = UILabel()
        addressLabel.textColor = .red
        speedLimit = UILabel()
        speedLimit.textColor = .orange
        country = UILabel()
        country.textColor = .purple
        audioMessage = UILabel()
        audioMessage.numberOfLines = 0
        audioMessage.lineBreakMode = .byWordWrapping
        audioMessage.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        audioMessage.textColor = audioMessageTitle.textColor

        addressStack.addArrangedSubview(adrLabelTitle)
        addressStack.addArrangedSubview(addressLabel)

        speedLimitStack.addArrangedSubview(speedLimitTitle)
        speedLimitStack.addArrangedSubview(speedLimit)

        countryStack.addArrangedSubview(countryTitle)
        countryStack.addArrangedSubview(country)
      
        audioMessageStack.addArrangedSubview(audioMessageTitle)
        audioMessageStack.addArrangedSubview(audioMessage)

        mainLabelStack.addArrangedSubview(addressStack)
        mainLabelStack.addArrangedSubview(speedLimitStack)
        mainLabelStack.addArrangedSubview(countryStack)
        mainLabelStack.addArrangedSubview(audioMessageStack)

        mapView.addSubview(mainLabelStack)


        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            mainLabelStack.topAnchor.constraint(equalTo: mapView.topAnchor),
            mainLabelStack.leadingAnchor.constraint(equalTo: mapView.leadingAnchor)
        ])

        mapView.vehicleController().setIcon(UIImage(systemName: "car"))
        mapView.featuresController().traffic.setEnabled()
        mapView.featuresController().compass.setEnabled()
        mapView.cameraController().renderMode = .M3D
        mapView.cameraController().enable(.headingUp, useAutoZoom: true)
    }

    func setupDriveSessionService() {
        driveSession = VNDriveSessionClient.factory().build()
        driveSession.positionEventDelegate = self
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

            if let country = curStreetInfo.adminInfo?.country  {
                self.country.text = country
            } else {
                self.country.text = "Null received"
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
