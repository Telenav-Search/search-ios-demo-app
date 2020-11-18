//
//  PredicationsView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 17.11.2020.
//

import UIKit

class PredictionsView: UIView {

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
}

extension PredictionsView

extension PredictionsView: UICollectionViewDelegate {
    
}
