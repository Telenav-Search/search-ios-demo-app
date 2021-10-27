//
//  RoutesScrollView.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 30.06.2021.
//

import Foundation
import UIKit
import VividDriveSessionSDK

class RoutesScrollView: UIScrollView {
    
    var routePreviews = [RoutePreview]()
    
    var previewsContentView: UIView? {
        return viewWithTag(1001)
    }
    
    func removeAllRoutes() {
        for preview in routePreviews {
            preview.removeFromSuperview()
        }
        routePreviews = []
    }
    
    weak var previewDelegate: RoutePreviewDelegate?
    
    func setRoutes(routes: [VNRoute], withDelegate previewDelegate: RoutePreviewDelegate) {
        removeAllRoutes()
        for (index, route) in routes.enumerated() {
            let preview = RoutePreview.instanceFromNib()
            routePreviews.append(preview)
            previewsContentView?.addSubview(preview)
            preview.route = route
            preview.index = index
            preview.delegate = self
            self.previewDelegate = previewDelegate
        }
        setNeedsDisplay()
        setNeedsLayout()
    }
    
    func selectFirstRoute () {
        if let preview = routePreviews.first {
            preview.isSelected = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor(white: 1, alpha: 0.7)
        let space = 15
        let width = 140
        var x = space
        for preview in routePreviews {
            preview.frame = CGRect(x: x, y: space,
                                   width: width,
                                   height: Int(bounds.height)-2*space)
            x = x + width + 2*space
        }
        let rect = CGRect(x: 0, y: 0, width: x, height: Int(bounds.height))
        previewsContentView?.frame = rect
        contentSize = rect.size
    }
}

extension RoutesScrollView: RoutePreviewDelegate {
    func routePreview(_ preview: RoutePreview, didSelectedRouteIndex index: Int) {
        
    }
    
    func routePreview(_ selectedPreview: RoutePreview, didSelectedRoute route: VNRoute?) {
        for preview in routePreviews {
            preview.isSelected = false
        }
        selectedPreview.isSelected = true
        // previewDelegate?.routePreview(selectedPreview, didSelectedRoute: route)
        previewDelegate?.routePreview(selectedPreview, didSelectedRouteIndex: selectedPreview.index)
    }
    
    func routePreview(_ preview: RoutePreview, didTapInfoForRoute route: VNRoute?) {
       
        previewDelegate?.routePreview(preview, didTapInfoForRoute: route)
    }
}
