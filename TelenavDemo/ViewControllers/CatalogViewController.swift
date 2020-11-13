//
//  CatalogViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 30.10.2020.
//

import UIKit
import TelenavSDK

protocol CatalogViewControllerDelegate: SuggestionsDisplayManagerDelegate, StaticCategoriesDisplayManagerDelegate {
    func didSelectNode()
    func didReturnToMap()
}

class CatalogViewController: UIViewController  {

    var delegate: CatalogViewControllerDelegate?
    
    @IBOutlet var categoriesDisplayManager: CategoriesDisplayManager!
    
    @IBOutlet var suggestionsDisplayManager: SuggestionsDisplayManager! {
        didSet {
            suggestionsDisplayManager.delegate = self
        }
    }
    
    @IBOutlet var staticCategoriesDisplayManager: StaticCategoriesDisplayManager! {
        didSet {
            staticCategoriesDisplayManager.delegate = self
        }
    }
     
    override func viewDidLoad() {
        super.viewDidLoad()
        self.staticCategoriesDisplayManager.reloadTable()
    }

    func fillAllCategories(_ categories: [TelenavCategoryDisplayModel]) {
        self.categoriesDisplayManager.categories = categories
        self.categoriesDisplayManager.reloadTable()
    }
    
    func fillStaticCategories(_ categories: [TelenavStaticCategory]) {
        
        var catItems = [StaticCategoryCellItem]()
        
        for category in categories {
            let item = StaticCategoryDisplayModel(staticCategory: category)
            catItems.append(item)
        }
        
        catItems.append(StaticCategoryMoreItem())
        
        self.staticCategoriesDisplayManager.categories = catItems
    }
    
    func fillSuggestions(_ suggestions: [TelenavSuggestionResult]) {
        self.suggestionsDisplayManager.suggestions = suggestions
        self.suggestionsDisplayManager.reloadTable()
    }
 
    @IBAction func didClickReturnToMap(_ sender: Any) {
        delegate?.didReturnToMap()
    }
}

extension CatalogViewController: SuggestionsDisplayManagerDelegate {
    
    func didSelectSuggestion(id: String) {
        delegate?.didSelectSuggestion(id: id)
    }
}

extension CatalogViewController: StaticCategoriesDisplayManagerDelegate {
    
    func didSelectCategoryItem(_ item: StaticCategoryCellItem) {
        
        self.delegate?.didSelectCategoryItem(item)
    }
}
