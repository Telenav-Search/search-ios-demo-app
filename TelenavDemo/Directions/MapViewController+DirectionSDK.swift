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
        let title = "Do you want to make a route?"
        createRouteActionSheet = UIAlertController(title: title,
                                   message: message,
                                   preferredStyle: .actionSheet)
        let fromAction = UIAlertAction(title: "From here",
                                       style: .default,
                                       handler: {
            [weak self] (action) in
                if let oldFromAnnotation = self?.routeFromAnnotation {
                    self?.mapView.removeAnnotation(oldFromAnnotation)
                }
                self?.routeFromAnnotation = annotation
                annotation.title = "Route from this point"
                annotation.subtitle = message
                self?.mapView.addAnnotation(annotation)
                self?.createRouteIfPossible()
                self?.createRouteActionSheet?.dismiss(animated: false, completion: nil)
            })
        createRouteActionSheet?.addAction(fromAction)
        let toAction = UIAlertAction(title: "To here",
                                     style: .default,
                                     handler: {
            [weak self] (action) in
                if let oldToAnnotation = self?.routeToAnnotation {
                  self?.mapView.removeAnnotation(oldToAnnotation)
                }
                self?.routeToAnnotation = annotation
                annotation.title = "Route to this point"
                annotation.subtitle = message
                self?.mapView.addAnnotation(annotation)
                self?.mapView.reloadInputViews()
                self?.createRouteIfPossible()
                self?.createRouteActionSheet?.dismiss(animated: false, completion: nil)
        })
        createRouteActionSheet?.addAction(toAction)
        createRouteActionSheet?.addAction(UIAlertAction(title: "Cancel",
                                                        style: .cancel))
        
        if let actionSheet = createRouteActionSheet,
           !actionSheet.isBeingPresented {
            present(actionSheet, animated: true)
        }
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
        if let request = createRouteRequest() {
            let client = VNDirectionClient.factory().build()
            let task = client?.createRouteCalculationTask(request)
            let activity = showActivityIndicator()
            task?.runAsync({ [weak self] response, error  in
                guard error == nil,
                      let routes = response?.routes,
                      routes.count > 0 else {
                    self?.hideActivityIndicator(activity: activity)
                    self?.showCalculationErrorAlert(error: error)
                    return
                }
                if let mainRoute = routes.first,
                   let coordinates = self?.generateCoordinates(forRoute: mainRoute) {
                    self?.showRoute(coordinates: coordinates)
                    self?.showRoutesScroll(routes: [mainRoute, mainRoute, mainRoute, mainRoute])
                }
                self?.hideActivityIndicator(activity: activity)
            })
        }
    }
    
    func createRouteRequest() -> VNRouteRequest? {
        if let startCoord = routeFromAnnotation?.coordinate,
           let endCoord = routeToAnnotation?.coordinate {
            let origin = VNGeoLocation(latitude: startCoord.latitude,
                                       longitude: startCoord.longitude)
            let destination = VNGeoLocation(latitude: endCoord.latitude,
                                       longitude: endCoord.longitude)
            return VNRouteRequest.builder()?
                .setOrigin(origin)
                .setDestination(destination)
                .build()
        }
        return nil
    }
    
    func generateCoordinates(forRoute route: VNRoute) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for leg in route.legs {
            for step in leg.steps {
                for edge in step.edges {
                    for point in edge.geometry {
                        coordinates.append(point.coordinate)
                    }
                }
            }
        }
        return coordinates
    }
    
    func showRoute(coordinates: [CLLocationCoordinate2D]) {
        OperationQueue.main.addOperation { [weak self] in
            let count = coordinates.count
            guard count >= 2 else {
                return
            }
            if let overlay = self?.routePolyline {
                self?.mapView.removeOverlay(overlay)
            }
            self?.routePolyline = MKPolyline(coordinates: coordinates,
                                             count: count)
            if let overlay = self?.routePolyline {
                self?.mapView.addOverlay(overlay)
            }
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
    
    func showCalculationErrorAlert(error: Error?) {
        OperationQueue.main.addOperation { [weak self] in
            let message = error?.localizedDescription ?? "No routes"
            let title = "An error occured while route calculating"
            let ac = UIAlertController(title: title,
                                       message: message,
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Close", style: .cancel))
            self?.present(ac, animated: true)
        }
    }
    
    func showRoutesScroll(routes: [VNRoute]) {
        OperationQueue.main.addOperation { [weak self] in
            if let controller = self {
                controller.routesScrollView.isHidden = false
                controller.routesScrollView.setRoutes(routes: routes,
                                                      withDelegate: controller)
                controller.routesScrollView.selectFirstRoute()
            }
        }
    }
    
    func didSelectRoute(route: VNRoute) {
        let coordinates = generateCoordinates(forRoute: route)
        showRoute(coordinates: coordinates)
        searchVisible = false
    }
}

extension MapViewController: RoutePreviewDelegate {
    
    func routePreview(_ preview: RoutePreview, didSelectedRoute route: VNRoute?) {
        if let route = route {
            let coordinates = generateCoordinates(forRoute: route)
            showRoute(coordinates: coordinates)
        }
    }
    
    func routePreview(_ preview: RoutePreview, didTapInfoForRoute route: VNRoute?) {

        
    }
}
