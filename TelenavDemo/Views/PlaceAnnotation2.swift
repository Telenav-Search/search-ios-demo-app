//
//  PlaceAnnotation2.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 15.10.2021.
//

import Foundation
import VividDriveSessionSDK

class PlaceAnnotation2 {
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
