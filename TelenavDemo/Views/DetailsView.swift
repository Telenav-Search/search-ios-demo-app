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
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UINib(nibName: "DetailViewCell", bundle: nil), forCellReuseIdentifier: "DetailViewCell")
        }
    }
    
    var content = [DetailViewDisplayModel]()
    
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
    }
    
    private var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.78274, longitude: -122.43152)
    private var entityLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    func fillEntity(_ entity: TNEntity, currentCoordinate: CLLocationCoordinate2D) {
        
        self.currentLocation = currentCoordinate
        
        switch entity.type {
        case .address:
            break
        case .place:
            
            content = [
                DetailViewDisplayModel(fieldName: "Name", fieldValue: entity.place?.name ?? ""),
                DetailViewDisplayModel(fieldName: "Address", fieldValue: entity.place?.address?.addressLines?.joined(separator: "\n") ?? ""),
                DetailViewDisplayModel(fieldName: "Website", fieldValue: entity.place?.websites?.joined(separator: "\n") ?? ""),
                DetailViewDisplayModel(fieldName: "Phone numbers", fieldValue: entity.place?.phoneNumbers?.joined(separator: "\n") ?? "")
            ]
            
            if let distance = entity.formattedDistance {
                content.append( DetailViewDisplayModel(fieldName: "Distance", fieldValue: distance))
            }
            
            if let coordinates = entity.place?.address?.geoCoordinates {
                
                entityLocation = CLLocationCoordinate2D(latitude: coordinates.latitude ?? 0, longitude: coordinates.longitude ?? 0)
                                
                let pl = MKPolyline(coordinates: [currentLocation, entityLocation], count: 2)
                
                self.showUserStaticRoute([pl])
            }
            
            tableView.reloadData()
            
        case .none:
            break
        }
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
    
    func showUserStaticRoute(_ polilynes: [MKOverlay]) {
        
        removeUserStaticRoute()
        
        if polilynes.count == 0 {
            return
        }
        
        if let polilyne = polilynes.first {
            zoom(to: polilyne as! MKPolyline, animated: true)
        }
        
        let ann1 = MKPointAnnotation()
        ann1.coordinate = currentLocation
        let ann2 = MKPointAnnotation()
        ann2.coordinate = entityLocation

        mapView.addAnnotations([ann1, ann2])
        mapView.addOverlays(polilynes)
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
        
        polylineRenderer.strokeColor = UIColor.blue
        polylineRenderer.lineWidth = 3
        
        return polylineRenderer
    }
}
