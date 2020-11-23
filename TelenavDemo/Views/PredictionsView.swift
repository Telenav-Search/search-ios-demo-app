//
//  PredicationsView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 17.11.2020.
//

import UIKit
import TelenavEntitySDK

class PredictionsView: UIView {

    @IBOutlet var contentView: UIView!

    var content = [TelenavPredictionWordResult]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var selectedWordCallback: ((TelenavPredictionWordResult) -> Void)?
    
    @IBOutlet weak var collectionView: SelfSizedCollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "PredictionWordCell", bundle: nil), forCellWithReuseIdentifier: "PredictionWordCell")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed(String(describing: PredictionsView.self), owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.isUserInteractionEnabled = true
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

extension PredictionsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return content.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: PredictionWordCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PredictionWordCell", for: indexPath) as? PredictionWordCell else {
            return UICollectionViewCell()
        }
        
        cell.fillPrediction(word: content[indexPath.row])
        
        return cell
    }
}

extension PredictionsView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = content[indexPath.item]
        
        selectedWordCallback?(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let word = content[indexPath.row].predictWord else {
            return CGSize.zero
        }
        
        let itemWidth = word.size(withAttributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]).width
        
        let insets: CGFloat = 20
        
        return CGSize(width: itemWidth + insets, height: collectionView.frame.height)
    }
}
