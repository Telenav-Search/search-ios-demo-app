//
//  SearchOptionFilters.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import Foundation
import TelenavEntitySDK

@objc protocol SelectableFilterItem {
    var isSelected: Bool { get set }
}

extension TNEntityBBoxGeoFilter: SelectableFilterItem {
    var isSelected: Bool {
        get { return true }
        set { }
    }
}

protocol FiltersItem: SelectableFilterItem {
    var itemType: FiltersItemType { get }
}

protocol EVFilterItem: SelectableFilterItem {
    var evFilterType: EVFilterItemType { get }
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

enum EVFilterItemType {
    case chargerBrands
    case connectorTypes
    case powerFeeds
}

class ChargerBrand: EVFilterItem {
    
    var selected: Bool = false
    
    var isSelected: Bool {
        get {
            return selected
        } set {
            selected = newValue
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .chargerBrands
    }
    
    var chargerBrandType: ChargerBrandType
    
    init(chargerBrandType: ChargerBrandType) {
        self.chargerBrandType = chargerBrandType
    }
}

enum ChargerBrandType: String, CaseIterable {
    
    case chargerPoint = "99100001"
    case blink = "99100002"
    case evgo = "99100003"
    case electrifyAmerica = "99100010"

    var fullName: String {
        switch self {
        case .blink:
            return "Blink"
        case .evgo:
            return "eVgo"
        case .chargerPoint:
            return "Chargepoint"
        case .electrifyAmerica:
            return "ElectrifyAmerica"
        }
    }
    
    public static var allCases: [ChargerBrandType] {
        return [.chargerPoint, .blink, .evgo, .electrifyAmerica]
    }
}

class Connector: EVFilterItem {
    
    var selected: Bool = false

    var isSelected: Bool {
        get {
            return selected
        } set {
            selected = newValue
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .connectorTypes
    }
    
    var connectorType: SupportedConnectorType
    
    init( connectorType: SupportedConnectorType) {
        self.connectorType = connectorType
    }
}

enum SupportedConnectorType: String, CaseIterable {
    
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
    
    public static var allCases: [SupportedConnectorType] {
        return [.CHAdeMO, .J1772, .NEMA, .NEMA1450, .PlugTypeF, .SAECombo, .Tesla, .Type2]
    }
}

class PowerFeedLevel: EVFilterItem {

    var selected: Bool = false
    
    var isSelected: Bool {
        get {
            return selected
        } set {
            selected = newValue
        }
    }
    
    var evFilterType: EVFilterItemType {
        return .powerFeeds
    }
    
    var level: PowerFeedLevelType
    
    init(level: PowerFeedLevelType) {
        self.level = level
    }
}

enum PowerFeedLevelType: Int, CaseIterable {
 
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
    
    static public var allCases: [PowerFeedLevelType] {
        return [.one, .two, .five]
    }
}


class FiltersSectionObject {
    var sectionType: FiltersSectionType
    var content: [FiltersItem]
    
    init(sectionType: FiltersSectionType, content: [FiltersItem]) {
        self.sectionType = sectionType
        self.content = content
    }
}

class EVFilter: FiltersItem {
  
    var itemType: FiltersItemType {
        return .evFilterRow
    }
    
    var isSelected: Bool {
        get { return false }
        set { }
    }
    
    var evFilterTitle: String
    var evFilterContent: [EVFilterItem]
    
    init(evFilterTitle: String, evFilterContent: [EVFilterItem]) {
        self.evFilterTitle = evFilterTitle
        self.evFilterContent = evFilterContent
    }
}

extension TelenavCategoryDisplayModel: FiltersItem {
    
    var isSelected: Bool {
        get {
            return selected
        }
        set {
            selected = newValue
        }
    }
    
    var itemType: FiltersItemType {
        return .categoryRow
    }
}

class TNEntityGeoFilterTypeDisplayModel: FiltersItem {
    
    var itemType: FiltersItemType {
        return .geoFilterRow
    }
    
    var selected: Bool = false
    
    var isSelected: Bool {
        get {
            return selected
        }
        set {
            selected = newValue
        }
    }
    
    var geoFilterType: TNEntityGeoFilterType
    
    init(geoFilterType: TNEntityGeoFilterType) {
        self.geoFilterType = geoFilterType
    }
}

extension TNEntityGeoFilterType: CaseIterable {
    
    public static var allCases: [TNEntityGeoFilterType] {
        return [.bbox, .corridor, .poligon, .radius]
    }
}

class BrandDisplayModel: FiltersItem {

    var itemType: FiltersItemType {
        return .brandRow
    }
    
    var isSelected: Bool {
        get {
            return selected
        }
        set {
            selected = newValue
        }
    }
    
    var brand: TNEntityBrand
    
    var selected: Bool = false
    
    init(brand: TNEntityBrand, selected: Bool = false) {
        self.brand = brand
        self.selected = selected
    }
}
