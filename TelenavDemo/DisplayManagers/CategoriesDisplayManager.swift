//
//  CategoriesDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit

protocol CategoriesDisplayManagerDelegate: class {
    func goToChildCategory(id: String)
}

class CategoriesDisplayManager: NSObject {

    var categories: [TelenavCategoryDisplayModel] = []
    
    weak var delegate: CategoriesDisplayManagerDelegate?
    
    var idxPath = [IndexPath]()
    
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
        
        if let children = category.category.childNodes, children.count > 0 {
            insertSubcategoriesOfCategory(category)
        } else {
            
            guard let id = category.category.id else {
                return
            }
            
            delegate?.goToChildCategory(id: id)
        }
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
            
            let idxPathsToRemove = findNodesForCollapsing(for: category)
        
            guard let firstIdx = idxPathsToRemove.first?.row, let lastIdx =  idxPathsToRemove.last?.row else {
                return
            }
            
            categories.removeSubrange(firstIdx...lastIdx)
            
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

    func findNodesForCollapsing(for cat: TelenavCategoryDisplayModel) -> [IndexPath] {
        
        let selectedCategoryLevel = cat.catLevel
        var idxPaths = [IndexPath]()
        
        guard let selectedCategoryIdx = categories.firstIndex(where: { (categ) -> Bool in
            categ.category.id == cat.category.id
        }) else {
            return []
        }
        
        for idx in (selectedCategoryIdx...self.categories.count - 1) {
            
            let category = categories[idx]
            
            if category.catLevel == selectedCategoryLevel && category.category.id != cat.category.id {
                break
            }
            
            if (category.isExpanded && category.catLevel >= selectedCategoryLevel) {
                
                let indexPath = IndexPath(row: idx + 1, section: 0)
                idxPaths.append(indexPath)
            }
            
            if (category.category.childNodes == nil && category.catLevel > selectedCategoryLevel) {
                let indexPath = IndexPath(row: idx, section: 0)
                idxPaths.append(indexPath)
            }
        }
        
        return idxPaths
    }
}
