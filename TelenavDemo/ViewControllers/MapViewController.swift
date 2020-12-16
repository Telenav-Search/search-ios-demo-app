//
//  MapViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 19.10.2020.
//

import UIKit
import TelenavEntitySDK
import Alamofire
import MapKit

class MapViewController: UIViewController, CatalogViewControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    @IBOutlet var detailsViewAnimator: PanViewAnimator!
    @IBOutlet var searchResultViewAnimator: PanViewAnimator!
 
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.showsUserLocation = true
        }
    }
    @IBOutlet weak var searchQueryLabel: UILabel!
    
    @IBOutlet weak var detailsView: DetailsView!
    
    @IBOutlet weak var detailsViewBottomConstraint: NSLayoutConstraint! 
    
    @IBOutlet weak var predictionsView: PredictionsView! {
        didSet {
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
    }
    
    var currentDetailID: String = ""
    
    let locationManager = CLLocationManager()
    
    let fakeCategoriesService = FakeCategoriesGenerator()
    
    private var throttler = Throttler(throttlingInterval: 0.7, maxInterval: 1, qosClass: .userInitiated)
    
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
            
            for sbv in searchResultsVC.view.subviews {
                sbv.isHidden = !searchVisible
            }
            
            heightAnchor.constant = setupSearchHeight()
            searchResultViewAnimator.bottomConstraint.constant = 0
            
            mapContainerView.layoutIfNeeded()
            view.layoutIfNeeded()
        }
    }

    private var searchPaginationContext: String?
    private var searchContent = [TNEntity]()
    private var currentAnnotations = [MKAnnotation]()
    private var staticCategories = [TNEntityStaticCategory]()
    
    private var annotationsSetupCallback: (() -> Void)?
    
    private var currentLocation: CLLocationCoordinate2D?
    private var fakeLocation: CLLocationCoordinate2D?

    private var searchResultDisplaying: Bool = false
    private var searchQuery: String?
    private var hasMoreSearchResults: Bool = false
    
    private var selectedFilters = [SelectableFilterItem]()
    
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

    
    // MARK: - View management
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        setupSDK()
        
        fakeCategoriesService.getStaticCategories { (staticCats, err) in
            
            guard let categories = staticCats else {
                return
            }
            
            self.staticCategories = categories
            
            self.catalogVC.fillStaticCategories(categories)
        }
        
        configureLocationManager()
        addChildView()
        addSearchAsChild()
        detailsView.superview?.bringSubviewToFront(detailsView)
        toggleDetailView(visible: false)

        NotificationCenter.default.addObserver(forName: Notification.Name("LocationChangedNotification"), object: nil, queue: .main) { [weak self] (notif) in
            
            if let location = notif.userInfo?["location"] as? CLLocationCoordinate2D {
                self?.fakeLocation = location
                self?.currentLocation = location
            } else if let useReal = notif.userInfo?["useReal"] as? Bool, useReal == true {
                self?.fakeLocation = nil
                if let realLoc = self?.locationManager.location?.coordinate {
                    self?.currentLocation = realLoc
                }
            }
        }
        
        let panGesture2 = UIPanGestureRecognizer(target: self.searchResultViewAnimator, action: #selector(PanViewAnimator.didDragMainView(_:)))
        searchResultsVC.view.addGestureRecognizer(panGesture2)
        
        let swipe1 = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetailLeft))
        swipe1.direction = .left
        detailsView.addGestureRecognizer(swipe1)
     
        let swipe2 = UISwipeGestureRecognizer(target: self, action: #selector(swipeDetailRight))
        swipe2.direction = .right
        detailsView.addGestureRecognizer(swipe2)
    }
    
    func findAnnIndex(id: String) -> Int {
        for (idx, ann) in currentAnnotations.enumerated() {
            if let ann = ann as? PlaceAnnotation, ann.placeId == id {
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
        if let ann = currentAnnotations[newIdx] as? PlaceAnnotation {
            goToDetails(entityId: ann.placeId)
        }
    }
    
    @objc func swipeDetailLeft() {
        var newIdx = findAnnIndex(id: currentDetailID) + 1
        if newIdx == NSNotFound {
            return
        }
        if newIdx >= currentAnnotations.count {
            newIdx = currentAnnotations.count - 1
        }
        if let ann = currentAnnotations[newIdx] as? PlaceAnnotation {
            goToDetails(entityId: ann.placeId)
        }
    }

    func configureLocationManager() {
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func addChildView() {
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
        
        let bottomVal = -400 + 35 + tabBarController!.tabBar.frame.size.height
        let bottom = mapContainerView.bottomAnchor.constraint(equalTo: searchResultsVC.view.bottomAnchor,
                                                                  constant: bottomVal)
        bottom.isActive = true
            
        searchResultsVC.view.leftAnchor.constraint(equalTo: mapContainerView.leftAnchor).isActive = true
        searchResultsVC.view.rightAnchor.constraint(equalTo: mapContainerView.rightAnchor).isActive = true
        
        searchResultViewAnimator.bottomConstraint = bottom
        searchResultViewAnimator.dtailsViewHeightConstraint = heightAnchor
        searchResultViewAnimator.standrdDetailViewBottomConstrainValue = bottomVal
        searchResultViewAnimator.initialBottomConstraintValue = bottomVal
    }
    
    private func setupSearchHeight() -> CGFloat {
        
        var heightConstraint: CGFloat
        
        if searchVisible {
            heightConstraint = 400
        } else {
            heightConstraint = 0
        }
    
        return heightConstraint
    }

    private func toggleDetailView(visible: Bool) {
        heightAnchor.constant = visible ? 0 : 400
        
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
    
    private func setupSDK() {
        let sdkOptions = TNEntitySDKOptions(apiKey: "3aba881b-f452-4f53-99de-7397dce2b59b", apiSecret: "bd112f9b-a368-4869-bca6-351e5c4c9e4f", deviceId: nil, userId: nil, locale: Locale.current.languageCode)
        sdkOptions.cloudEndPoint = "http://restapidev.telenav.com/entity/v5/"
      
        TNEntityCore.setApiOptions(sdkOptions)
    }
    
    // MARK: - Actions
    
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
        
        mapView.removeAnnotations(self.currentAnnotations)
        
        self.backButton.isHidden = false
        
        startSearch(searchQuery: name)
    }
    
    private func selectDetailOnMap(id: String) {
        self.annotationsSetupCallback = {
            
            if let selectedAnn = self.currentAnnotations.first(where: { (ann) -> Bool in
                
                if let placeAnn = ann as? PlaceAnnotation {
                    
                    if placeAnn.placeId == id {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            }) {
                let view = self.mapView.view(for: selectedAnn)
                self.mapView.selectAnnotation(selectedAnn, animated: true)
                view?.isSelected = true
            }
        }
    }
    
    func didSelectSuggestion(id: String) {
        searchVisible = true
        searchResultsVC.view.isHidden = true
        searchTextField.resignFirstResponder()
        
        mapView.removeAnnotations(self.currentAnnotations)
        
        goToDetails(entityId: id) { (entity) in
            guard let coord = entity.place?.address?.geoCoordinates ?? entity.address?.geoCoordinates,
                  let id = entity.id,
                  let name = entity.place?.name ?? entity.address?.formattedAddress
            else {
                return
            }

            self.searchQueryLabel.text = name
            
            let coordinates = CLLocationCoordinate2D(latitude: coord.latitude ?? 0, longitude: coord.longitude ?? 0)
     
            let annotation = PlaceAnnotation(coordinate: coordinates, id: id)
            annotation.title = name
            
            self.currentAnnotations = [annotation]
            
            let region = self.mapView.regionThatFits(MKCoordinateRegion(center: coordinates, latitudinalMeters: 400, longitudinalMeters: 200))
            
            self.mapView.setRegion(region, animated: true)
            self.mapView.addAnnotations(self.currentAnnotations)
            self.backButton.isHidden = false
            
            let padding = UIEdgeInsets.init(top: 50, left: 50, bottom: 300, right: 50)
            self.mapView.setVisibleMapRect(region.mapRect, edgePadding: padding, animated: true)
     
            self.selectDetailOnMap(id: id)
        }
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
            
            self.backButton.isHidden = false
            let filter = TelenavCategoryDisplayModel(category: TNEntityCategory(childNodes: nil, id: (item as? StaticCategoryDisplayModel)?.staticCategory.id, name: nil),
                                                     catLevel: 0)
            
            var finalFilters: [SelectableFilterItem] = [filter]
            if filter.category.id == "771" {
                finalFilters = selectedFilters + [filter]
            }
            startSearch(searchQuery: "", filterItems: finalFilters)
            searchQueryLabel.text = (item as? StaticCategoryDisplayModel)?.staticCategory.name
            
        case .moreItem:
            backButton.isHidden = false
            TNEntityCore.getCategories { (categories, err) in

                guard let categories = categories?.results else {
                    return
                }

                let cats = self.fakeCategoriesService.mappedCats(categories)
                
                self.catalogVC.fillAllCategories(cats)
                self.catalogVisible = true
                self.showingSubCatalog = true
            }
        }
    }
    
    // MARK: - Map
    
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D){
       let annotation = MKPointAnnotation()
       annotation.coordinate = location
       annotation.title = "Device Location"
       let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
       mapView.setRegion(coordinateRegion, animated: true)
       mapView.addAnnotation(annotation)
    }
    
    // MARK: - LocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }

        if let fakeLocation = self.fakeLocation {
            self.currentLocation = fakeLocation
        } else {
            self.currentLocation = locValue
        }
        if let nav = self.tabBarController?.viewControllers?[1] as? UINavigationController,
           let vc = nav.topViewController as? CoordinateSettingsController {
            vc.delegate = self
        }
//        setPinUsingMKPointAnnotation(location: locValue)
    }
    
    private func obtainRegionForAnnotationsArr(_ arr: [MKAnnotation]) -> MKCoordinateRegion {
     
         var minLat: Double = 90;
         var minLon: Double = 180;
         var maxLat: Double = -90;
         var maxLon: Double = -180;
         
         for ann in arr {
             minLat = fmin(minLat, ann.coordinate.latitude)
             minLon = fmin(minLon, ann.coordinate.longitude)
             maxLat = fmax(maxLat, ann.coordinate.latitude)
             maxLon = fmax(maxLon, ann.coordinate.longitude)
         }
         
         let midLat =  (minLat + maxLat)/2;
         let midLong = (minLon + maxLon)/2;
         
         let deltaLat = fabs(maxLat - minLat);
         let deltaLong = fabs(maxLon - minLon);
         
         let span = MKCoordinateSpan.init(latitudeDelta: deltaLat, longitudeDelta: deltaLong)
         let region = MKCoordinateRegion.init(center: CLLocationCoordinate2DMake(midLat, midLong), span: span)
     
         return region
     }
    
    private func goToDetails(entityId: String, completion: ((TNEntity) -> Void)? = nil) {
        
        let params = TNEntityQueryBuilder().ids([entityId]).build()
        
        TNEntityCore.getEntityDetails(params: params) { [weak self] (entities, err) in
            
            guard let self = self else {
                return
            }
            
            guard let detail = entities?.results?.first else {
                return
            }

            self.currentDetailID = entityId
            self.detailsView.fillEntity(detail, currentCoordinate: self.currentLocation ?? CLLocationCoordinate2D())
            self.toggleDetailView(visible: true)
            
            self.catalogVisible = false
            self.showingDetail = true
            
            completion?(detail)
        }
    }
    
    private func startSearch(searchQuery: String, filterItems: [SelectableFilterItem]? = nil) {
 
        resetSearch()
        searchQueryLabel.text = searchQuery
 
        self.searchQuery = searchQuery
        self.backButton.isHidden = true

        var searchFilter: TNEntityFilter?
        
        if let filterItems = filterItems, filterItems.count > 0 {
            
            let tnFilter = TNEntityFilter()

            for f in filterItems {
                if let filter = f as? FiltersItem {
                    
                    switch filter.itemType {
                    case .categoryRow:
                        
                        let categoryFilter = filter as! TelenavCategoryDisplayModel
                        
                        guard let id = categoryFilter.category.id else {
                            return
                        }
                        
                        if tnFilter.categoryFilter == nil {
                            tnFilter.categoryFilter = TNEntityCategoryFilter()
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
                }
            }
            
            searchFilter = tnFilter
        }
        
        let searchParams = TNEntitySearchParams(searchQuery: searchQuery,
                                               location: TNEntityGeoPoint(lat: currentLocation?.latitude ?? 0, lon: currentLocation?.longitude ?? 0),
                                               filters: searchFilter,
                                               searchOptionsIntent: TNEntitySearchOptionIntent.around,
                                               showAddressLines: false)
        
//        Alternative variant of building searchParams
//        let searchParams = TNEntitySearchQueryBuilder()
//            .limit(10)
//            .query("food")
//            .location(TNEntityGeoPoint(lat: 0, lon: 0))
//            .build()
        
        TNEntityCore.search(searchParams: searchParams) { (telenavSearch, err) in
            self.handleSearchResult(telenavSearch, isPaginated: false)
        }
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
        self.searchResultsVC.fillSearchResults(self.searchContent, resetPagination: isPaginated == false)
        self.searchVisible = true
        self.catalogVisible = false
        self.searchResultDisplaying = true
        self.backButton.isHidden = false
        self.addAnnotations(from: self.searchContent)
    }
    
    private func getPredictions(on searchQuery: String) {
        
        let location = TNEntityGeoPoint(lat: currentLocation?.latitude ?? 0, lon: currentLocation?.longitude ?? 0)
        
        let params = TNEntityPredictionWordQueryBuilder()
            .searchQuery(searchQuery)
            .location(location)
            .build()
    
        TNEntityCore.getWordPredictions(params: params) { (prediction, err) in
            
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
    
    private func addAnnotations(from searchResults: [TNEntity]) {
        
        mapView.removeAnnotations(self.currentAnnotations)
              
        var annotations = [MKAnnotation]()
        
        for (idx,res) in searchResults.enumerated() {
            if let coords = res.place?.address?.geoCoordinates ?? res.address?.geoCoordinates,
               let identifier = res.id {
                let annotation = PlaceAnnotation(coordinate: CLLocationCoordinate2D(latitude: coords.latitude ?? 0, longitude: coords.longitude ?? 0), id: identifier)
                annotation.title = res.place?.name ?? res.address?.formattedAddress
                annotation.number = idx + 1
                
                annotations.append(annotation)
            }
        }
        
        if let currentLocation = currentLocation {
            
            let myLocationAnnotation = MKPointAnnotation()
            myLocationAnnotation.coordinate = currentLocation
            myLocationAnnotation.title = "Here"
            myLocationAnnotation.subtitle = "Device Location"
            
            annotations.append(myLocationAnnotation)
        }
        
        self.currentAnnotations = annotations
        
        let region = obtainRegionForAnnotationsArr(annotations)
            
        mapView.setRegion(region, animated: true)
        
        let padding = UIEdgeInsets.init(top: 50, left: 50, bottom: 400, right: 50)
        mapView.setVisibleMapRect(region.mapRect, edgePadding: padding, animated: true)
        
        mapView.addAnnotations(annotations)
    }
    
    private func getSuggestions(text: String, comletion: @escaping ([TNEntitySuggestion]) -> Void) {
        
        let location = TNEntityGeoPoint(lat: currentLocation?.latitude ?? 0, lon: currentLocation?.longitude ?? 0)
        
        let params = TNEntitySuggestionParams(searchQuery: text, location: location, includeEntity: true)
        
        TNEntityCore.getSuggestions(params: params) { (suggestions, err) in
            
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
        
        if let context = searchPaginationContext, self.hasMoreSearchResults {
            TNEntityCore.search(searchParams: TNEntitySearchQueryBuilder().pageContext(context).build() ) { (searchRes, err) in
                self.handleSearchResult(searchRes, isPaginated: true)
            }
        }
    }
   
    func didSelectResultItem(id: String) {
        backButton.isHidden = false
        goToDetails(entityId: id)
        
        if let ann = currentAnnotations.first(where: { (ann) -> Bool in
            if let placeAnn = ann as? PlaceAnnotation, placeAnn.placeId == id {
                return true
            }
            return false
        }) {
            
            mapView.selectAnnotation(ann, animated: true)
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

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
       
        if (view.annotation as? PlaceAnnotation) != nil {
            
            view.isSelected = true
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        if view.annotation is PlaceAnnotation {

            view.isSelected = false
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if view.annotation is PlaceAnnotation {
            let placeAnn = view.annotation as! PlaceAnnotation
            
            goToDetails(entityId: placeAnn.placeId)
            showingMap = currentAnnotations.count > 1
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is PlaceAnnotation else { return nil }
        
        let customAnnotationView = self.customAnnotationView(in: mapView, for: annotation)
        return customAnnotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
     
        if searchResultDisplaying == false {
            annotationsSetupCallback?()
        }
        
        searchResultDisplaying = false
    }
    
    private func customAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> PlaceAnnotationView {
        let identifier = "PlaceAnnotationView"

        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? PlaceAnnotationView {
            annotationView.annotation = annotation
            setNumber(for: annotation, customAnnotationView: annotationView)

            return annotationView
        } else {
            let customAnnotationView = PlaceAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            customAnnotationView.canShowCallout = true
            
            let btn = UIButton(type: .detailDisclosure)
            customAnnotationView.rightCalloutAccessoryView = btn
            
            setNumber(for: annotation, customAnnotationView: customAnnotationView)
            
            return customAnnotationView
        }
    }
    
    private func setNumber(for annotation: MKAnnotation, customAnnotationView: PlaceAnnotationView) {
        
        if let ann = annotation as? PlaceAnnotation {
            customAnnotationView.number = ann.number
        }
    }
}

extension MKCoordinateRegion {
    
    var mapRect: MKMapRect {
        get{
            let a = MKMapPoint.init(CLLocationCoordinate2DMake(
                self.center.latitude + self.span.latitudeDelta / 2,
                self.center.longitude - self.span.longitudeDelta / 2))
            
            let b = MKMapPoint.init(CLLocationCoordinate2DMake(
                self.center.latitude - self.span.latitudeDelta / 2,
                self.center.longitude + self.span.longitudeDelta / 2))
            
            return MKMapRect.init(x: min(a.x,b.x), y: min(a.y,b.y), width: abs(a.x-b.x), height: abs(a.y-b.y))
        }
    }
}

extension MapViewController: FiltersViewControllerDelegate {
    
    func updateSelectedFilters(selectedFilters: [SelectableFilterItem]) {
        self.selectedFilters = selectedFilters
    }
}
