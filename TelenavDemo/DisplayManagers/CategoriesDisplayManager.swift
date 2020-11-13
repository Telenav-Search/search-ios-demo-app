//
//  CategoriesDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit

class CategoriesDisplayManager: NSObject {

    var categories: [TelenavCategoryDisplayModel] = []
    
    func reloadTable() {
                
        if (tableView.delegate is CategoriesDisplayManager) == false {
            tableView.delegate = self
        }
        
        if (tableView.dataSource is CategoriesDisplayManager) == false {
            tableView.dataSource = nil
            tableView.dataSource = self
            tableView.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
}

extension CategoriesDisplayManager: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: CatalogBaseCell = tableView.dequeueReusableCell(withIdentifier: "CatalogBaseCell") as? CatalogBaseCell else {
            return UITableViewCell()
        }
        
        cell.fillCategory(categories[indexPath.row])
        
        return cell
    }
    
}

extension CategoriesDisplayManager: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = categories[indexPath.row]
        
        insertSubcategoriesOfCategory(category)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    private func insertSubcategoriesOfCategory(_ category: TelenavCategoryDisplayModel) {
        
        guard let idxOfSelectedCat = categories.firstIndex(where: { (cat) -> Bool in
            cat.category.id == category.category.id
        }) else {
            return
        }
        
        guard let subcats = category.category.childNodes else {
            return
        }
        
        if category.isExpanded == true {
            
            let indexToCollaps = idxOfSelectedCat + 1
            
            var idxPathsToRemove = [IndexPath]()
            
            let subcatsToRemove = category.category.childNodes ?? []
            
            let mappedSubcats = subcatsToRemove.map { (cat) -> TelenavCategoryDisplayModel in
                
                return TelenavCategoryDisplayModel(category: cat, catLevel: category.catLevel + 1)
            }
            
            for subcat in mappedSubcats {
                
                for i in indexToCollaps...(idxOfSelectedCat + subcats.count) {
                    if categories[i].category.id == subcat.category.id {
                     
                        idxPathsToRemove.append(IndexPath(row: i, section: 0))
                    }
                }
            }
            
            categories.removeSubrange(idxPathsToRemove.first!.row...idxPathsToRemove.last!.row)
            
            tableView.deleteRows(at: idxPathsToRemove, with: .fade)
            
        } else {
            
            let indexToInsert = idxOfSelectedCat + 1
            
            let mappedSubcats = subcats.map { (cat) -> TelenavCategoryDisplayModel in
                
                return TelenavCategoryDisplayModel(category: cat, catLevel: category.catLevel + 1)
            }
            
            self.categories.insert(contentsOf: mappedSubcats, at: indexToInsert)
            
            var idxPathsToInsert = [IndexPath]()
            
            for i in indexToInsert...(idxOfSelectedCat + subcats.count) {
                idxPathsToInsert.append(IndexPath(row: i, section: 0))
            }
            
            tableView.insertRows(at: idxPathsToInsert, with: .fade)
        }
    
        
        category.isExpanded.toggle()
        tableView.reloadRows(at: [IndexPath(row: idxOfSelectedCat, section: 0)], with: .fade)
    }
}
