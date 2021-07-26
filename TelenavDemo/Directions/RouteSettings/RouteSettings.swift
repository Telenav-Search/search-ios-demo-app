//
//  RouteSettings.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 26.07.2021.
//

import VividNavigationSDK

struct RouteSettings
{
    var region = "NA"
    
    var routeCount: Int32 = 1
    var heading: Int32 = -1
    var speed: Int32 = 0
    
    var routeStyle: VNRouteStyle = .fastest
    var contentLevel: VNContentLevel = .full
    
    static func label(forRouteStyle routeStyle: VNRouteStyle) -> String {
        switch routeStyle {
        case .fastest:
            return "Fastest"
        case .shortest:
            return "Shortest"
        case .easy:
            return "Easy"
        case .eco:
            return "ECO"
        default:
            return "Usual"
        }
    }
    
    static func label(forContentLevel level: VNContentLevel) -> String {
        switch level {
        case .eta:
            return "ETA"
        case .overview:
            return "Overview"
        default:
            return "Full"
        }
    }
    
    var preferences = VNRoutePreferences()
}
