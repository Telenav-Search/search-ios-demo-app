//
//  CatalogViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 30.10.2020.
//

import UIKit
import TelenavSDK

protocol CatalogViewControllerDelegate {
    func didSelectNode()
    func didReturnToMap()
}

class CatalogViewController: UIViewController  {

    var delegate: CatalogViewControllerDelegate?
    
    @IBOutlet var categoriesDisplayManager: CategoriesDisplayManager!
    
    @IBOutlet var suggestionsDisplayManager: SuggestionsDisplayManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.categoriesDisplayManager.reloadTable()
    }

    func fillCategories(_ categories: [TelenavCategoryDisplayModel]) {
        self.categoriesDisplayManager.categories = categories
    }
    
    func fillSuggestions(_ suggestions: [TelenavSuggestionResult]) {
        self.suggestionsDisplayManager.suggestions = suggestions
        self.suggestionsDisplayManager.reloadTable()
    }
 
    @IBAction func didClickReturnToMap(_ sender: Any) {
        delegate?.didReturnToMap()
    }
}
