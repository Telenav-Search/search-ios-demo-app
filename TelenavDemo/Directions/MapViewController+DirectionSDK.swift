//
//  MapViewController+DirectionSDK.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 24.06.2021.
//

import UIKit
import MapKit
import VividDriveSessionSDK
import TelenavEntitySDK

extension MapViewController {

    func handleDetailsViewRouteButtons() {
        detailsView.fromThisPointButton.addTarget(self, action: #selector(onDetailsViewFromButton), for: .touchUpInside)
        detailsView.toThisPointButton.addTarget(self, action: #selector(onDetailsViewToButton), for: .touchUpInside)
        detailsView.viaThisPointButton.addTarget(self, action: #selector(onDetailsViewViaButton), for: .touchUpInside)
    }
    
    func coordinatesFromDetailView() -> CLLocationCoordinate2D? {
        if  let entity = detailsView.entity,
            let point = entity.place?.address?.navCoordinates,
            let lat = point.latitude, let lon = point.longitude {
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            entitiesWithCoordinates.updateValue(location, forKey: entity)
            return location
        }
        return nil
    }
    
    @objc func onDetailsViewFromButton() {
        if let coordinate = coordinatesFromDetailView(),
           let location = VNGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude) {
            addFromPoint(location: location, message: "")
        }
    }
    
    @objc func onDetailsViewToButton() {
        if let coordinate = coordinatesFromDetailView(),
           let location = VNGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude) {
            addToPoint(location: location, message: "")
        }
    }
    
    @objc func onDetailsViewViaButton() {
        if let coordinate = coordinatesFromDetailView(),
           let location = VNGeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude) {
            addWayPoint(location: location, message: "")
        }
    }
    
