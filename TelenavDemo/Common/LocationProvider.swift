//
//  LocationProvider.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 29.11.2021.
//

import Foundation
import CoreLocation

protocol LocationProviderDelegate: AnyObject {
  func locationProvider(provider: LocationProvider, locationDidChanged location: CLLocationCoordinate2D)
}

class LocationProvider: NSObject {
  static let shared = LocationProvider()
  
  private var listners: [LocationProviderDelegate] = []
  private var locationManager = CLLocationManager()
  private var _location: CLLocationCoordinate2D = DemoConstants.defaultLocation
  private var isProviderRunning = false
  
  var location: CLLocationCoordinate2D {
    return _location
  }
  
  func addListner(listner: LocationProviderDelegate) {
    listners.append(listner)
  }

  func removeListner(listner: LocationProviderDelegate) {
    listners.removeAll(where: { $0 === listner })
  }
  
  private func runProvider() {
    isProviderRunning = true
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()

    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
    }
  }
  
  private func stopProvider() {
    isProviderRunning = false
    locationManager.stopUpdatingLocation()
  }
  
  func fakeLocation(location: CLLocationCoordinate2D?) {
    if location != nil && isProviderRunning == true {
      stopProvider()
    } else if location == nil && isProviderRunning == false {
      runProvider()
    }
    
    if let location = location {
      _location = location
    }
    
    // call all listners
    eventListners(location: _location)
  }
  
  private func eventListners(location: CLLocationCoordinate2D) {
    listners.forEach({ $0.locationProvider(provider: self, locationDidChanged: location) })
  }
}

extension LocationProvider: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      return
    }
    
    _location = location.coordinate
    eventListners(location: _location)
  }
}
