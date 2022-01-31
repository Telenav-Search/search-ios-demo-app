//
//  RoutePreview.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 30.06.2021.
//

import Foundation
import UIKit
import VividDriveSessionSDK

protocol RoutePreviewDelegate: AnyObject {
    func routePreview(_ preview: RoutePreview, didSelectedRoute route: VNRoute?)
    func routePreview(_ preview: RoutePreview, didTapInfoForRoute route: VNRoute?)
    func routePreview(_ preview: RoutePreview, didSelectedRouteIndex index: Int)
}

class RoutePreview: UIView {
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    public var index = -1
    
    internal var isSelected = false {
        didSet {
            updateSelectionColor()
        }
    }
    
    weak var delegate: RoutePreviewDelegate?
    
    class func instanceFromNib() -> RoutePreview {
        let preview = UINib(nibName: "RoutePreview",
                            bundle: nil)
            .instantiate(withOwner: nil,
                         options: nil)[0] as! RoutePreview
        preview.updateSelectionColor()
        preview.durationLabel.accessibilityIdentifier = "routePreviewDurationLabel"
        preview.distanceLabel.accessibilityIdentifier = "routePreviewDistanceLabel"
        return preview
    }
    
    
    @IBAction func onPreview(_ sender: Any) {
        delegate?.routePreview(self, didSelectedRoute: route)
    }
    
    @IBAction func onInfoButton(_ sender: Any) {
        delegate?.routePreview(self, didTapInfoForRoute: route)
    }
    
    var route: VNRoute? {
        didSet {
            distanceLabel.text = RouteSettings.distanceLabel(
                format: "%.3f %@",
                lengthInMeters: route?.length ?? 0)
            let hours = String(format: "%.2f", (route?.duration ?? 0)/60/60)
            durationLabel.text = "\(hours) h"
        }
    }
    
    func updateSelectionColor() {
        if isSelected {
            backgroundColor = UIColor(red: 0.640, green: 0.919, blue: 0.787, alpha: 0.6)
        } else {
            backgroundColor = .white
        }
        setNeedsLayout()
        setNeedsDisplay()
    }
}
