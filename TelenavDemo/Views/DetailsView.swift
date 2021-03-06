//
//  DetailsView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavEntitySDK
import MapKit

class DetailsView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UINib(nibName: "DetailViewCell", bundle: nil), forCellReuseIdentifier: "DetailViewCell")
        }
    }
    
    var content = [DetailViewDisplayModel]()
    var ratingLink: URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed(String(describing: DetailsView.self), owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.isUserInteractionEnabled = true
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.backgroundColor = .clear
        
        let gest = UITapGestureRecognizer(target: self, action: #selector(tapRatingAction))
        ratingView.addGestureRecognizer(gest)
    }
    
    @objc func tapRatingAction() {
        if let url = ratingLink {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 18
        self.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        self.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 10.0
    }
    
    private var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.78274, longitude: -122.43152)
    private var entityLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    func fillEntity(_ entity: TNEntity, currentCoordinate: CLLocationCoordinate2D, distanceText: String? = nil) {
        
        self.currentLocation = currentCoordinate
        
        if let rating = entity.facets?.rating?.first, let count = rating.totalCount {
            if let str = rating.url {
                ratingLink = URL(string: str)
            }
            
            let avgRating = rating.averageRating ?? 0
            
            ratingView.isHidden = false
            ratingLabel.isHidden = false
            ratingLabel.text = "Reviews: \(count)"
            
            var rem = ""
            if avgRating.truncatingRemainder(dividingBy: 1) > 0 {
                rem = "_half"
            }
            
            ratingImage.image = UIImage(named: "large_\(Int(avgRating))\(rem)")

        } else {
            ratingView.isHidden = true
            ratingLabel.isHidden = true
        }
        
        switch entity.type {
        case .address:
            content = [
                DetailViewDisplayModel(fieldName: "Address", fieldValue: entity.address?.addressLines?.joined(separator: "\n") ?? ""),
            ]
            nameLabel.text = entity.address?.formattedAddress
            categoryLabel.isHidden = true

            break
        case .place:
            
            content = [
                DetailViewDisplayModel(fieldName: "Address", fieldValue: entity.place?.address?.addressLines?.joined(separator: "\n") ?? ""),
                DetailViewDisplayModel(fieldName: "Website", fieldValue: entity.place?.websites?.joined(separator: "\n") ?? "Not added yet"),
                DetailViewDisplayModel(fieldName: "Phone numbers", fieldValue: entity.place?.phoneNumbers?.joined(separator: "\n") ?? "Not added yet")
            ]
            
            if let place = entity.place, let categories = place.categories {
                if categories.filter({ category -> Bool in
                    return category.id == "611" || category.id == "612"
                }).count > 0 {
                    if let parkingContent = parkingContet(entity: entity) {
                        content.append(contentsOf: parkingContent)
                    }
                }
            }
            
//            if let coordinates = entity.place?.address?.geoCoordinates {
//                
//                entityLocation = CLLocationCoordinate2D(latitude: coordinates.latitude ?? 0, longitude: coordinates.longitude ?? 0)
//                                                
//                self.drawRoute()
//            }
            
            nameLabel.text = entity.place?.name
            categoryLabel.isHidden = false
            categoryLabel.text = entity.place?.categories?.first?.name
        }
        
        if let distance = entity.formattedDistance {
            content.append( DetailViewDisplayModel(fieldName: "Distance", fieldValue: distance))
        } else if let distanceText = distanceText {
            content.append( DetailViewDisplayModel(fieldName: "Distance", fieldValue: distanceText))
        }
        
        if let prices = entity.facets?.priceInfo?.priceDetails {
            if prices.count > 0 {
                let pricesContent = pricesDetailsContent(prices: prices)
                content.append( pricesContent)
            }
            
        }
        
        if let connectors = entity.facets?.evConnectors?.connectors {
            let connectorsDetails = connectorsContent(connectors: connectors)
            content.append(connectorsDetails)
        }
        
        if let nearby = entity.facets?.nearby?.nearbyCategories {
            var text = ""
            for cat in nearby {
                if let catName = cat.category?.name {
                    text.append("\(catName)\n")
                }
            }
            let cell = DetailViewDisplayModel(fieldName: "Nearby Amenities", fieldValue: text)
            content.append(cell)
        }

        if let openHours = entity.facets?.openHours?.regularOpenHours {
                        
            var openHoursArr = [String]()
            
            for period in openHours {
                if let day = period.day, let timeFrom = period.openTime?.first?.timeFrom, let timeTo = period.openTime?.first?.timeTo {
                    
                    let openHoursStr = "\(timeFrom)-\(timeTo)"
                    let weekday = Calendar.current.weekdaySymbols[day - 1]
                    
                    let str = "\(weekday): \(openHoursStr)"
                    openHoursArr.append(str)
                }
            }
            
            if openHoursArr.count > 0 {
                let openHoursStr = openHoursArr.joined(separator: "\n")
                
                let openHoursCell = DetailViewDisplayModel(fieldName: "Open hours", fieldValue: openHoursStr)
                
                content.append(openHoursCell)
            }
        }
    
        tableView.reloadData()
        tableView.flashScrollIndicators()
    }
    
    private func connectorsContent(connectors: [TNEntityConnector]) -> DetailViewDisplayModel {
        
        let value = connectors.reduce("") { (result, connector) in
            if let number = connector.connectorNumber,
               let name = connector.connectorType?.name {
                
                let numberOfStations = String(format: NSLocalizedString("NumberOfStations", comment: ""), number)
                let text = "\(name) (\(numberOfStations))"
                if result.count > 0 {
                    return "\(result)\n\(text)"
                } else {
                    return "\(text)"
                }
            }
            return "\(result)"
        }
        return DetailViewDisplayModel(fieldName: "Connectors", fieldValue: value)
    }
    
    private func pricesDetailsContent(prices: [TNEntityPrice]) -> DetailViewDisplayModel {
        let value = prices.reduce("") { (result, price) in
            let priceStr = "\(price.symbol ?? "") \(String(format: "%.3f", price.amount ?? 0)) / \(price.unit ?? "gal")"
            let text = price.label != nil ? "\(price.label ?? ""): \(priceStr)" : priceStr
            if result.count > 0 {
                return "\(result)\n\(text)"
            } else {
                return "\(text)"
            }
        }
        return DetailViewDisplayModel(fieldName: "Prices", fieldValue: value)
    }
    
    private func parkingContet(entity: TNEntity) -> [DetailViewDisplayModel]?  {
        guard let parking = entity.facets?.parking else {
            return nil
        }
        var content = [DetailViewDisplayModel]()
        if let total = parking.spacesTotal {
            content.append(DetailViewDisplayModel(fieldName: "Spaces total", fieldValue: "\(total)"))
        }
        if let available = parking.spacesAvailable {
            content.append(DetailViewDisplayModel(fieldName: "Spaces available", fieldValue: "\(available)"))
        }
        if let calculatedRates = parking.pricing?.calculatedRates {
            let value = calculatedRates.reduce("") { (result, rate) in
                
                guard let amount = rate.amount else {
                    return result
                }
                var text = "\(rate.symbol ?? "") \(amount)"
                if let unit = rate.unit {
                    text = text.appending(" / \(unit) minutes")
                }
                if result.count > 0 {
                    return "\(result)\n\(text)"
                } else {
                    return "\(text)"
                }
            }
            content.append(DetailViewDisplayModel(fieldName: "Price", fieldValue: value))
        }

            var strRateCard = "";
            if let rateCards = parking.pricing?.rateCard?.text {
                for rateCard in rateCards {
                    strRateCard.append(rateCard)
                    strRateCard.append("\n")
                }
                content.append(DetailViewDisplayModel(fieldName: "Rate card", fieldValue: strRateCard))
            }
        
        return content
    }
}

