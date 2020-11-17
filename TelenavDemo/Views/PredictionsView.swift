//
//  PredicationsView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 17.11.2020.
//

import UIKit
import TelenavSDK

class PredictionsView: UIView {

    var content = [TelenavPredictionWordResult]()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "PredictionWordCell", bundle: nil), forCellWithReuseIdentifier: "PredictionWordCell")
        }
    }
}

extension PredictionsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: PredictionWordCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PredictionWordCell", for: indexPath) as? PredictionWordCell else {
            return
        }
        
        
    }
}

extension PredictionsView: UICollectionViewDelegate {
    
}
