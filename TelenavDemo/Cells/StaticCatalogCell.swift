//
//  StaticCatalogCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavEntitySDK

class StaticCatalogCell: UITableViewCell {

    @IBOutlet weak var mainImgView: UIImageView!
    
    @IBOutlet weak var catTitleLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    func setupView() {
        mainImgView.accessibilityIdentifier = "staticCatalogCellMainImgView"
        catTitleLabel.accessibilityIdentifier = "staticCatalogCellCatTitleLabel"
    }
    
    func fillStaticCategoryItem(_ item: StaticCategoryCellItem) {
        
        switch item.cellType {
        case .categoryItem:
            
            let cat = item as! StaticCategoryDisplayModel
            
            if let catalogImg = cat.staticCategory.img {
                mainImgView.image = UIImage(named: catalogImg)
                mainImgView.tintColor = .label
            }
            
            catTitleLabel.text = cat.staticCategory.name
            
        case .moreItem:
            catTitleLabel.text = "More"
            mainImgView.image = UIImage(named: "ic_more")
            mainImgView.tintColor = .label
        }
        
    }
}
