//
//  PlaceAnnotationView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 16.11.2020.
//

import UIKit
import MapKit

class PlaceAnnotationView: MKAnnotationView {
    private let annotationFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
        private let label: UILabel
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        self.label = UILabel(frame: annotationFrame.offsetBy(dx: 0, dy: 0))
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = annotationFrame
        self.label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        self.label.textColor = .darkGray
        self.label.textAlignment = .center
        
        self.backgroundColor = .clear
        self.addSubview(label)

    }
    
    var annotationColor: UIColor = .white
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                annotationColor = UIColor(red: 255 / 256, green: 92 / 256, blue: 71 / 256, alpha: 1)
            } else {
                annotationColor = .white
            }
            
            self.setNeedsDisplay()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }
    
    public var number: Int = 0 {
        didSet {
            self.label.text = String(number)
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // make circle rect 5 px from border
        var circleRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        circleRect = circleRect.insetBy(dx: 5, dy: 5)
    
        // set stroking color and draw circle
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.strokeEllipse(in: circleRect)
        
        context.setFillColor(annotationColor.cgColor)
        context.fillEllipse(in: circleRect)
    }
}
