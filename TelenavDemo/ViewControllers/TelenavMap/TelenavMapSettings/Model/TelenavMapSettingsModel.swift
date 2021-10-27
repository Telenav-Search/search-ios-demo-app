//
//  TelenavMapSettingsModel.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import Foundation
import CoreLocation
import VividDriveSessionSDK

struct TelenavMapSettingsModel {
    // gestures
    var gestureType = VNGestureType.auto
    
    // features
    var isTrafficOn = false
    var isLandmarksOn = false
    var isBuildingsOn = false
    var isTerrainOn = false
    var isGlobeOn = false
    var isCompassOn = false
    var isScaleBarOn = false
    var endPoint: CLLocation?
    var isEndPointOn = false
    
    // layout
    var verticalOffset = Double(0)
    var horizontalOffset = Double(0)
    
    // map data
    var isListenMapViewDataOn = false
}
