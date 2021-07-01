//
//  FiltersViewController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit
import TelenavEntitySDK
import CoreLocation

@objc protocol FiltersViewControllerDelegate: AnyObject {
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem])
}

class FiltersViewController: UIViewController {

    @IBOutlet weak var filtersTableView: UITableView! {
        didSet {
            filtersTableView.delegate = self
            filtersTableView.dataSource = self
        }
    }
    
    @IBOutlet weak var delegate: FiltersViewControllerDelegate?
    
    private var currentLocation: CLLocationCoordinate2D?
    private var content = [FiltersSectionObject]()
    private var categories = [TelenavCategoryDisplayModel]()
    
    func fillLocation(_ location: CLLocationCoordinate2D) {
        self.currentLocation = location
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        TNEntityClient.getCategories { (categories, err) in
            
            guard let categories = categories?.results else {
                return
            }

            let cats = StaticCategoriesGenerator().displayModelsFor(categories: categories)
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
                
        self.content = [evFilterSection]
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
            
            cell.expandedStateChanged = { [weak self] category in
                
                guard let self = self else {
                    return
                }
                
                self.insertSubcategoriesOfCategory(category)
            }
            
            return cell
            
        case .brandRow:
            guard let cell: BrandFilterCell = tableView.dequeueReusableCell(withIdentifier: "BrandFilterCell") as? BrandFilterCell else {
                return UITableViewCell()
            }
                        
            cell.fillBrand(item as! BrandDisplayModel)
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
    
    private func insertSubcategoriesOfCategory(_ category: TelenavCategoryDisplayModel) {
        
        guard let categoriesSection = content.first(where: { (sec) -> Bool in
            sec.sectionType == .categorySection
        }) else {
            return
        }
        
        var categories = categoriesSection.content as! [TelenavCategoryDisplayModel]
        
        guard let idxOfSelectedCat = categories.firstIndex(where: { (cat) -> Bool in
            cat.category.id == category.category.id
        }) else {
            return
        }
        
        guard let subcats = category.category.childNodes else {
            return
        }
        
        if category.isExpanded == true {
            
            let idxPathsToRemove = findNodesForCollapsing(for: category)
        
            guard let firstIdx = idxPathsToRemove.first?.row, let lastIdx =  idxPathsToRemove.last?.row else {
                return
            }
            
            categories.removeSubrange(firstIdx...lastIdx)
            
            content[0].content = categories
            
            filtersTableView.deleteRows(at: idxPathsToRemove, with: .fade)
            
        } else {
            
            let indexToInsert = idxOfSelectedCat + 1
            
            let mappedSubcats = subcats.map { (cat) -> TelenavCategoryDisplayModel in
                
                return TelenavCategoryDisplayModel(category: cat, catLevel: category.catLevel + 1)
            }
            
            categories.insert(contentsOf: mappedSubcats, at: indexToInsert)
            
            var idxPathsToInsert = [IndexPath]()
            
            for i in indexToInsert...(idxOfSelectedCat + subcats.count) {
                idxPathsToInsert.append(IndexPath(row: i, section: 0))
            }
            
            content[0].content = categories
            
            filtersTableView.insertRows(at: idxPathsToInsert, with: .fade)
        }
    
        category.isExpanded.toggle()
        filtersTableView.reloadRows(at: [IndexPath(row: idxOfSelectedCat, section: 0)], with: .fade)
    }
    
    func findNodesForCollapsing(for cat: TelenavCategoryDisplayModel) -> [IndexPath] {
        
        let selectedCategoryLevel = cat.catLevel
        var idxPaths = [IndexPath]()
        
        guard let categoriesSection = content.first(where: { (sec) -> Bool in
            sec.sectionType == .categorySection
        }) else {
            return []
        }
        
        let categories = categoriesSection.content as! [TelenavCategoryDisplayModel]
        
        guard let selectedCategoryIdx = categories.firstIndex(where: { (categ) -> Bool in
            categ.category.id == cat.category.id
        }) else {
            return []
        }
        
        for idx in (selectedCategoryIdx...categories.count - 1) {
            
            let category = categories[idx]
            
            if category.catLevel == selectedCategoryLevel && category.category.id != cat.category.id {
                break
            }
            
            if (category.isExpanded && category.catLevel >= selectedCategoryLevel) {
                
                let indexPath = IndexPath(row: idx + 1, section: 0)
                idxPaths.append(indexPath)
            }
            
            if (category.catLevel > selectedCategoryLevel) {
                let indexPath = IndexPath(row: idx, section: 0)
                idxPaths.append(indexPath)
            }
        }
        
        return idxPaths
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
 
        let item = content[indexPath.section].content[indexPath.row]
        
        item.isSelected.toggle()
            
        switch item.itemType {
        case .categoryRow:
            
            let categoryItem = item as! TelenavCategoryDisplayModel
            
            if categoryItem.isSelected {
                
                guard categoryItem.category.id != nil  else {
                    return
                }
                
                let discoverBrandParams = TNEntityDiscoverBrandParamsBuilder()
                    .categoryId("241")
                    .location(TNEntityGeoPoint(lat: self.currentLocation?.latitude ?? 0, lon: self.currentLocation?.longitude ?? 0))
                    .build()
                    
                
                TNEntityClient.getDiscoverBrands(params: discoverBrandParams) { (brands, err) in
                    
                    var convBrands = [BrandDisplayModel]()
                    
                    for brand in brands?.results ?? [] {
                        let br = BrandDisplayModel(brand: brand)
                        convBrands.append(br)
                    }
                    
                    if let brandSection = self.content.first(where: { (sec) -> Bool in
                        sec.sectionType == .brandSection
                    }) {
                        for brand in convBrands {
                            if brandSection.content.contains(where: { (item) -> Bool in
                                (item as! BrandDisplayModel).brand.brandId == brand.brand.brandId
                            }) == false {
                                brandSection.content.append(brand)
                            }
                        }
                        
                        self.filtersTableView.reloadSections(IndexSet(integer: 1), with: .fade)
                                                
                    } else {
                        let brandSection = FiltersSectionObject(sectionType: .brandSection, content: convBrands)
                        self.content.insert(brandSection, at: 1)
                        
                        self.filtersTableView.insertSections(IndexSet(integer: 1), with: .fade)
                    }
                }
                
            } else {

            }
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = content[indexPath.section].content[indexPath.row]
        
        item.isSelected.toggle()
    }
}
