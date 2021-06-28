//
//  MapViewController+DirectionSDK.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 24.06.2021.
//

import UIKit
import MapKit
import VividNavigationSDK


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
                                    self?.createRouteIfPossible()
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
                                    self?.createRouteIfPossible()
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
    
    func createRouteIfPossible() {
        if routeFromAnnotation != nil && routeToAnnotation != nil {
            createRoute()
        }
    }
    
    func createRoute() {
        if let startCoord = routeFromAnnotation?.coordinate,
           let endCoord = routeToAnnotation?.coordinate {
            let origin = VNGeoLocation(latitude: startCoord.latitude,
                                       longitude: startCoord.longitude)
            let destination = VNGeoLocation(latitude: endCoord.latitude,
                                       longitude: endCoord.longitude)
            let request = VNRouteRequest.builder()?
                .setOrigin(origin)
                .setDestination(destination)
                .build()
            let service = VNSDK.sharedInstance.sharedDirectionService()
            let task = service?.createRouteCalculationTask(request, mode: true)
            let activity = showActivityIndicator()
            task?.runAsync({ [weak self] rslt, error  in
                self?.hideActivityIndicator(activity: activity)
                if let error = error {
                    self?.showErrorAlert(error: error)
                    return
                }
                print("<|" + (rslt?.serializeToString())! ?? "" + "|>")
                let routes = rslt?.routes ?? Array()
                
                let legs  = (routes.last?.legs)!
                
                let steps = (legs.last?.steps)!
                
                let edges = (steps.last?.edges)!

            })
        }
    }
    
    func showActivityIndicator() -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView(style: .large)
        activity.frame = mapView.bounds
        mapView.addSubview(activity)
        activity.startAnimating()
        return activity
    }
    
    func hideActivityIndicator(activity: UIActivityIndicatorView) {
        OperationQueue.main.addOperation {
            activity.removeFromSuperview()
        }
    }
    
    func showErrorAlert(error: Error) {
        OperationQueue.main.addOperation { [weak self] in
            let ac = UIAlertController(title: "An error occured while route calculating",
                                       message: error.localizedDescription,
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Close", style: .cancel))
            self?.present(ac, animated: true)
        }
    }
}