    func addLongTapGestureRecognizer () {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(addRoutePointAnnotation(longGesture:)))
        recognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(recognizer)
    }
    
    @objc func addRoutePointAnnotation(longGesture: UILongPressGestureRecognizer){
        let touchPoint = longGesture.location(in: mapView)
        let scale = UIScreen.main.scale
        let viewPoint = VNViewPoint(
            x: Float(touchPoint.x * scale), // in pixels
            y: Float(touchPoint.y * scale)  // in pixels
        )
        
        guard let geoPoint = mapView.cameraController().viewport(toWorld: viewPoint) else {
            print("GeoPoint is nil")
            return
        }
        
        showRouteOptionsAlert(withGeoPoint: geoPoint)
    }
    
    func messageForCoordinate(coordinate: VNGeoPoint) -> String{
        return "\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
    }
    
    func showRouteOptionsAlert(withGeoPoint geoPoint: VNGeoPoint/*withAnnotation annotation: RouteCreationAnnotation*/) {
        let message = messageForCoordinate(coordinate: geoPoint)
        let title = "Do you want to make a route?"
        createRouteActionSheet = UIAlertController(title: title,
                                                   message: message,
                                                   preferredStyle: .actionSheet)
        
        let fromAction = UIAlertAction(title: "From here", style: .default, handler: { [weak self] (action) in
            self?.addFromPoint(location: geoPoint, message: message)
        })
        createRouteActionSheet?.addAction(fromAction)
        
        let viaAction = UIAlertAction(title: "Add stop point", style: .default, handler: { [weak self] (action) in
            self?.addWayPoint(location: geoPoint, message: message)
        })
        createRouteActionSheet?.addAction(viaAction)
        
        let toAction = UIAlertAction(title: "To here", style: .default, handler: { [weak self] (action) in
            self?.addToPoint(location: geoPoint, message: message)
        })
        createRouteActionSheet?.addAction(toAction)
        
        let removePoints = UIAlertAction(title: "Remove all way points", style: .destructive, handler: { [weak self] (action) in
            self?.removeWayPoints()
        })
        createRouteActionSheet?.addAction(removePoints)
        
        createRouteActionSheet?.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let actionSheet = createRouteActionSheet, !actionSheet.isBeingPresented {
            present(actionSheet, animated: true)
        }
    }
    
    func addFromPoint(location: VNGeoPoint, message: String, entity: TNEntity? = nil) {
        let annotationController = mapView.annotationsController()
        let pushPinImage = UIImage(named: "map-push-pin-s")!
        
        if let annotation = fromAnnotation {
            annotationController.remove([annotation])
            fromAnnotation = nil
        }
        
        let fromAnnotation = annotationController.factory().create(
            with: pushPinImage,
            location: .init(latitude: location.latitude, longitude: location.longitude)
        )
        
        fromAnnotation.verticalOffset = -0.05
        fromAnnotation.style = .screenFlagNoCulling
        
        annotationController.add([fromAnnotation])
        fromLocation = location
        self.fromAnnotation = fromAnnotation
        
        createRouteIfPossible()
    }
    
    func addWayPoint(location: VNGeoPoint, message: String, entity: TNEntity? = nil) {
        let annotationController = mapView.annotationsController()
        let pushPinImage = UIImage(named: "map-push-pin-w")!
        
        let wayAnnotation = annotationController.factory().create(
            with: pushPinImage,
            location: .init(latitude: location.latitude, longitude: location.longitude)
        )
        
        wayAnnotation.verticalOffset = -0.05
        wayAnnotation.style = .screenFlagNoCulling
        
        annotationController.add([wayAnnotation])
        wayLocations.append(location)
        self.wayAnnotations.append(wayAnnotation)
        
        createRouteIfPossible()
    }
    
    func addToPoint(location: VNGeoPoint, message: String, entity: TNEntity? = nil) {
        let annotationController = mapView.annotationsController()
        let pushPinImage = UIImage(named: "map-push-pin-f")!
        
        if let annotation = toAnnotation {
            annotationController.remove([annotation])
            toAnnotation = nil
        }
        
        let finishAnnotation = annotationController.factory().create(
            with: pushPinImage,
            location: .init(latitude: location.latitude, longitude: location.longitude)
        )
        
        finishAnnotation.verticalOffset = -0.05
        finishAnnotation.style = .screenFlagNoCulling
        
        annotationController.add([finishAnnotation])
        toLocation = location
        self.toAnnotation = finishAnnotation
        
        createRouteIfPossible()
    }
    
    func removeWayPoints() {
        let annotationController = mapView.annotationsController()
        let routeController = mapView.routeController()
        
        var annotations = wayAnnotations
        if let toAnnotation = toAnnotation {
            annotations.append(toAnnotation)
            self.toAnnotation = nil
            self.toLocation = nil
        }
        if let fromAnnotation = fromAnnotation {
            annotations.append(fromAnnotation)
            self.fromAnnotation = nil
            self.fromLocation = nil
        }
        
        self.wayLocations = []
        self.wayAnnotations = []
        
        annotationController.remove(annotations)
        
        if !self.routeModels.isEmpty {
            let routeIds = self.routeModels.map { $0.getRouteId() }
            routeController.removeRoutes(routeIds)
            self.routeModels = []
        }
        
        routesScrollView.setRoutes(routes: [], withDelegate: self)
        hideRoutesScroll()
    }
    
    enum AnnotationTag: Int {
        case from = -1
        case to = -2
    }
    
    func createRouteIfPossible() {
        guard let request = createRouteRequest(settings: routeSettings) else {
            return
        }
        
        let client = VNDirectionClient.factory().build()
        let task = client?.createRouteCalculationTask(request)
        let activity = showActivityIndicator()
        task?.runAsync({ [weak self] response, error  in

            self?.entitiesWithCoordinates.removeAll()

            guard error == nil, let routes = response?.routes, routes.count > 0 else {
                self?.hideActivityIndicator(activity: activity)
                self?.showCalculationErrorAlert(error: error)
                return
            }
            self?.showRouteOnMainQueue(routes: routes)
            self?.showRoutesScroll(routes: routes)
            self?.hideActivityIndicator(activity: activity)
        })
    }
    
    func createRouteRequest(settings: RouteSettings) -> VNRouteRequest? {
        guard let startCoord = fromLocation, let endCoord = toLocation else {
            return nil
        }

        let origin = createGeolocation(with: startCoord)
        let destination = createGeolocation(with: endCoord)

        let requestBuilder = VNRouteRequest.builder().setOrigin(origin).setDestination(destination)
        
        var waypoints = [VNGeoLocation]()
        for wayLocation in /*routeWayPointsAnnotations*/wayLocations {
            // let wpCoord = wpAnnotation.coordinate
            let waypoint = createGeolocation(with: wayLocation)
            waypoints.append(waypoint)
        }
        requestBuilder.setWayPoints(waypoints)
        requestBuilder.setRouteCount(settings.routeCount)
        requestBuilder.setHeading(settings.heading)
        requestBuilder.setSpeed(settings.speedInMps)
        requestBuilder.setRouteStyle(settings.routeStyle)
        requestBuilder.setContentLevel(settings.contentLevel)
        if settings.startDate > Date() {
            requestBuilder.setStartTime(settings.startDate)
        }
        requestBuilder.setRoutePreference(settings.preferences)
        return requestBuilder.build()
    }

    func createGeolocation(with geoPoint: VNGeoPoint) -> VNGeoLocation {

        if let entity = entitiesWithCoordinates.first(where: {
            $1.longitude == geoPoint.longitude &&
            $1.latitude == geoPoint.latitude
        }) {
            let street = entity.key.place?.address?.street?.formattedName
            let crossStreet = entity.key.place?.address?.crossStreet?.formattedName
            let door = entity.key.place?.address?.houseNumber

            let address = VNAddress(
                street: street,
                crossStreet: crossStreet,
                door: door
            )

            return VNGeoLocation(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude,
                address: address
            )
        }
        return VNGeoLocation(
            latitude: geoPoint.latitude,
            longitude: geoPoint.longitude
        )
    }
    
    func showRoute(routes: [VNRoute]) {
        let routeModels = routes.enumerated().map { (index, element) in
            return VNMapRouteConverter.convert(element, routeId: "\(index)")
        }
        
        let routeController = mapView.routeController()
        
        // Remove previos routes
        if !self.routeModels.isEmpty {
            let routeIds = self.routeModels.map { $0.getRouteId() }
            routeController.removeRoutes(routeIds)
        }
        
        if !routeModels.isEmpty {
            routeController.addRoutes(routeModels)
            routeController.unhighlight()
            routeController.highlight(routeModels.first!.getRouteId())
            self.routeModels = routeModels
        }
        
        // show region that containts all routes.
        if !routeModels.isEmpty {
            let routeIds = self.routeModels.map { $0.getRouteId() }
            let cameraController = mapView.cameraController()
            let bounds = mapView.bounds
            let scale = UIScreen.main.scale
            
            let padding: CGFloat = 32.0
            
            cameraController.showRoutes(
                routeIds,
                toX: Int32(bounds.origin.x * scale) + Int32(padding * scale),
                toY: Int32(bounds.origin.y * scale) + Int32(padding * scale),
                width: UInt32(bounds.size.width * scale) - UInt32(padding * 2 * scale),
                height: UInt32(bounds.size.height * scale) - UInt32(padding * 2 * scale),
                gridAligned: true,
                showFullRouteOverview: true,
                includeCVP: false)
        }
    }
    
    func showRouteOnMainQueue(routes: [VNRoute]) {
        OperationQueue.main.addOperation { [weak self] in
            self?.showRoute(routes: routes)
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
                UIView.animate(withDuration: 0.5) { [weak controller] in
                    controller?.routeScrollHeightConstraint.constant = 90
                    controller?.view.layoutIfNeeded()
                }
                controller.routesScrollView.setRoutes(routes: routes,
                                                      withDelegate: controller)
                controller.routesScrollView.selectFirstRoute()
            }
        }
    }
    
    func hideRoutesScroll() {
        OperationQueue.main.addOperation { [weak self] in
            if let controller = self {
                UIView.animate(withDuration: 0.5) { [weak controller] in
                    controller?.routeScrollHeightConstraint.constant = 0
                    controller?.view.layoutIfNeeded()
                }
            }
        }
    }
}

