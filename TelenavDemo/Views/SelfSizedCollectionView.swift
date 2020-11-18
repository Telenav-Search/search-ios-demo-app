//
//  SelfSizedCollectionView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 18.11.2020.
//

import Foundation
import UIKit

class SelfSizedCollectionView: UICollectionView {

    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        
        var size = super.contentSize
        if size.width == 0 || size.height == 0 {
            // return a default size
            size = CGSize(width: superview?.frame.width ?? 375, height: 44)
        }
        
        return size
    }
  
    override func reloadData() {
        super.reloadData()
        self.layoutIfNeeded()
        self.invalidateIntrinsicContentSize()
    }
}
