//
//  RoutesScrollView.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 30.06.2021.
//

import Foundation
import UIKit
import VividNavigationSDK

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
    
    func setRoutes(routes: [VNRoute]) {
        removeAllRoutes()
        for route in routes {
            let preview = RoutePreview.instanceFromNib()
            routePreviews.append(preview)
            previewsContentView?.addSubview(preview)
            preview.route = route
        }
        setNeedsDisplay()
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor(white: 1, alpha: 0.4)
        let space = 10
        let width = 140
        var x = space
        for preview in routePreviews {
            preview.frame = CGRect(x: x, y: 2*space,
                                   width: width,
                                   height: Int(bounds.height)-3*space)
            x = x + width + 2*space
        }
        let rect = CGRect(x: 0, y: 0, width: x, height: Int(bounds.height))
        previewsContentView?.frame = rect
        contentSize = rect.size
    }
}