extension MapViewController: RoutePreviewDelegate {
    func routePreview(_ preview: RoutePreview, didSelectedRouteIndex index: Int) {
        let model = routeModels[index]
        let routeController = mapView.routeController()
        
        routeController.unhighlight()
        routeController.highlight(model.getRouteId())
    }
    
    func routePreview(_ preview: RoutePreview, didSelectedRoute route: VNRoute?) {
    }
    
    func routePreview(_ preview: RoutePreview, didTapInfoForRoute route: VNRoute?) {
        let controller = ManeuversViewController()
        let navController = UINavigationController(rootViewController: controller)
        
        present(navController, animated: true) {
            controller.showManeuvers(ofRoute: route)
        }
    }
}


extension MapViewController: DirectionDetailsViewControllerDelegate {
    
    @IBAction func onRouteSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailsController = storyboard
            .instantiateViewController(withIdentifier: "DirectionDetailsViewController")
            as? DirectionDetailsViewController {
            detailsController.delegate = self
            detailsController.routeSettings = routeSettings
            navigationController?.pushViewController(detailsController,
                                                     animated: true)
        }
    }
    
    // MARK: -  DirectionDetailsViewControllerDelegate
    
    func onBackButtonOfDirectionDetails(_ viewController: DirectionDetailsViewController) {
        navigationController?.popViewController(animated: true)
    }
    
    func directionDetails(_ viewController: DirectionDetailsViewController,
                          didUpdateSettings settings: RouteSettings)
    {
        routeSettings = settings
        createRouteIfPossible()
        viewController.onBack(self)
    }
    
    func isRouteCalculated() -> Bool {
        return !routeModels.isEmpty
    }
}
