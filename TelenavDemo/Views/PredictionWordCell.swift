//
//  PredictionWordCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 17.11.2020.
//

import UIKit
import TelenavEntitySDK

class PredictionWordCell: UICollectionViewCell {

    @IBOutlet weak var predictionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func fillPrediction(word: TNWordPrediction) {
        self.predictionLabel.text = word.predictWord
    }
}
