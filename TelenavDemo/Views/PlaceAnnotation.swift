//
//  PlaceAnnotation.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import Foundation
import MapKit

class PlaceAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var placeId: String
    var title: String?
    var number: Int = 1
    var categories: [String]?
    
    init(coordinate: CLLocationCoordinate2D, id: String, categories: [String]?) {
        self.categories = categories
        self.coordinate = coordinate
        self.placeId    = id
    }
}
