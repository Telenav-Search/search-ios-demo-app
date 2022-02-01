//
//  MapViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 19.10.2020.
//

import UIKit
import TelenavEntitySDK
import Alamofire
import VividDriveSessionSDK

class MapViewController: UIViewController, CatalogViewControllerDelegate, CLLocationManagerDelegate {
    lazy var mapView: VNMapView = {
        let mapView = VNMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.accessibilityIdentifier = "mapViewControllerMapViewVNMapView"
        return mapView
    }()
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    @IBOutlet var detailsViewAnimator: PanViewAnimator!
    @IBOutlet var searchResultViewAnimator: SearchPanAnimator!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var redoSearchButton: UIButton!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var searchQueryLabel: UILabel!
    @IBOutlet weak var detailsView: DetailsView!
    @IBOutlet weak var detailsViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var predictionsView: PredictionsView! {
        didSet {
            self.updatePredictionsView()
        }
    }
    
    var currentDetailID: String = ""
    let staticCategoriesService = StaticCategoriesGenerator()
    private var throttler = Throttler(throttlingInterval: 0.7, maxInterval: 0, qosClass: .userInitiated)
    var catalogVisible = true {
        didSet {
            catalogVC.view.isHidden = !catalogVisible
        }
    }
    var showingSubCatalog = false
    var showingMap = false
    var showingDetail = false
    var heightAnchor: NSLayoutConstraint!
    
    var searchVisible = false {
        didSet {
            searchResultsVC.view.isHidden = !searchVisible
            searchTextField.isHidden = searchVisible
            searchQueryLabel.isHidden = !searchVisible
            backButton.isHidden = !searchVisible
            predictionsView.isHidden = searchVisible
            redoSearchButton.isHidden = !searchVisible
            
            for sbv in searchResultsVC.view.subviews {
                sbv.isHidden = !searchVisible
            }
            
            heightAnchor.constant = setupSearchHeight()
            searchResultViewAnimator.middleHeight = setupSearchHeight()
            searchResultViewAnimator.bottomConstraint.constant = searchVisible ? (tabBarController?.tabBar.frame.size.height ?? CGFloat(0)) : -setupSearchHeight()
            searchResultViewAnimator.bottomMin = 30 + tabBarController!.tabBar.bounds.height - setupSearchHeight()
            mapContainerView.layoutIfNeeded()
            view.layoutIfNeeded()
        }
    }

    private var searchPaginationContext: String?
    private var searchContent = [TNEntity]()
    private var currentAnnotations = [PlaceAnnotation2]()
    private var staticCategories = [TNEntityStaticCategory]()
    
    private var annotationsSetupCallback: (() -> Void)?
    private let locationProvider = LocationProvider.shared
    private var currentLocation = LocationProvider.shared.location
    private var searchResultDisplaying: Bool = false
    private var searchQuery: String?
    private var hasMoreSearchResults: Bool = false
    private var selectedFilters = [SelectableFilterItem]()
    private let searchHeight: CGFloat = 400
    
    lazy var catalogVC: CatalogViewController = {
        let vc = storyboard!.instantiateViewController(withIdentifier: "CatalogViewController") as! CatalogViewController
        vc.delegate = self
        return vc
    }()
    
    lazy var searchResultsVC: SearchResultViewController = {
        let vc = storyboard!.instantiateViewController(withIdentifier: "SearchResultViewController") as! SearchResultViewController
        vc.delegate = self
        return vc
    }()
    
    internal var createRouteActionSheet: UIAlertController?
    @IBOutlet weak var routesScrollView: RoutesScrollView!
    @IBOutlet weak var routeScrollHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var routeSettingsButton: UIButton!
    var routeSettings = RouteSettings()
    
