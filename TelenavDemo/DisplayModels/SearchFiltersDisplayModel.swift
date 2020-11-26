//
//  SearchOptionFilters.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import Foundation
import TelenavEntitySDK

protocol FiltersItem {
    var itemType: FiltersItemType { get }
    var isSelected: Bool { get set }
}

enum FiltersItemType {

    case categoryRow
    case brandRow
    case evFilterRow
    case geoFilterRow
}

enum FiltersSectionType: String {
    case categorySection = "Select category"
    case brandSection = "Select Brand"
    case evFiltersSection = "Select EV Filters"
    case geoFiltersSection = "Select geo filter"
}

class FiltersSectionObject {
    var sectionType: FiltersSectionType
    var content: [FiltersItem]
    
    init(sectionType: FiltersSectionType, content: [FiltersItem]) {
        self.sectionType = sectionType
        self.content = content
    }
}

enum EVFilterItemType {
    case chargerBrands
    case connectorTypes
    case powerFeeds
}

protocol EVFilterItem {
    var evFilterType: EVFilterItemType { get }
    var isSelected: Bool { get set }
}

class EVFilter: FiltersItem {
  
    var itemType: FiltersItemType {
        return .evFilterRow
    }
    
    var isSelected: Bool {
        get {
            return false
        } set { }
    }
    
    var evFilterTitle: String
    var evFilterContent: [EVFilterItem]
    
    init(evFilterTitle: String, evFilterContent: [EVFilterItem]) {
        self.evFilterTitle = evFilterTitle
        self.evFilterContent = evFilterContent
    }
}

enum ChargerBrand: String, EVFilterItem, CaseIterable {
    
    var isSelected: Bool {
        get {
            return false
        } set {
            
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .chargerBrands
    }
    
    case chargerPoint = "Chargepoint"
    
    public static var allCases: [ChargerBrand] {
        return [.chargerPoint]
    }
}

enum SupportedConnectorTypes: String, EVFilterItem, CaseIterable {
    
    var isSelected: Bool {
        get {
            return false
        } set {
            
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .connectorTypes
    }
    
    case J1772 = "30001"
    case SAECombo = "30002"
    case CHAdeMO = "30003"
    case Type2 = "30004"
    case Type3 = "30005"
    case Tesla = "30006"
    case NEMA = "30007"
    case NEMA1450 = "30008"
    case PlugTypeF = "30009"

    var fullName: String {
        switch self {
        case .J1772:
            return "J1772"
        case .SAECombo:
            return "SAE Combo"
        case .CHAdeMO:
            return "CHAdeMO"
        case .Type2:
            return "Type 2"
        case .Type3:
            return "Type 3"
        case .Tesla:
            return "Tesla"
        case .NEMA:
            return "NEMA"
        case .NEMA1450:
            return "NEMA 14-50"
        case .PlugTypeF:
            return "Plug Type F"
        }
    }
    
    public static var allCases: [SupportedConnectorTypes] {
        return [.J1772, .CHAdeMO, .NEMA, .NEMA1450, .PlugTypeF, .SAECombo, .Tesla, .Type2, .Type3]
    }
}

enum PowerFeedLevels: Int, EVFilterItem, CaseIterable {
  
    var isSelected: Bool {
        get {
            return false
        } set {
            
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .powerFeeds
    }
    
    case one = 1
    case two = 2
    case five = 5
    
    var levelName: String {
        switch self {
        case .one:
            return "Level 1"
        case .two:
            return "Level 2"
        case .five:
            return "DC Fast"
        }
    }
    
    public static var allCases: [PowerFeedLevels] {
        return [.one, .two, .five]
    }
}

extension TelenavCategoryDisplayModel: FiltersItem {
    
    var isSelected: Bool {
        get {
            return false
        }
        set { }
    }
    
    var itemType: FiltersItemType {
        return .categoryRow
    }
}

extension TNEntityGeoFilterType: FiltersItem, CaseIterable {
  
    var isSelected: Bool {
        get {
            return false
        }
        set { }
    }

    var itemType: FiltersItemType {
        return .geoFilterRow
    }
    
    public static var allCases: [TNEntityGeoFilterType] {
        return [.bbox, .corridor, .poligon, .radius]
    }
}

