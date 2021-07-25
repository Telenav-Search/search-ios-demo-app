//
//  MapViewController+DirectionSDK.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 24.06.2021.
//

import UIKit
import MapKit
import VividNavigationSDK
import TelenavEntitySDK

extension MapViewController {
    
    func routeSettingsButton(setHidden isHidden: Bool) {
        routeSettingsButton.layer.cornerRadius = 4
        routeSettingsButton.layer.borderWidth = 1
        routeSettingsButton.layer.borderColor = UIColor.systemBlue.cgColor
        routeSettingsButton.isHidden = isHidden
    }
    
    @IBAction func onRouteSettings(_ sender: Any) {
        let detailsController = DirectionDetailsViewController(nibName: "DirectionDetailsViewController", bundle: .main)
        navigationController?.pushViewController(detailsController, animated: true)
    }
    
    func handleDetailsViewRouteButtons() {
        detailsView.fromThisPointButton.addTarget(self, action: #selector(onDetailsViewFromButton), for: .touchUpInside)
        detailsView.toThisPointButton.addTarget(self, action: #selector(onDetailsViewToButton), for: .touchUpInside)
        detailsView.viaThisPointButton.addTarget(self, action: #selector(onDetailsViewViaButton), for: .touchUpInside)
    }
    
    func coordinatesFromDetailView() -> CLLocationCoordinate2D? {
        if let point = detailsView.entity?.place?.address?.navCoordinates,
           let lat = point.latitude, let lon = point.longitude {
            return CLLocationCoordinate2D(latitude:lat,
                                          longitude:lon)
        }
        return nil
    }
    
    @objc func onDetailsViewFromButton() {
        if let coordinate = coordinatesFromDetailView() {
            let annotation = RouteCreationAnnotation(coordinate: coordinate)
            addFromPoint(annotation: annotation,
                         message: messageForCoordinate(coordinate: coordinate))
        }
    }
    
    @objc func onDetailsViewToButton() {
        if let coordinate = coordinatesFromDetailView() {
            let annotation = RouteCreationAnnotation(coordinate: coordinate)
            addToPoint(annotation: annotation,
                       message: messageForCoordinate(coordinate: coordinate))
        }
    }
    
    @objc func onDetailsViewViaButton() {
        if let coordinate = coordinatesFromDetailView() {
            let annotation = RouteCreationAnnotation(coordinate: coordinate)
            addWayPoint(annotation: annotation,
                       message: messageForCoordinate(coordinate: coordinate))
        }
    }
    
    func addLongTapGestureRecognizer () {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(addRoutePointAnnotation(longGesture:)))
        recognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(recognizer)
    }
    
    @objc func addRoutePointAnnotation(longGesture: UILongPressGestureRecognizer){
        let touchPoint = longGesture.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = RouteCreationAnnotation(coordinate: coordinate)
        showRouteOptionsAlert(withAnnotation: annotation)
    }
    
    func messageForCoordinate(coordinate: CLLocationCoordinate2D) -> String{
        return "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
    }
    
    func showRouteOptionsAlert(withAnnotation annotation: RouteCreationAnnotation) {
        let message = messageForCoordinate(coordinate: annotation.coordinate)
        let title = "Do you want to make a route?"
        createRouteActionSheet = UIAlertController(title: title,
                                   message: message,
                                   preferredStyle: .actionSheet)
        let fromAction = UIAlertAction(title: "From here",
                                       style: .default,
                                       handler: {
            [weak self] (action) in
                self?.addFromPoint(annotation: annotation, message: message)
            })
        createRouteActionSheet?.addAction(fromAction)
        let viaAction = UIAlertAction(title: "Add stop point",
                                     style: .default,
                                     handler: {
            [weak self] (action) in
                self?.addWayPoint(annotation: annotation, message: message)
        })
        createRouteActionSheet?.addAction(viaAction)
        let toAction = UIAlertAction(title: "To here",
                                     style: .default,
                                     handler: {
            [weak self] (action) in
                self?.addToPoint(annotation: annotation, message: message)
        })
        createRouteActionSheet?.addAction(toAction)
        createRouteActionSheet?.addAction(UIAlertAction(title: "Cancel",
                                                        style: .cancel))
        
        if let actionSheet = createRouteActionSheet,
           !actionSheet.isBeingPresented {
            present(actionSheet, animated: true)
        }
    }
    
    func addFromPoint(annotation: RouteCreationAnnotation, message: String) {
        if let oldFromAnnotation = routeFromAnnotation {
            mapView.removeAnnotation(oldFromAnnotation)
        }
        routeFromAnnotation = annotation
        annotation.title = "Route from this point"
        annotation.subtitle = message
        mapView.addAnnotation(annotation)
        createRouteIfPossible()
        createRouteActionSheet?.dismiss(animated: false, completion: nil)
    }
    
    func addWayPoint(annotation: RouteCreationAnnotation, message: String) {
        routeWayPointsAnnotations.append(annotation)
        annotation.title = "Route via this point"
        annotation.subtitle = message
        mapView.addAnnotation(annotation)
        mapView.reloadInputViews()
        createRouteIfPossible()
        createRouteActionSheet?.dismiss(animated: false, completion: nil)
    }
    
    func addToPoint(annotation: RouteCreationAnnotation, message: String) {
        if let oldToAnnotation = routeToAnnotation {
          mapView.removeAnnotation(oldToAnnotation)
        }
        routeToAnnotation = annotation
        annotation.title = "Route to this point"
        annotation.subtitle = message
        mapView.addAnnotation(annotation)
        mapView.reloadInputViews()
        createRouteIfPossible()
        createRouteActionSheet?.dismiss(animated: false, completion: nil)
    }
    
    enum AnnotationTag: Int {
        case from = -1
        case to = -2
    }
    
    func getRouteCreationAnnotationView(forAnnotation annotation: MKAnnotation) -> MKAnnotationView {
        
        let annotationView = MKPinAnnotationView(annotation:annotation,
                                                 reuseIdentifier:"RouteCreationAnnotation")

        let label = UILabel(frame: CGRect(x: 0, y: 40, width: 50, height: 20))
        label.textColor = .black
        annotationView.addSubview(label)
        
        annotationView.pinTintColor = MKPinAnnotationView.greenPinColor()
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        let deleteButton = UIButton(type: .close)
        if annotation === routeFromAnnotation {
            deleteButton.tag = AnnotationTag.from.rawValue
            label.text = "From"
        } else {
            if annotation === routeToAnnotation {
                deleteButton.tag = AnnotationTag.to.rawValue
                label.text = "To"
            } else {
                for i in 0..<routeWayPointsAnnotations.count {
                    if annotation === routeWayPointsAnnotations[i] {
                        deleteButton.tag = i
                        label.text = "Via \(i+1)"
                        annotationView.pinTintColor = MKPinAnnotationView.purplePinColor()
                    }
                }
            }
        }
        deleteButton.addTarget(self,
                               action: #selector(onDeleteRoutePoint(sender:)),
                               for: .touchUpInside)
        annotationView.rightCalloutAccessoryView = deleteButton
        return annotationView
    }
    
    @objc func onDeleteRoutePoint(sender: UIButton) {
        var annotationForRemoving: MKAnnotation? = nil
        switch sender.tag {
        case AnnotationTag.from.rawValue:
            annotationForRemoving = routeFromAnnotation
            routeFromAnnotation = nil
            removeRouteOverlay()
        case AnnotationTag.to.rawValue:
            annotationForRemoving = routeToAnnotation
            routeToAnnotation = nil
            removeRouteOverlay()
        default:
            let index = sender.tag
            if index >= 0 && index < routeWayPointsAnnotations.count {
                annotationForRemoving = routeWayPointsAnnotations[index]
                routeWayPointsAnnotations.remove(at: index)
                mapView.removeAnnotations(routeWayPointsAnnotations)
                mapView.addAnnotations(routeWayPointsAnnotations)
                createRouteIfPossible()
            }
        }
        if let annotation = annotationForRemoving {
            mapView.removeAnnotation(annotation)
        }
        routesScrollView.setRoutes(routes: [], withDelegate: self)
        routesScrollView.isHidden = true
        routeSettingsButton(setHidden: true)
    }
    
    func removeRouteOverlay () {
        if let overlay = routePolyline {
            mapView.removeOverlay(overlay)
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
                    self?.showRoutesScroll(routes: routes)
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
            let builder = VNRouteRequest.builder()
                            .setOrigin(origin)
                            .setDestination(destination)
            var waypoints = [VNGeoLocation]()
            for wpAnnotation in routeWayPointsAnnotations {
                let wpCoord = wpAnnotation.coordinate
                let waypoint = VNGeoLocation(latitude: wpCoord.latitude,
                                           longitude: wpCoord.longitude)
                waypoints.append(waypoint)
            }
            builder.setWayPoints(waypoints)
            builder.setRouteCount(4)
            return builder.build()
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
            self?.removeRouteOverlay()
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
                controller.routeSettingsButton(setHidden: false)
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
    
    func routePreview(_ preview: RoutePreview,
                      didTapInfoForRoute route: VNRoute?) {
        let controller = ManeuversViewController()
        let navController = UINavigationController(rootViewController: controller)
        
        present(navController, animated: true) {
            controller.showManeuvers(ofRoute: route)
        }
    }
}