extension DetailsView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: DetailViewCell = tableView.dequeueReusableCell(withIdentifier: "DetailViewCell", for: indexPath) as?  DetailViewCell else {
            return UITableViewCell()
        }
        
        cell.fillDetail(content[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func drawRoute() {
        
        removeUserStaticRoute()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let directionsRequest = MKDirections.Request()
            var placemarks = [MKMapItem]()
            for item in [self.currentLocation, self.entityLocation] {
                let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude), addressDictionary: nil )
                placemarks.append(MKMapItem(placemark: placemark))
            }
            directionsRequest.transportType = MKDirectionsTransportType.automobile
            
            for (k, item) in placemarks.enumerated() {
                if k < (placemarks.count - 1) {
                    directionsRequest.source = item
                    directionsRequest.destination = (placemarks[k+1])
                    let directions = MKDirections(request: directionsRequest)
                    
                    directions.calculate { (res, err) in
                        if err == nil {
                            let route = res?.routes[0]
                            
                            if let polilyne = route?.polyline {
                                
                                DispatchQueue.main.async {
                                    self.zoom(to: polilyne, animated: true)
                                    
                                    self.mapView.addOverlays([polilyne])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let ann1 = MKPointAnnotation()
        ann1.coordinate = currentLocation
        let ann2 = MKPointAnnotation()
        ann2.coordinate = entityLocation

        mapView.addAnnotations([ann1, ann2])
    }
    
    func removeUserStaticRoute() {
        
        for overlay in mapView.overlays {
            
            if let ov = overlay as? MKPolyline {
                mapView.removeOverlay(ov)
            }
        }
        
        mapView.removeAnnotations(mapView.annotations)
    }
    
    func zoom(to polyLine: MKPolyline, animated: Bool) {
        self.mapView.setVisibleMapRect(polyLine.boundingMapRect, edgePadding: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15), animated: true)
    }
}

extension DetailsView: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        
        polylineRenderer.strokeColor = UIColor.link
        polylineRenderer.lineWidth = 3
        
        return polylineRenderer
    }
}
