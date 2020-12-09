//
//  DetailsViewAnimator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 25.11.2020.
//

import UIKit

enum PanViewPosition {
    
    case standard
    case extended
}

let kExtendedDetailViewBottomConstrainValue: CGFloat  = 0

class PanViewAnimator: NSObject {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! {
        didSet {
            self.initialBottomConstraintValue = bottomConstraint.constant
        }
    }
    @IBOutlet weak var dtailsViewHeightConstraint: NSLayoutConstraint! {
        didSet {
            dtailsViewHeightConstraint.constant = UIScreen.main.bounds.height * 1.85/3
            
            standrdDetailViewBottomConstrainValue = 260 - dtailsViewHeightConstraint.constant
            self.initialBottomConstraintValue = standrdDetailViewBottomConstrainValue
        }
    }
    
    var standrdDetailViewBottomConstrainValue: CGFloat   = -235

    var initialBottomConstraintValue: CGFloat!
    
    var detailsViewPosition: PanViewPosition?
    
    @objc func didDragMainView(_ sender: UIPanGestureRecognizer) {
        
            let point: CGPoint = sender.translation(in: self.view)
            
            sender.setTranslation(CGPoint.zero, in: self.view)
            
            if  sender.state == .changed {
                
                let velocity = sender.velocity(in: view)
                
                if velocity.y != 0 {
                    
                    let newHeight = (bottomConstraint.constant - point.y)
                    
                    if newHeight > initialBottomConstraintValue && newHeight < kExtendedDetailViewBottomConstrainValue {
                        
                        moveDetailsCard(toPosition: newHeight)
                    }
                }
            }
                
            else if sender.state == .ended || sender.state == .cancelled {
                
                let newHeight = bottomConstraint.constant - point.y
                
                let velocity = sender.velocity(in: view)
                
                if newHeight < kExtendedDetailViewBottomConstrainValue && newHeight > standrdDetailViewBottomConstrainValue && velocity.y < 0 {
                    moveDetailsCard(toPosition: kExtendedDetailViewBottomConstrainValue)
                    self.detailsViewPosition = .extended
                }
                else if velocity.y > 0 {
                    moveDetailsCard(toPosition: standrdDetailViewBottomConstrainValue)
                    self.detailsViewPosition = .standard
            }
        }
    }

    func moveDetailsCard(toPosition newHeigth: CGFloat) {
        
        bottomConstraint.constant = newHeigth
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1,
                       options: .curveEaseInOut,
                       animations: {
                        
                        self.view.layoutIfNeeded()
                       },
                       completion: nil)
    }
}
