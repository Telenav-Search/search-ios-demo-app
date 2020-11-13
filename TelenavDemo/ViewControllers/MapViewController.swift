//
//  MapViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 19.10.2020.
//

import UIKit
import TelenavSDK
import Alamofire
import MapKit

class MapViewController: UIViewController, CatalogViewControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    @IBOutlet weak var detailsView: DetailsView! {
        didSet {
            detailsView.layer.cornerRadius = 18
            detailsView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
    }
    
    @IBOutlet weak var detailsViewBottomConstraint: NSLayoutConstraint!
    
    let searchService = TelenavSearchService()
    let suggestionsService = TelenavSuggestionsService()
    let locationManager = CLLocationManager()
    
    let fakeCategoriesService = FakeCategoriesGenerator()
    let fakeSuggestionsService = FakeSuggestionsGenerator()
    let fakeDetailsService = FakeDetailsGenerator()
    let fakeSearchService = FakeSearchGenerator()
    
    private var throttler = Throttler(throttlingInterval: 0.7, maxInterval: 1, qosClass: .userInitiated)
    
    var catalogVisible = true {
        didSet {
            catalogVC.view.isHidden = !catalogVisible
        }
    }
    
    var heightAnchor: NSLayoutConstraint!
    
    var searchVisible = false {
        didSet {
            searchResultsVC.view.isHidden = !searchVisible
            
            for sbv in searchResultsVC.view.subviews {
                sbv.isHidden = !searchVisible
            }
            
            heightAnchor.constant = setupSearchHeight()
            
            mapContainerView.layoutIfNeeded()
            view.layoutIfNeeded()
        }
    }

    private var searchPaginationContext: String?
    private var searchContent = [TelenavSearchResult]()
    private var currentAnnotations = [MKAnnotation]()
    private var staticCategories = [TelenavStaticCategory]()
    
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
        TelenavCore.setApiKey("3aba881b-f452-4f53-99de-7397dce2b59b", apiSecret: "bd112f9b-a368-4869-bca6-351e5c4c9e4f")
        
        searchService.search(location: TelenavGeoPoint(lat: 45.5, lon: 25), searchQuery: "food") { (result, err) in
            print(result)
        }
        
        suggestionsService.getSuggestions(location: TelenavGeoPoint(lat: 45.5, lon: 25), query: "food", includeEntity: false) { (result, err) in
            print(result?.results)
        }
    
        fakeCategoriesService.getStaticCategories { (staticCats, err) in
            
            guard let categories = staticCats else {
                return
            }
            
            self.staticCategories = categories
            
            self.catalogVC.fillStaticCategories(categories)
        }
        
        toggleDetailView(visible: false)
        configureLocationManager()
        addChildView()
        addSearchAsChild()
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
        view.addSubview(searchResultsVC.view)
        view.bringSubviewToFront(searchResultsVC.view)
        
        searchResultsVC.view.translatesAutoresizingMaskIntoConstraints = false
        setupSearchConstraints()
        
