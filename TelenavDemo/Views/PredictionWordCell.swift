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
        
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    func setupView() {
        predictionLabel.accessibilityIdentifier = "predictionWordCellPredictionLabel"
    }
    
    func fillPrediction(word: TNWordPrediction) {
        self.predictionLabel.text = word.predictWord
    }
}
