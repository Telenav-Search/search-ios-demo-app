//
//  RouteCreationAnnotation.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 24.06.2021.
//

import Foundation
import MapKit

class RouteCreationAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