        searchResultsVC.view.backgroundColor = .red
    }
    
    private func setupSearchConstraints() {
        
        searchResultsVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            
        heightAnchor = searchResultsVC.view.heightAnchor.constraint(equalToConstant: setupSearchHeight())
        heightAnchor.isActive = true
        
        searchResultsVC.view.leftAnchor.constraint(equalTo: mapContainerView.leftAnchor).isActive = true
        searchResultsVC.view.rightAnchor.constraint(equalTo: mapContainerView.rightAnchor).isActive = true
    }
    
    private func setupSearchHeight() -> CGFloat {
        
        let heightConstraint = searchVisible ? mapContainerView.frame.height / 3 : 0

        return heightConstraint
    }

    private func toggleDetailView(visible: Bool) {
        detailsViewBottomConstraint?.constant = visible ? 0 : -(detailsView?.bounds.height ?? 220)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func didTapOnMap(_ sender: Any) {
        
        toggleDetailView(visible: false)
        searchTextField.resignFirstResponder()
    }
    
    
    @IBAction func didClickBack(_ sender: Any) {
        
        catalogVisible = true
        backButton.isHidden = true
        toggleDetailView(visible: false)
    }
    
    // MARK: - Catalog Delegate
    
    func goToChildCategory(id: String) {
        searchTextField.resignFirstResponder()
        
        mapView.removeAnnotations(self.currentAnnotations)
        
        self.backButton.isHidden = false
        
        goToDetails(entityId: id) { (entity) in
            
            guard let coord = entity.place?.address?.geoCoordinates, let id = entity.id else {
                return
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: coord.latitude ?? 0, longitude: coord.longitude ?? 0)
            
            let annotation = PlaceAnnotation(coordinate: coordinates, id: id)
            
            self.currentAnnotations = [annotation]
            
            let region = self.mapView.regionThatFits(MKCoordinateRegion(center: coordinates, latitudinalMeters: 400, longitudinalMeters: 400))
            
            self.mapView.setRegion(region, animated: true)
            self.mapView.addAnnotations(self.currentAnnotations)
        }
    }
    
    func didSelectSuggestion(id: String) {
        
        searchTextField.resignFirstResponder()
        
        mapView.removeAnnotations(self.currentAnnotations)
        
        goToDetails(entityId: id) { (entity) in
            
            guard let coord = entity.place?.address?.geoCoordinates, let id = entity.id else {
                return
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: coord.latitude ?? 0, longitude: coord.longitude ?? 0)
            
            let annotation = PlaceAnnotation(coordinate: coordinates, id: id)
            
            self.currentAnnotations = [annotation]
            
            let region = self.mapView.regionThatFits(MKCoordinateRegion(center: coordinates, latitudinalMeters: 200, longitudinalMeters: 200))
            
            self.mapView.setRegion(region, animated: true)
            self.mapView.addAnnotations(self.currentAnnotations)
            self.backButton.isHidden = false
        }
    }
    
    func didReturnToMap() {
        catalogVisible = true
        backButton.isHidden = true
        catalogVC.fillStaticCategories(self.staticCategories)
    }
    
    func didSelectCategoryItem(_ item: StaticCategoryCellItem) {
        
        switch item.cellType {
        case .categoryItem:
            
            startSearch(searchQuery: (item as! StaticCategoryDisplayModel).staticCategory.name ?? "")
            self.backButton.isHidden = false
            
        case .moreItem:
            fakeCategoriesService.getAllCategories { (categories, err) in

                guard let categories = categories else {
                    return
                }

                self.catalogVC.fillAllCategories(categories)
                self.catalogVisible = true
            }
        }
    }
    
    // MARK: - Map
    
    func setPinUsingMKPointAnnotation(location: CLLocationCoordinate2D){
       let annotation = MKPointAnnotation()
       annotation.coordinate = location
       annotation.title = "Here"
       annotation.subtitle = "Device Location"
       let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
       mapView.setRegion(coordinateRegion, animated: true)
       mapView.addAnnotation(annotation)
    }
    
    // MARK: - LocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }

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
    
    private func goToDetails(entityId: String, completion: ((TelenavEntity) -> Void)? = nil) {
        fakeDetailsService.getDetails(id: entityId) { (telenavEntities, err) in

            guard let detail = telenavEntities?.first else {
                return
            }

            self.detailsView.fillEntity(detail)
            self.toggleDetailView(visible: true)
            
            self.catalogVisible = false
            
            completion?(detail)
        }
    }
    
    private func startSearch(searchQuery: String) {
        
        fakeSearchService.getSearchResult(query: searchQuery) { (telenavSearch, err) in
            
            self.searchPaginationContext = telenavSearch?.paginationContext?.nextPageContext
            
            for res in telenavSearch?.results ?? [] {
                
                if self.searchContent.contains(res) == false {
                    self.searchContent.append(res)
                }
            }
            
            self.searchResultsVC.fillSearchResults(self.searchContent)
            self.searchVisible = true
            self.catalogVisible = false
                        
            self.addAnnotations(from: self.searchContent)
        }
    }
}

extension MapViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let searchQuery = textField.text else {
            return false
        }
        
        startSearch(searchQuery: searchQuery)
        
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = (textField.text ?? "") as NSString
        let resultText = currentText.replacingCharacters(in: range, with: string)
        
        throttler.throttle {
            DispatchQueue.main.async {
                
                if resultText.isEmpty {
                    self.catalogVC.categoriesDisplayManager.reloadTable()
                }
                
                else {
                    
                    self.getSuggestions(text: resultText) { (result) in
                        
                        self.catalogVC.fillSuggestions(result)
                    }
                }
            }
        }
        
        return true
    }
    
    private func addAnnotations(from searchResults: [TelenavSearchResult]) {
        
        let annotations = searchResults.map { (res) -> PlaceAnnotation in
            let annotation = PlaceAnnotation(coordinate: CLLocationCoordinate2D(latitude: res.place?.address?.geoCoordinates?.latitude ?? 0, longitude: res.place?.address?.geoCoordinates?.longitude ?? 0), id: res.id!)
            annotation.title = res.place?.name
    
            return annotation
        }
        
        self.currentAnnotations = annotations
        
        let region = obtainRegionForAnnotationsArr(annotations)
            
        mapView.setRegion(region, animated: true)
        
        let padding = UIEdgeInsets.init(top: 100, left: 50, bottom: 50, right: 200)
        mapView.setVisibleMapRect(region.mapRect, edgePadding: padding, animated: true)
        
        mapView.addAnnotations(annotations)
    }
    
    private func getSuggestions(text: String, comletion: @escaping ([TelenavSuggestionResult]) -> Void) {
        
        fakeSuggestionsService.getSuggestions { (suggestions, err) in
            
            guard let suggestions = suggestions else {
                print(err?.localizedDescription)
                comletion([])
                return
            }
            
            comletion(suggestions)
        }
    }
}

extension MapViewController: SearchResultViewControllerDelegate {
    
    func didSelectResultItem(id: String) {
        backButton.isHidden = false
        goToDetails(entityId: id)
    }

    func goBack() {
        searchVisible = false
        catalogVisible = true
        backButton.isHidden = true
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if view.annotation is PlaceAnnotation {
            let placeAnn = view.annotation as! PlaceAnnotation
            
            goToDetails(entityId: placeAnn.placeId)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
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
