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
    
    @IBOutlet weak var catalogButton: UIButton!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
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
    
    private var throttler = Throttler(throttlingInterval: 0.7, maxInterval: 1, qosClass: .userInitiated)
    
    var catalogVisible = true {
        didSet {
            catalogVC.view.isHidden = !catalogVisible
        }
    }
    
    lazy var catalogVC: CatalogViewController = {
        let vc = storyboard!.instantiateViewController(withIdentifier: "CatalogViewController") as! CatalogViewController
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
            
            self.catalogVC.fillStaticCategories(categories)
        }
        
        toggleDetailView(visible: false)
        configureLocationManager()
        addChildView()
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

    private func toggleDetailView(visible: Bool) {
        detailsViewBottomConstraint?.constant = visible ? 0 : -(detailsView?.bounds.height ?? 190)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func catalogAction(_ sender: Any) {
        catalogVisible = true
    }
    
    // MARK: - Catalog Delegate
    
    func didSelectSuggestion(id: String) {
        
        fakeDetailsService.getDetails(id: id) { (telenavEntities, err) in

            guard let detail = telenavEntities?.first else {
                return
            }

            self.detailsView.fillEntity(detail)
            self.toggleDetailView(visible: true)
            
            self.catalogVisible = false
        }
    }
    
    func didSelectNode() {
        
    }
    
    func didReturnToMap() {
        catalogVisible = false
    }
    
    func didSelectCategoryItem(_ item: StaticCategoryCellItem) {
        
        switch item.cellType {
        case .categoryItem:
            break
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

        setPinUsingMKPointAnnotation(location: locValue)
    }
}

extension MapViewController: UITextFieldDelegate {
    
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
