//
//  TelenavMapSettingsViewController.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit
import VividMapSDK

class TelenavMapDiagnosisViewController: UIViewController, Storyboardable {
    
    @IBOutlet var textView: UITextView!
    var mapViewState: VNMapViewState?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mapViewState = mapViewState else {
            textView.text = "The Map Diagnosis isn't available. Need to activate \"Listen to the map data\" in map settings."
            return
        }
        
        showMapViewState(mapViewState)
    }
    
    private func showMapViewState(_ mapViewState: VNMapViewState) {
        var state = ""
        
        state += "camera latitude = \(mapViewState.cameraLatitude)\n"
        state += "camera longitude = \(mapViewState.cameraLongitude)\n"
        state += "camera LAD = \(mapViewState.cameraLAD)\n"
        state += "camera heading = \(mapViewState.cameraHeading)\n"
        state += "camera height = \(mapViewState.cameraHeight)\n"
        state += "camera field of view = \(mapViewState.cameraFieldOfView)\n"
        state += "camera declination = \(mapViewState.cameraDeclination)\n"
        state += "camera screen width = \(mapViewState.cameraScreenWidth)\n"
        state += "camera screen height = \(mapViewState.cameraScreenHeight)\n"
        state += "camera horizontal FOV = \(mapViewState.cameraHorizontalFOV)\n"
        state += "camera vertical FOV = \(mapViewState.cameraVerticalFOV)\n"
        state += "camera eye distance = \(mapViewState.cameraEyeDistance)\n"
        state += "camera base tile size = \(mapViewState.cameraBaseTileSize)\n"
        state += "camera orientation = \(mapViewState.cameraOrientation.rawValue)\n"
        state += "---\n"
        state += "range horizontal = \(mapViewState.rangeHorizontal)\n"
        state += "car latitude = \(mapViewState.carLatitude)\n"
        state += "car longitude = \(mapViewState.carLongitude)\n"
        state += "car heading = \(mapViewState.carHeading)\n"
        state += "zoom level = \(mapViewState.zoomLevel)\n"
        state += "data zoom level = \(mapViewState.dataZoomLevel)\n"
        state += "---\n"
        state += "interaction mode = \(mapViewState.interactionMode.rawValue)\n"
        state += "render mode = \(mapViewState.renderMode.rawValue)\n"
        state += "isAnimating = \(mapViewState.isAnimating)\n"
        state += "isAutoZoomAnimationRunning = \(mapViewState.isAutoZoomAnimationRunning)\n"
        state += "---\n"
        state += "tiles on screen = \(mapViewState.tilesOnScreen)\n"
        state += "tiles with edges loaded = \(mapViewState.tilesWithEdgesLoaded)\n"
        state += "tiles with polygons loaded = \(mapViewState.tilesWithPolygonsLoaded)\n"
        state += "tiles with text loaded = \(mapViewState.tilesWithTextLoaded)\n"
        state += "tiles with annotations loaded = \(mapViewState.tilesWithAnnotationsLoaded)\n"
        state += "tiles with landmarks loaded = \(mapViewState.tilesWithLandmarksLoaded)\n"
        state += "tiles with traffic loaded = \(mapViewState.tilesWithTrafficLoaded)\n"
        state += "---\n"
        state += "total GPU footprint = \(mapViewState.totalGPUFootprint)\n"
        state += "total GPU texture footprint = \(mapViewState.totalGPUTextureFootprint)\n"
        state += "total GPU Vbo footprint = \(mapViewState.totalGPUVboFootprint)\n"
        state += "total GPU Ibo footprint = \(mapViewState.totalGPUIboFootprint)\n"
        state += "total GPU Vbo count = \(mapViewState.totalGPUVboCount)\n"
        state += "total GPU Ibo count = \(mapViewState.totalGPUIboCount)\n"
        state += "---\n"
        state += "updated = \(mapViewState.updated)\n"
        state += "optimal tile set loaded = \(mapViewState.optimalTileSetLoaded)\n"
        
        textView.text = state
    }
}