    // route
    var fromLocation: VNGeoPoint?
    var toLocation: VNGeoPoint?
    var wayLocations = [VNGeoPoint]()
    var fromAnnotation: VNAnnotation?
    var toAnnotation: VNAnnotation?
    var wayAnnotations = [VNAnnotation]()
    var routeModels = [VNMapRouteModel]()
    var entityAnnotations = [VNAnnotation]()
    var entitiesWithCoordinates = [TNEntity: CLLocationCoordinate2D]()

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle == .dark {
            VNSDK.sharedInstance.dayNightMode = .dayMode
        } else {
            VNSDK.sharedInstance.dayNightMode = .nightMode
        }
    }
    
    func updatePredictionsView() {
        predictionsView.backgroundColor = .clear
        predictionsView.layer.cornerRadius = 9
        predictionsView.layer.masksToBounds = true
        
        predictionsView.selectedWordCallback = { [weak self] word in
            
            guard let self = self else {
                return
            }
            
            guard let predictionWord = word.predictWord else {
                return
            }
            
            let predictionWithWhitespace = predictionWord + " "
            var searchStr = predictionWithWhitespace

            if var wordsArray = self.searchTextField.text?.components(separatedBy: CharacterSet.whitespaces) {
                
                if wordsArray.last?.isEmpty == true {
                    self.searchTextField.text?.append(predictionWithWhitespace)
                } else {
                    if let lastWord = wordsArray.last, let lastWordIdx = wordsArray.lastIndex(of: lastWord) {
                        wordsArray[lastWordIdx] = predictionWithWhitespace
                    }
                    
                    searchStr = wordsArray.joined(separator: " ")
                    self.searchTextField.text = searchStr
                    
                }
            
                self.getSuggestions(text: wordsArray.joined(separator: " ")) { (result) in
                    
                    self.catalogVC.fillSuggestions(result)
                }
            }
            self.hidePredictionsView()
            self.getPredictions(on: self.searchTextField.text ?? "")
        }
    }
    
    // MARK: - View management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSDK()
        
        staticCategoriesService.getStaticCategories { (staticCats, err) in
            
            guard let categories = staticCats else {
                return
            }
            
            self.staticCategories = categories
            
            self.catalogVC.fillStaticCategories(categories)
        }
        
        addChildView()
        addSearchAsChild()
        detailsView.superview?.bringSubviewToFront(detailsView)
        toggleDetailView(visible: false)
        
        let panGesture2 = UIPanGestureRecognizer(target: self.searchResultViewAnimator, action: #selector(PanViewAnimator.didDragMainView(_:)))
        searchResultsVC.view.addGestureRecognizer(panGesture2)
        
        let swipe1 = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetailLeft))
        swipe1.direction = .left
        detailsView.addGestureRecognizer(swipe1)
     
        let swipe2 = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetailRight))
        swipe2.direction = .right
        detailsView.addGestureRecognizer(swipe2)
        
        redoSearchButton.layer.cornerRadius = 4
        redoSearchButton.layer.borderWidth = 1
        redoSearchButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        if let viewControllers = tabBarController?.viewControllers {
            for navVC in viewControllers {
                if let navVC = navVC as? UINavigationController,
                   let coordVC = navVC.topViewController as? CoordinateSettingsController {
                    let _ = coordVC.view
                    coordVC.delegate = self
                }
            }
        }
        addLongTapGestureRecognizer()
        handleDetailsViewRouteButtons()
        routeSettingsButton.layer.borderColor = UIColor.systemBlue.cgColor
      
        currentLocation = LocationProvider.shared.location
        locationProvider.addListner(listner: self)
        moveMapCameraTo(to: currentLocation)
        setUserPushPin(userLocation: currentLocation)
        
        setupAccessibilityIdentifiers()
    }
    
    func setupAccessibilityIdentifiers() {
        backButton.accessibilityIdentifier = "mapViewControllerBackButton"
        redoSearchButton.accessibilityIdentifier = "mapViewControllerRedoSearchButton"
        searchQueryLabel.accessibilityIdentifier = "mapViewControllerSearchQueryLabel"
        predictionsView.collectionView.accessibilityIdentifier = "mapViewControllerPredictionWordsCollectionView"
    }
  
    deinit {
        locationProvider.removeListner(listner: self)
    }
    
    func findAnnIndex(id: String) -> Int {
        for (idx, ann) in currentAnnotations.enumerated() {
            if ann.placeId == id {
                return idx
            }
        }
        return NSNotFound
    }
    
    @objc func swipeDetailRight() {
        var newIdx = findAnnIndex(id: currentDetailID) - 1
        if newIdx == NSNotFound {
            return
        }
        if newIdx < 0 {
            newIdx = 0
        }
        let ann = currentAnnotations[newIdx]
        // TODO:
        // mapView.selectAnnotation(ann, animated: true)
        goToDetails(placeAnnotation: ann)
    }
    
    @objc func swipeDetailLeft() {
        var newIdx = findAnnIndex(id: currentDetailID) + 1
        if newIdx == NSNotFound {
            return
        }
        if newIdx >= currentAnnotations.count {
            newIdx = currentAnnotations.count - 1
        }
        let ann = currentAnnotations[newIdx]
        // TODO:
        // mapView.selectAnnotation(ann, animated: true)
        goToDetails(placeAnnotation: ann)
    }

    func addChildView() {
        mapView.preferredFPS = 30
        mapContainerView.insertSubview(mapView, at: 0)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor)
        ])
        
        addChild(catalogVC)
        mapContainerView.addSubview(catalogVC.view)
        mapContainerView.bringSubviewToFront(catalogVC.view)
        
        catalogVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        catalogVC.view.topAnchor.constraint(equalTo: mapContainerView.topAnchor).isActive = true
        catalogVC.view.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor).isActive = true
        catalogVC.view.leftAnchor.constraint(equalTo: mapContainerView.leftAnchor).isActive = true
        catalogVC.view.rightAnchor.constraint(equalTo: mapContainerView.rightAnchor).isActive = true
    }
    
    func addSearchAsChild() {
        addChild(searchResultsVC)
        mapContainerView.addSubview(searchResultsVC.view)
        mapContainerView.bringSubviewToFront(searchResultsVC.view)
        
        searchResultsVC.view.translatesAutoresizingMaskIntoConstraints = false
        setupSearchConstraints()
        
        searchResultViewAnimator.view = searchResultsVC.view
        searchResultsVC.view.isHidden = true
    }
    
    private func setupSearchConstraints() {
        
        heightAnchor = searchResultsVC.view.heightAnchor.constraint(equalToConstant: setupSearchHeight())
        heightAnchor.isActive = true
        
        let bottomVal = -searchHeight + tabBarController!.tabBar.frame.size.height
        let bottom = mapContainerView.bottomAnchor.constraint(equalTo: searchResultsVC.view.bottomAnchor,
                                                                  constant: bottomVal)
        bottom.isActive = true
            
        searchResultsVC.view.leftAnchor.constraint(equalTo: mapContainerView.leftAnchor).isActive = true
        searchResultsVC.view.rightAnchor.constraint(equalTo: mapContainerView.rightAnchor).isActive = true
        
        searchResultViewAnimator.bottomConstraint = bottom
        searchResultViewAnimator.heightConstraint = heightAnchor
        searchResultViewAnimator.middleHeight = heightAnchor.constant
        searchResultViewAnimator.maxHeight = self.view.bounds.size.height - self.tabBarController!.tabBar.bounds.height

        let constr = redoSearchButton.bottomAnchor.constraint(equalTo: searchResultsVC.view.topAnchor, constant: -10)
        constr.priority = UILayoutPriority.defaultHigh
        constr.isActive = true
    }
    
    private func setupSearchHeight() -> CGFloat {
        return searchVisible ? searchHeight : 0
    }

    private func toggleDetailView(visible: Bool) {
        heightAnchor.constant = visible ? 0 : searchHeight
        searchResultViewAnimator.middleHeight = heightAnchor.constant
        
        if visible {
            redoSearchButton.isHidden = true
        } else if showingMap {
            redoSearchButton.isHidden = false
        }
        detailsViewBottomConstraint?.constant = visible ? 0 : -300
        tabBarController?.tabBar.isHidden = visible
        
        if visible {
            view.bringSubviewToFront(detailsView)
        } else {
            view.sendSubviewToBack(detailsView)
        }
        UIView.animate(withDuration: 0.3) {

            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - SDK Setup
    
    private func setupSDK() {
        let settings = readSettingsFromConfig()
        if let settings = settings,
           let key = settings["apiKey"],
           let secret = settings["apiSecret"],
           let endpoint = settings["cloudEndPoint"] {
            do {
                let sdkOptions = try TNEntitySDKOptionsBuilder()
                        .apiKey(key)
                        .apiSecret(secret)
                        .locale(Locale.current.languageCode)
                        .cloudEndPoint(endpoint)
                        .build()
                TNEntityClient.initialize(sdkOptions)
                } catch {
                    print("Incorrect SDK options")
                }
        }
        else {
            print("Can't read SDKConfig.plist")
        }
    }
    
    private func readSettingsFromConfig() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: "SDKConfig", ofType: "plist") else { return nil
        }
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String:String] else {
            return nil
        }
        return plist
    }
    
    // MARK: - Actions
    
    @IBAction func redoSearchButton(_ sender: Any) {
        let cameraController = mapView.cameraController()
        let scale = UIScreen.main.scale
        
        guard
            let topRight = cameraController.viewport(toWorld: VNViewPoint(x: Float(mapView.bounds.width * scale), y: 0)),
            let bottomLeft = cameraController.viewport(toWorld: VNViewPoint(x: 0, y: Float(mapView.bounds.height * scale))) else {
            return
        }

        let queryTitle = searchQueryLabel.text
        let filter = TNEntityBBoxGeoFilter()
        filter.bbox.bottomLeft = TNEntityGeoPoint(lat: bottomLeft.latitude, lon: bottomLeft.longitude)
        filter.bbox.topRight = TNEntityGeoPoint(lat: topRight.latitude, lon: topRight.longitude)
        
        startSearch(searchQuery: lastSearchQuery, filterItems: (lastFilterItems ?? []) + [filter])
        searchQueryLabel.text = queryTitle
    }
    
    @IBAction func didTapOnMap(_ sender: Any) {
        
        toggleDetailView(visible: false)
        searchTextField.resignFirstResponder()
    }
    
    @IBAction func didClickBack(_ sender: Any) {
        goBack()
    }

    // MARK: - Catalog Delegate
    
    func goToChildCategory(name: String) {
        searchTextField.resignFirstResponder()
        
        removeEntityAnnotations()
        
        self.backButton.isHidden = false
        
        startSearch(searchQuery: name)
    }
    
    func removeEntityAnnotations() {
        let annotationController = mapView.annotationsController()
        self.currentAnnotations = []
        
        annotationController.remove(entityAnnotations)
    }
    
    func addEntityAnnotations(annotations: [PlaceAnnotation2]) {
        let annotationController = mapView.annotationsController()
        
        var annotationArray = [VNAnnotation]()
        
        for (index, entity) in annotations.enumerated() {
            guard let annotation = makeAnnotation(by: entity, index: index) else {
                continue
            }
            annotationArray.append(annotation)
        }
        
        annotationController.add(annotationArray)
        entityAnnotations = annotationArray
    }
    
    private func makeAnnotation(by entity: PlaceAnnotation2, index: Int) -> VNAnnotation? {
        let latitude = entity.coordinate.latitude
        let longitude = entity.coordinate.longitude
        
        let annotationController = mapView.annotationsController()
        let annotaionsFactory = annotationController.factory()
        
        guard let entityAnnotationImage = makeEntityAnnotaionIcon(by: "\(index + 1)") else {
            return nil
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = annotaionsFactory.create(with: entityAnnotationImage, location: coordinate)
        annotation.style = .screenFlagNoCulling
        
        return annotation
    }
    
    private func makeEntityAnnotaionIcon(by text: String) -> UIImage? {
        let textColor = UIColor.black
        let textFont = UIFont.systemFont(ofSize: 24)
        guard let entityAnnotationImage = UIImage(named: "entity-annotation-icon") else {
            return nil
        }
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(entityAnnotationImage.size, false, scale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        
        let size = (text as NSString).size(withAttributes: textFontAttributes)
        let origin = CGPoint(
            x: entityAnnotationImage.size.width / 2 - size.width / 2,
            y: entityAnnotationImage.size.height / 2 - size.height / 2)
        
        let rect = CGRect(origin: origin, size: size)
        
        entityAnnotationImage.draw(in: CGRect(origin: CGPoint.zero, size: entityAnnotationImage.size))
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func didSelectSuggestion(entity: TNEntity, distance: String?) {
        searchVisible = true
        redoSearchButton.isHidden = true
        searchResultsVC.view.isHidden = true
        searchTextField.resignFirstResponder()
        
        removeEntityAnnotations()
        guard let annotation = annotationFromEntity(entity: entity) else {
            return
        }
        goToDetails(placeAnnotation: annotation, distance: distance) { (entity) in
            guard let _ = entity.id,
                  let name = entity.place?.name ?? entity.address?.formattedAddress
            else {
                return
            }

            self.searchQueryLabel.text = name

            guard let updatedAnnotation = self.annotationFromEntity(entity: entity) else {
                return
            }

            self.removeEntityAnnotations()
            self.currentAnnotations = [annotation]
            self.addEntityAnnotations(annotations: [annotation])
            
            let region = self.obtainRegionForAnnotationsArr([updatedAnnotation])
            self.mapView.cameraController().show(region)
            
            self.backButton.isHidden = false
            self.moveMapCameraTo(to: annotation.coordinate)
        }
    }
    
    func moveMapCameraTo(to coordinate: CLLocationCoordinate2D) {
        let point = VNGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let position = self.mapView.cameraController().position
        let cameraPosition = VNCameraPosition(bearing: position.bearing, tilt: position.tilt, zoomLevel: position.zoomLevel, location: point)
        self.mapView.cameraController().position = cameraPosition
    }
    
    func didSelectQuery(_ query: String) {
        searchTextField.resignFirstResponder()
        startSearch(searchQuery: query)
    }
    
    func didReturnToStaticCategories() {
        catalogVisible = true
        backButton.isHidden = true
        catalogVC.fillStaticCategories(self.staticCategories)
    }
    
    func didSelectCategoryItem(_ item: StaticCategoryCellItem) {
        
        searchTextField.resignFirstResponder()
        
        switch item.cellType {
        case .categoryItem:
            guard let model = item as? StaticCategoryDisplayModel else {
                return
            }
            self.searchByCategory(categoryModel: model)
        case .moreItem:
            backButton.isHidden = false
            TNEntityClient.getCategories { (categories, err) in

                guard let categories = categories?.results else {
                    return
                }

                let cats = self.staticCategoriesService.displayModelsFor(categories: categories)
                
                self.catalogVC.fillAllCategories(cats)
                self.catalogVisible = true
                self.showingSubCatalog = true
            }
        }
    }
    
    private var userPushPinAnnotation: VNAnnotation?
  
    private func setUserPushPin(userLocation: CLLocationCoordinate2D) {
      let annotationsController = mapView.annotationsController()
      
      if userPushPinAnnotation == nil {
        let userPushPinAnnotation = annotationsController.factory()
          .create(with: UIImage(named: "user-pushpin")!, location: userLocation)
        userPushPinAnnotation.style = .screenFlagNoCulling
        userPushPinAnnotation.priority = 1
        
        self.userPushPinAnnotation = userPushPinAnnotation
      }
      
      if let userPushPinAnnotation = self.userPushPinAnnotation {
        userPushPinAnnotation.location = userLocation
        annotationsController.add([userPushPinAnnotation])
      }
    }
    
    private func obtainRegionForAnnotationsArr(_ arr: [PlaceAnnotation2]) -> VNCameraRegion {
        let region = VNCameraRegion()
        arr.forEach {
            region.extend(toLatitude: $0.coordinate.latitude, andLongitude: $0.coordinate.longitude)
        }
        return region
    }
    
    private func goToDetails(placeAnnotation: PlaceAnnotation2, distance: String? = nil, completion: ((TNEntity) -> Void)? = nil) {
        
        var builder = TNEntityDetailParamsBuilder().ids([placeAnnotation.placeId]).detailOptions(TNEntityDetailOptions(detailLevel: .full, showAddressLines: true))
        
        if let categories = placeAnnotation.categories, categories.contains("612") || categories.contains("611") {
            builder = addFacetsForParking(builder: builder)
        }
        
        let params: TNEntityDetailParams
        do {
            try params = builder.build()
        } catch  {
            if let err = error as? TNEntityError {
                print(err.message ?? "")
            }
            return
        }
        
        self.moveMapCameraTo(to: placeAnnotation.coordinate)
        
        TNEntityClient.getEntityDetail(params: params) { [weak self] (entities, err) in
            
            guard let self = self else {
                return
            }
            
            guard let detail = entities?.results?.first else {
                return
            }

            self.currentDetailID = placeAnnotation.placeId
            if detail.distance == nil {
                if let distance = self.calculateDistanceForDetails(detail: detail) {
                    detail.distance = distance
                }
            }
            self.detailsView.fillEntity(detail,
                                        currentCoordinate: self.currentLocation ,
                                        distanceText: distance)
            self.toggleDetailView(visible: true)
            
            self.catalogVisible = false
            self.showingDetail = true
            
            completion?(detail)
        }
    }
    
    func calculateDistanceForDetails(detail: TNEntity) -> Double? {
        if let placeCoordinates = detail.type == .place ? detail.place?.address?.geoCoordinates : detail.address?.geoCoordinates,
           let placeLatitude = placeCoordinates.latitude,
           let placeLongitude = placeCoordinates.longitude {
            
            let myLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let placeLocation = CLLocation(latitude: placeLatitude, longitude: placeLongitude)
            let distanceInMeters = myLocation.distance(from: placeLocation)
            return distanceInMeters
        }
        return nil
    }
    
    // MARK: - Search
    
    var lastSearchQuery: String = ""
    var lastFilterItems: [SelectableFilterItem]?
    
    private func searchByCategory(categoryModel: StaticCategoryDisplayModel) {
        self.backButton.isHidden = false
        let filter = TelenavCategoryDisplayModel(category: TNEntityCategory(childNodes: nil, id: categoryModel.staticCategory.id, name: categoryModel.staticCategory.name),
                                                 catLevel: 0)
        
        var finalFilters: [SelectableFilterItem] = [filter]
        if filter.category.id == "771" {
            finalFilters = selectedFilters + [filter]
        }
        startSearch(searchQuery: "", filterItems: finalFilters)
        searchQueryLabel.text = categoryModel.staticCategory.name
    }
  
    private func startSearch(searchQuery: String, filterItems: [SelectableFilterItem]? = nil) {
        lastFilterItems = []
        
        if let filterItems = filterItems {
            lastFilterItems?.append(contentsOf: filterItems.filter({ $0 is TNEntityBBoxGeoFilter == false}))
        }
        lastSearchQuery = searchQuery
        
        resetSearch()
        searchQueryLabel.text = searchQuery
 
        self.searchQuery = searchQuery
        self.backButton.isHidden = true

        let searchFilter = filterFrom(filterItems: filterItems)
        let searchOptions = TNEntitySearchOptions(intent: .around, showAddressLines: false)
        
        let searchParams = TNEntitySearchParamsBuilder()
            .limit(20)
            .query(searchQuery)
            .location(TNEntityGeoPoint(lat: currentLocation.latitude,
                                       lon: currentLocation.longitude))
            .filters(searchFilter)
            .searchOptions(searchOptions)
            .build()
        
        TNEntityClient.search(params: searchParams) { (telenavSearch, err) in
            self.handleSearchResult(telenavSearch, isPaginated: false)
        }
    }
    
    private func addFacetsForParking(builder: TNEntityDetailParamsBuilder) -> TNEntityDetailParamsBuilder {
        let parkingParams = TNEntityParkingParameters()
        parkingParams.duration = 60
        parkingParams.entryTime = Date()
        
        let facetParams = TNEntityFacetParameters(parkingParams: parkingParams)
        return builder.facetParams(facetParams)
    }
    
    private func filterFrom(filterItems: [SelectableFilterItem]?) -> TNEntitySearchFilter? {
        var searchFilter: TNEntitySearchFilter?
        
        if let filterItems = filterItems, filterItems.count > 0 {
            
            let tnFilter = TNEntitySearchFilter()

            for f in filterItems {
                if let filter = f as? FiltersItem {
                    
                    switch filter.itemType {
                    case .categoryRow:
                        
                        let categoryFilter = filter as! TelenavCategoryDisplayModel
                        
                        guard let id = categoryFilter.category.id else {
                            return nil
                        }
                        
                        if tnFilter.categoryFilter == nil {
                            tnFilter.categoryFilter = TNEntitySearchCategoryFilter()
                        }
                        
                        if tnFilter.categoryFilter?.categories.contains(id) == false {
                            tnFilter.categoryFilter?.categories.append(id)
                        }
                        
                    case .brandRow:
                        break
                        
                    case .evFilterRow:
                        break
                    case .geoFilterRow:
                        let geoFilter = filter as! TNEntityGeoFilterTypeDisplayModel
                        
                        if tnFilter.geoFilter == nil {
                            tnFilter.geoFilter = TNEntityGeoFilter()
                        }
                        
                        tnFilter.geoFilter?.type = geoFilter.geoFilterType
                    }
                    
                } else if let filter = f as? EVFilterItem {
                    switch filter.evFilterType {
                    case .chargerBrands:
                        
                        let chargerBrand = filter as! ChargerBrand
                        
                        if tnFilter.evFilter == nil {
                            tnFilter.evFilter = TNEntityEvFilter()
                        }
                        
                        if tnFilter.evFilter?.chargerBrands == nil {
                            tnFilter.evFilter?.chargerBrands = []
                        }
                        
                        if tnFilter.evFilter?.chargerBrands?.contains(chargerBrand.chargerBrandType.rawValue) == false {
                            
                            tnFilter.evFilter?.chargerBrands?.append(chargerBrand.chargerBrandType.rawValue)
                        }
                        
                    case .connectorTypes:
                        let connectorType = filter as! Connector
                        
                        if tnFilter.evFilter == nil {
                            tnFilter.evFilter = TNEntityEvFilter()
                        }
                        
                        if tnFilter.evFilter?.connectorTypes == nil {
                            tnFilter.evFilter?.connectorTypes = []
                        }
                        
                        if tnFilter.evFilter?.connectorTypes?.contains(connectorType.connectorType.rawValue) == false {
                            
                            tnFilter.evFilter?.connectorTypes?.append(connectorType.connectorType.rawValue)
                        }
                        
                    case .powerFeeds:
                        let powerFeed = filter as! PowerFeedLevel
                        
                        if tnFilter.evFilter == nil {
                            tnFilter.evFilter = TNEntityEvFilter()
                        }
                        
                        if tnFilter.evFilter?.powerFeedLevels == nil {
                            tnFilter.evFilter?.powerFeedLevels = []
                        }
                        
                        if tnFilter.evFilter?.powerFeedLevels?.contains(powerFeed.level.rawValue) == false {
                            
                            tnFilter.evFilter?.powerFeedLevels?.append(powerFeed.level.rawValue)
                        }
                    }
                } else if let filter = f as? TNEntityBBoxGeoFilter {
                    tnFilter.geoFilter = filter
                }
            }
            
            searchFilter = tnFilter
        }
        return searchFilter
    }
    
    private func handleSearchResult(_ telenavSearch: TNEntitySearchResult?, isPaginated: Bool) {
        
        self.hasMoreSearchResults = telenavSearch?.hasMore ?? false
        self.showingMap = true
        
        if isPaginated {
            for res in telenavSearch?.results ?? [] {
        
                if self.searchContent.contains(where: { (searchRes) -> Bool in
                    searchRes.id == res.id
                }) == false {
                    self.searchContent.append(res)
                }
            }
        } else {
            self.searchContent = telenavSearch?.results ?? []
        }

        self.searchPaginationContext = telenavSearch?.paginationContext?.nextPageContext
        
        self.heightAnchor.constant = self.setupSearchHeight()
        searchResultViewAnimator.middleHeight = heightAnchor.constant
        self.searchResultsVC.fillSearchResults(self.searchContent, resetPagination: isPaginated == false)
        self.searchVisible = true
        self.catalogVisible = false
        self.searchResultDisplaying = true
        self.backButton.isHidden = false
        self.addAnnotations(from: self.searchContent)
    }
    
    private func getPredictions(on searchQuery: String) {
        let location = TNEntityGeoPoint(lat: currentLocation.latitude, lon: currentLocation.longitude)
        
        var params: TNEntityWordPredictionParams!
        do {
            params = try TNEntityWordPredictionParamsBuilder()
                .searchQuery(searchQuery)
                .location(location)
                .build()
        } catch let error {
            print(error)
            //handle error here
            return
        }
    
        TNEntityClient.getWordPredictions(params: params) { (prediction, err) in
            
            if let predictions = prediction?.results {
                
                self.predictionsView.content = predictions
                if !self.searchVisible {
                    self.predictionsView.isHidden = false
                }
                self.mapContainerView.bringSubviewToFront(self.predictionsView)
            } else {
                self.hidePredictionsView()
            }
        }
    }
}

extension MapViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.hidePredictionsView()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let searchQuery = textField.text else {
            return false
        }
        
        startSearch(searchQuery: searchQuery)
        
        textField.resignFirstResponder()
        predictionsView.isHidden = true
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = (textField.text ?? "") as NSString
        let resultText = currentText.replacingCharacters(in: range, with: string)
        
        throttler.throttle {
            DispatchQueue.main.async {
                
                if resultText.isEmpty {
                    self.catalogVC.staticCategoriesDisplayManager.reloadTable()
                    self.hidePredictionsView()
                    self.predictionsView.content = []
                    self.catalogVisible = true
                }
                
                else {
                    
                    self.getPredictions(on: resultText)
                    
                    self.getSuggestions(text: resultText) { (result) in
                        if !self.searchTextField.text!.isEmpty {
                            self.catalogVC.fillSuggestions(result)
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        self.catalogVC.staticCategoriesDisplayManager.reloadTable()
        self.hidePredictionsView()
        self.predictionsView.content = []

        return true
    }
    
    private func annotationFromEntity(entity: TNEntity) -> PlaceAnnotation2? {
        if let coords = entity.place?.address?.geoCoordinates ?? entity.address?.geoCoordinates,
           let identifier = entity.id {
            let coordinate = CLLocationCoordinate2D(latitude: coords.latitude ?? 0, longitude: coords.longitude ?? 0)
            let categories = entity.place?.categories?.compactMap { $0.id }
            let annotation = PlaceAnnotation2(coordinate: coordinate , id: identifier, categories: categories)
            annotation.title = entity.place?.name ?? entity.address?.formattedAddress
            return annotation
        }
        return nil
    }
    
    private func addAnnotations(from searchResults: [TNEntity]) {
        removeEntityAnnotations()
        
        var annotations = [PlaceAnnotation2]()
        
        for (idx,res) in searchResults.enumerated() {
            if let annotation = annotationFromEntity(entity: res) {
                annotation.number = idx + 1
                annotations.append(annotation)
            }
        }
        
        self.currentAnnotations = annotations
        addEntityAnnotations(annotations: annotations)
        
        if searchResults.isEmpty {
            // current point
            moveMapCameraTo(to: currentLocation)
        } else {
            let region = obtainRegionForAnnotationsArr(annotations)
            mapView.cameraController().show(region)
        }
    }
    
    private func getSuggestions(text: String, comletion: @escaping ([TNEntitySuggestion]) -> Void) {
        let location = TNEntityGeoPoint(lat: currentLocation.latitude, lon: currentLocation.longitude)
        
        let params = TNEntitySuggestionParams(searchQuery: text, location: location, includeEntity: true)
        
        TNEntityClient.getSuggestions(params: params) { (suggestions, err) in
            
            guard let suggestions = suggestions?.results else {
                if let err = err {
                    print(err.localizedDescription)
                }
                
                comletion([])
                return
            }
            
            comletion(suggestions)
        }
    }
    
    private func hidePredictionsView() {
        predictionsView.isHidden = true
    }

    private func resetSearch() {
        self.searchQuery = nil
        self.searchPaginationContext = nil
        self.hasMoreSearchResults = false
    }
}

extension MapViewController: SearchResultViewControllerDelegate {
    
    func loadMoreSearchResults() {
        return; // turn off pagination
//        if let context = searchPaginationContext, self.hasMoreSearchResults {
//            TNEntityCore.search(searchParams: TNEntitySearchQueryBuilder().pageContext(context).build() ) { (searchRes, err) in
//                self.handleSearchResult(searchRes, isPaginated: true)
//            }
//        }
    }
   
    func didSelectResultItem(entity: TNEntity, distance: String?) {
        backButton.isHidden = false
        
        guard let annotation = annotationFromEntity(entity: entity) else {
            return
        }
        
        goToDetails(placeAnnotation: annotation, distance: distance)

        if let ann = currentAnnotations.first(where: { (ann) -> Bool in
            if ann.placeId == annotation.placeId {
                return true
            }
            return false
        }) {
            // TODO:
            // mapView.selectAnnotation(ann, animated: true)
        }
    }
    
    func showOnlyMainScreen() {
        didReturnToStaticCategories()
        showingSubCatalog = false
        showingMap = false
    }
    
    func showOnlyCatalog() {
        self.toggleDetailView(visible: false)
        searchVisible = false
        catalogVisible = true
        predictionsView.isHidden = true
        backButton.isHidden = !showingSubCatalog
        
        showingMap = false
    }
    
    func hideDetail() {
        self.toggleDetailView(visible: false)
        showingDetail = false
    }

    func goBack() {
        if showingSubCatalog && !showingMap && !showingDetail {
            showOnlyMainScreen()
        }
        
        if showingMap && !showingDetail {
            showOnlyCatalog()
        }
        
        if showingDetail {
            hideDetail()
            
            if !showingMap {
                showOnlyCatalog()
            }
        }
    }
}

extension MapViewController: CoordinateSettingsDelegate {
    
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem]) {
        self.selectedFilters = selectedFilters
    }
    
    func regionDidChange(region: String) {
        removeWayPoints()
        
        routesScrollView.setRoutes(routes: [], withDelegate: self)
        hideRoutesScroll()
    }
}

extension MapViewController: LocationProviderDelegate {
  func locationProvider(provider: LocationProvider, locationDidChanged location: CLLocationCoordinate2D) {
    let from = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
    let to = CLLocation(latitude: location.latitude, longitude: location.longitude)
    
    if to.distance(from: from) > 500 /* meters */ {
      moveMapCameraTo(to: location)
    }
    
    currentLocation = location
    setUserPushPin(userLocation: currentLocation)
  }
}
