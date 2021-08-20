//
//  RouteSettings.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 26.07.2021.
//

import VividMapSDK

struct RouteSettings
{

    var region = "NA"
    
    var routeCount: Int32 = 1
    var heading: Int32 = -1
    
    /** Speed in accrodance with current locale
            if metric -> km/h
            if not -> mph
    */
    var speed: Int32 = 0
    var speedInMps: Int32 {
        get {
            if RouteSettings.isMetricSystem {
                return Int32(lround(Double(speed)/3.6))
            } else {
                return Int32(lround(Double(speed)/2.23694))
            }
        }
    }
    
    static var isMetricSystem: Bool {
        let locale = NSLocale.current
        return locale.usesMetricSystem
    }
    
    var speedDescriptionLabel: String {
        let format = "Set the speed of the vehicle in %@. Default is 0"
        if RouteSettings.isMetricSystem {
            return String(format: format, "km/h")
        } else {
            return String(format: format, "Mph")
        }
    }
    
    var routeStyle: VNRouteStyle = .fastest
    var contentLevel: VNContentLevel = .full
    var startDate = Date()
    
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
    
    func preference(atIndex index: Int) -> Bool {
        switch index {
        case 0:
            return preferences.avoidHovLanes
        case 1:
            return preferences.avoidHighways
        case 2:
            return preferences.avoidTollRoads
        case 3:
            return preferences.avoidFerries
        case 4:
            return preferences.avoidCarTrains
        case 5:
            return preferences.avoidUnpavedRoads
        case 6:
            return preferences.avoidTunnels
        case 7:
            return preferences.useTraffic
        case 8:
            return preferences.avoidSharpTurns
        case 9:
            return preferences.avoidCountryBorders
        case 10:
            return preferences.avoidPermitRequiredRoads
        case 11:
            return preferences.avoidSeasonalRestrictions
        default:
            return false
        }
    }
    
    func set(preference: Bool, atIndex index: UInt) {
        switch index {
        case 0:
            preferences.avoidHovLanes = preference
        case 1:
            preferences.avoidHighways = preference
        case 2:
            preferences.avoidTollRoads = preference
        case 3:
            preferences.avoidFerries = preference
        case 4:
            preferences.avoidCarTrains = preference
        case 5:
            preferences.avoidUnpavedRoads = preference
        case 6:
            preferences.avoidTunnels = preference
        case 7:
            preferences.useTraffic = preference
        case 8:
            preferences.avoidSharpTurns = preference
        case 9:
            preferences.avoidCountryBorders = preference
        case 10:
            preferences.avoidPermitRequiredRoads = preference
        case 11:
            preferences.avoidSeasonalRestrictions = preference
        default:
            return
        }
    }
    
    static func label(forPreferenceAtIndex index: Int) -> String {
        if index >= 0, index < preferencesLabels.count {
            return preferencesLabels[index]
        }
        return ""
    }
    
    static let preferencesLabels = ["Avoid HOV Lanes",
                                    "Avoid Highways",
                                    "Avoid Toll Roads",
                                    "Avoid Ferries",
                                    "Avoid Car Trains",
                                    "Avoid Unpaved Roads",
                                    "Avoid Tunnels",
                                    "Use Traffic",
                                    "Avoid Sharp Turns",
                                    "Avoid Country Borders",
                                    "Avoid Permit Required Roads",
                                    "Avoid Seasonal Restrictions"]
    
    static func distanceLabel(format: String,
                              lengthInMeters length: Double) -> String {
        let kilometers = length/1000
        if RouteSettings.isMetricSystem {
            return String(format: format, kilometers, "km")
        } else {
            let miles = kilometers*0.621371
            return String(format: format, miles, "mi")
        }
    }
}
