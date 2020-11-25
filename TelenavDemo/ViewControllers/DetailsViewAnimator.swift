//
//  DetailsViewAnimator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 25.11.2020.
//

import UIKit

enum DetailsViewPosition {
    
    case collapsed
    case standard
    case extended
}

let kCollapsedDetailViewBottomConstrainValue: CGFloat = -344
let kStandrdDetailViewBottomConstrainValue: CGFloat   = -235
let kExtendedDetailViewBottomConstrainValue: CGFloat  = 0

class DetailsViewAnimator: NSObject {

    @IBOutlet weak var detailsView: DetailsView!
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! {
        didSet {
            self.initialBottomConstraintValue = bottomConstraint.constant
        }
    }
    @IBOutlet weak var dtailsViewHeightConstraint: NSLayoutConstraint!
    
    var initialBottomConstraintValue: CGFloat!
    
    var detailsViewPosition: DetailsViewPosition?
    
    @objc func didDragDetailsView(_ sender: UIPanGestureRecognizer) {
        
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
                
                if newHeight < kExtendedDetailViewBottomConstrainValue && newHeight > kStandrdDetailViewBottomConstrainValue && velocity.y < 0 {
                    moveDetailsCard(toPosition: kExtendedDetailViewBottomConstrainValue)
                    self.detailsViewPosition = .extended
                }
                else if velocity.y > 0 {
                    moveDetailsCard(toPosition: kStandrdDetailViewBottomConstrainValue)
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
