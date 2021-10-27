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


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDriveSessionService()
    }
    
}

private extension DriveSessionViewController {

    func setupUI() {

        title = "Drive Session"

        mapView = VNMapView()

        mapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mapView)

        let safeAreaLayoutGuide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
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
            longitude: vehicleLocation.lon)
        )
    }
}
