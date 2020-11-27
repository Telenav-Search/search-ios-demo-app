//
//  FiltersViewController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit
import TelenavEntitySDK
import CoreLocation

protocol FiltersViewControllerDelegate: class {
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem])
}

class FiltersViewController: UIViewController {

    @IBOutlet weak var filtersTableView: UITableView! {
        didSet {
            filtersTableView.delegate = self
            filtersTableView.dataSource = self
        }
    }
    
    weak var delegate: FiltersViewControllerDelegate?
    
    private var currentLocation = CLLocationCoordinate2D()
    private var content = [FiltersSectionObject]()
    private var categories = [TelenavCategoryDisplayModel]()
    
    func fillLocation(_ location: CLLocationCoordinate2D) {
        self.currentLocation = location
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        TNEntityCore.getCategories { (categories, err) in
            
            guard let categories = categories else {
                return
            }

            let cats = FakeCategoriesGenerator().mappedCats(categories)
            self.categories = cats
            
            if let catSectionIdx = self.content.firstIndex(where: { (sec) -> Bool in
                sec.sectionType == .categorySection
            }) {
                self.content[catSectionIdx].content = self.categories
                self.filtersTableView.reloadSections(IndexSet(integer: catSectionIdx), with: .fade)
            }
        }
        
        self.createInitialContent()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        var selectedFilters = [SelectableFilterItem]()
        
        for sec in content {
            for filter in sec.content {
                if filter.isSelected {
                    selectedFilters.append(filter)
                } else if filter.itemType == .evFilterRow {
                    let evFilter = (filter as! EVFilter)
                    for subFilter in evFilter.evFilterContent {
                        if subFilter.isSelected {
                            selectedFilters.append(subFilter)
                        }
                    }
                }
            }
        }
        
        delegate?.updateSelectedFilters(selectedFilters: selectedFilters)
    }
    
    func createInitialContent() {
        
        let categoriesSection = FiltersSectionObject(sectionType: .categorySection, content: [])
        
        var chargerBrands = [ChargerBrand]()
        
        for brand in ChargerBrandType.allCases {
            chargerBrands.append(ChargerBrand(chargerBrandType: brand))
        }
        
        let chargerBrandFilter = EVFilter(evFilterTitle: "Charger brands", evFilterContent: chargerBrands)
        
        var connectors = [Connector]()
        
        for connectorType in SupportedConnectorType.allCases {
            connectors.append(Connector(connectorType: connectorType))
        }
        
        let connectorTypes = EVFilter(evFilterTitle: "Connector types", evFilterContent: connectors)
        
        var feedLevels = [PowerFeedLevel]()
        
        for level in PowerFeedLevelType.allCases {
            feedLevels.append(PowerFeedLevel(level: level))
        }
        
        let powerFeedLevels = EVFilter(evFilterTitle: "Power feed levels", evFilterContent: feedLevels)
        
        let evFilterSection = FiltersSectionObject(sectionType: .evFiltersSection, content: [chargerBrandFilter, connectorTypes, powerFeedLevels])
        
        var geoFilters = [TNEntityGeoFilterTypeDisplayModel]()
        
        for filter in TNEntityGeoFilterType.allCases {
            geoFilters.append(TNEntityGeoFilterTypeDisplayModel(geoFilterType: filter))
        }
        
        
        let geoFilterSection = FiltersSectionObject(sectionType: .geoFiltersSection, content: geoFilters)
        
        self.content = [categoriesSection, evFilterSection, geoFilterSection]
    }
}

extension FiltersViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return content.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content[section].content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = content[indexPath.section].content[indexPath.row]
        
        switch item.itemType {
        case .categoryRow:
            guard let cell: CategoryFilterCell = tableView.dequeueReusableCell(withIdentifier: "CategoryFilterCell") as? CategoryFilterCell else {
                return UITableViewCell()
            }
            
            cell.fillCategory(item as! TelenavCategoryDisplayModel)
            return cell
            
        case .brandRow:
            guard let cell: BrandFilterCell = tableView.dequeueReusableCell(withIdentifier: "BrandFilterCell") as? BrandFilterCell else {
                return UITableViewCell()
            }
                        
            return cell
            
        case .evFilterRow:
            guard let cell: EVFilterCell = tableView.dequeueReusableCell(withIdentifier: "EVFilterCell") as? EVFilterCell else {
                return UITableViewCell()
            }
                   
            cell.fillEVFilters(item as! EVFilter)
            
            return cell
            
        case .geoFilterRow:
            guard let cell: GeoFilterCell = tableView.dequeueReusableCell(withIdentifier: "GeoFilterCell") as? GeoFilterCell else {
                return UITableViewCell()
            }
              
            cell.fillItem(item as! TNEntityGeoFilterTypeDisplayModel)
            return cell
        }
    }
    
}

extension FiltersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let item = content[indexPath.section].content[indexPath.row]
        
        switch item.itemType {
        case .evFilterRow:
            return UITableView.automaticDimension
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return content[section].sectionType.rawValue
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
 
        var item = content[indexPath.section].content[indexPath.row]
        
        item.isSelected.toggle()
            
        switch item.itemType {
        case .categoryRow:
            
            let categoryItem = item as! TelenavCategoryDisplayModel
            
            if categoryItem.isSelected {
                
                guard let catId = categoryItem.category.id  else {
                    return
                }
                
                let discoverBrandParams = TNEntityDiscoverBrandParams(categoryId: catId, location: TNEntityGeoPoint(lat: self.currentLocation.latitude, lon: self.currentLocation.longitude))
                
                TNEntityCore.getDiscoverBrands(params: discoverBrandParams) { (brands, err) in
                    
                    print(brands)
                }
                
            } else {

            }
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var item = content[indexPath.section].content[indexPath.row]
        
        item.isSelected.toggle()
    }
}
