//
//  MapViewController+DirectionSDK.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 24.06.2021.
//

import UIKit
import MapKit

extension MapViewController {
    
    
    func addLongTapGestureRecognizer () {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(addRoutePointAnnotation(longGesture:)))
        recognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(recognizer)
    }
    
    @objc func addRoutePointAnnotation(longGesture: UILongPressGestureRecognizer){
        let touchPoint = longGesture.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = RouteCreationAnnotation(coordinate: coordinate)
        showRouteOptionsAlert(withAnnotation: annotation)
    }
    
    func showRouteOptionsAlert(withAnnotation annotation: RouteCreationAnnotation) {
        let message = "\(String(format: "%.4f", annotation.coordinate.latitude)), \(String(format: "%.4f", annotation.coordinate.longitude))"
        let ac = UIAlertController(title: "Do you want to make a route?",
                                   message: message,
                                   preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "From here",
                                   style: .default,
                                   handler: { [weak self] (action) in
                                    if let oldFromAnnotation = self?.routeFromAnnotation {
                                        self?.mapView.removeAnnotation(oldFromAnnotation)
                                    }
                                    self?.routeFromAnnotation = annotation
                                    annotation.title = "Route from this point"
                                    annotation.subtitle = message
                                    self?.mapView.addAnnotation(annotation)
        }))
        ac.addAction(UIAlertAction(title: "To here",
                                   style: .default,
                                   handler: { [weak self] (action) in
                                    if let oldToAnnotation = self?.routeToAnnotation {
                                        self?.mapView.removeAnnotation(oldToAnnotation)
                                    }
                                    self?.routeToAnnotation = annotation
                                    annotation.title = "Route to this point"
                                    annotation.subtitle = message
                                    self?.mapView.addAnnotation(annotation)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func getRouteCreationAnnotationView(forAnnotation annotation: MKAnnotation) -> MKAnnotationView {
        
        let annotationView = MKPinAnnotationView(annotation:annotation,
                                                 reuseIdentifier:"RouteCreationAnnotation")

        let label = UILabel(frame: CGRect(x: 0, y: 40, width: 50, height: 20))
        label.textColor = .black
        label.text = annotation === routeFromAnnotation ? "From" : "To"
        annotationView.addSubview(label)
        
        annotationView.pinTintColor = MKPinAnnotationView.greenPinColor()
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        let deleteButton = UIButton(type: .close)
        deleteButton.tag = annotation === routeFromAnnotation ? 0 : 1
        deleteButton.addTarget(self,
                               action: #selector(onDeleteRoutePoint(sender:)),
                               for: .touchUpInside)
        annotationView.rightCalloutAccessoryView = deleteButton
        return annotationView
    }
    
    @objc func onDeleteRoutePoint(sender: UIButton) {
        var annotationForRemoving: MKAnnotation? = nil
        if sender.tag == 0 {
            annotationForRemoving = routeFromAnnotation
            routeFromAnnotation = nil
        } else {
            annotationForRemoving = routeToAnnotation
            routeToAnnotation = nil
        }
        if let annotation = annotationForRemoving {
            mapView.removeAnnotation(annotation)
        }
    }
}
