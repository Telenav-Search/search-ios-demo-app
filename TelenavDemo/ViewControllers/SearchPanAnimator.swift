//
//  SearchPanAnimator.swift
//  TelenavDemo
//
//  Created by ezaderiy on 17.12.2020.
//

import UIKit

class SearchPanAnimator: NSObject {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    var maxHeight: CGFloat = 800
    var middleHeight: CGFloat = 400
    var bottomMin: CGFloat = 0.0
    
    var tmpStart: CGFloat = 0.0
    var tmpHeight: CGFloat = 0.0
  
    @objc func didDragMainView(_ sender: UIPanGestureRecognizer) {
        
        let point: CGPoint = sender.translation(in: self.view.superview)
        
        if sender.state == .began {
            tmpStart = bottomConstraint.constant
            tmpHeight = heightConstraint.constant
        } else if sender.state == .changed {
            var newBottom = tmpStart - point.y
            var newHeight = newBottom + tmpHeight
            
            if newBottom > 0 { // extending
                newBottom = 0
            }
            if newBottom < bottomMin { // constraining
                newBottom = bottomMin
            }
            if newHeight < middleHeight {
                newHeight = middleHeight
            }
            
            bottomConstraint.constant = newBottom
            heightConstraint.constant = newHeight
            
            view.layoutIfNeeded()
        } else if sender.state == .ended || sender.state == .cancelled {
            let velocity = sender.velocity(in: view)
            if velocity.y > 0 { // constrain
                if heightConstraint.constant > middleHeight {
                    heightConstraint.constant = middleHeight
                    bottomConstraint.constant = 0
                } else {
                    bottomConstraint.constant = bottomMin
                }
            } else { // expand
                if heightConstraint.constant > middleHeight {
                    heightConstraint.constant = maxHeight
                    bottomConstraint.constant = 0
                } else {
                    bottomConstraint.constant = 0
                }
            }
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 1,
                           options: .curveEaseInOut,
                           animations: {
                            
                            self.view.superview!.layoutIfNeeded()
                           },
                           completion: nil)
        }
        
     }
    
    
}
