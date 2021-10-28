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
    private var addressLabel: UILabel!
    private var speedLimit: UILabel!
    private var country: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDriveSessionService()
    }

    deinit {

    }
}

private extension DriveSessionViewController {

    func setupUI() {

        title = "Drive Session"

        mapView = VNMapView()

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

        let adrLabelTitle = UILabel()
        adrLabelTitle.text = "Address: "
        adrLabelTitle.textColor = .red

        let speedLimitTitle = UILabel()
        speedLimitTitle.text = "Speed limit: "
        speedLimitTitle.textColor = .orange

        let countryTitle = UILabel()
        countryTitle.text = "Country: "
        countryTitle.textColor = .purple

        addressLabel = UILabel()
        addressLabel.textColor = .red
        speedLimit = UILabel()
        speedLimit.textColor = .orange
        country = UILabel()
        country.textColor = .purple


        addressStack.addArrangedSubview(adrLabelTitle)
        addressStack.addArrangedSubview(addressLabel)

        speedLimitStack.addArrangedSubview(speedLimitTitle)
        speedLimitStack.addArrangedSubview(speedLimit)

        countryStack.addArrangedSubview(countryTitle)
        countryStack.addArrangedSubview(country)

        mainLabelStack.addArrangedSubview(addressStack)
        mainLabelStack.addArrangedSubview(speedLimitStack)
        mainLabelStack.addArrangedSubview(countryStack)

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

    }

    func setupDriveSessionService() {
        driveSession = VNDriveSessionClient.factory().build()
        driveSession.positionEventDelegate = self
    }
}

extension DriveSessionViewController: VNPositionEventDelegate {
    func onLocationUpdated(_ vehicleLocation: VNVehicleLocationInfo) {
        let cameraPosition = VNCameraPosition.init(
            bearing: mapView.cameraController().position.bearing,
            tilt: mapView.cameraController().position.tilt,
            zoomLevel: mapView.cameraController().position.zoomLevel,
            location: VNGeoPoint.init(
                latitude: vehicleLocation.lat,
                longitude: vehicleLocation.lon
            )
        )
        mapView.cameraController().position = cameraPosition
        mapView.vehicleController().setLocation(CLLocation.init(
            latitude: vehicleLocation.lat,
            longitude: vehicleLocation.lon
        )
        )
    }

    func  onStreetUpdated(_ curStreetInfo: VNStreetInfo) {
        DispatchQueue.main.async {
            self.addressLabel.text = curStreetInfo.combinedStreetName ?? "Null received"

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

    func onCandidateRoadDetected(_ roadCalibrator: VNRoadCalibrator) {

    }
}
