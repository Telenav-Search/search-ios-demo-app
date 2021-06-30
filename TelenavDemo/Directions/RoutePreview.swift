//
//  RoutePreview.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 30.06.2021.
//

import Foundation
import UIKit
import VividNavigationSDK

protocol RoutePreviewDelegate: AnyObject {
    func routePreview(_ preview: RoutePreview, didSelectedRoute route: VNRoute?)
    func routePreview(_ preview: RoutePreview, didTapInfoForRoute route: VNRoute?)
}

class RoutePreview: UIView {
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
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
        preview.layer.cornerRadius = 5;
        preview.layer.masksToBounds = true;
        preview.updateSelectionColor()
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
            let kilometers = String(format: "%.3f", (route?.length ?? 0)/1000)
            distanceLabel.text = "\(kilometers) km"
            let hours = String(format: "%.1f", (route?.duration ?? 0)/60/60)
            durationLabel.text = "\(hours) h"
        }
    }
    
    func updateSelectionColor() {
        if isSelected {
            backgroundColor = UIColor(red: 0, green: 0, blue: 20, alpha: 0.2)
        } else {
            backgroundColor = .white
        }
        setNeedsLayout()
        setNeedsDisplay()
    }
}
