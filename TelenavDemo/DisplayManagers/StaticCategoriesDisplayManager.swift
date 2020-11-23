//
//  StaticCategoriesDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavEntitySDK

protocol StaticCategoriesDisplayManagerDelegate: class {
    func didSelectCategoryItem(_ item: StaticCategoryCellItem)
}

class StaticCategoriesDisplayManager: NSObject {
    
    var categories = [StaticCategoryCellItem]()
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: StaticCategoriesDisplayManagerDelegate?
    
    func reloadTable() {
                
        if (tableView?.delegate is StaticCategoriesDisplayManager) == false {
            tableView?.delegate = self
        }
        
        if (tableView?.dataSource is StaticCategoriesDisplayManager) == false {
            tableView?.dataSource = nil
            tableView?.dataSource = self
            tableView?.reloadData()
        }
    }
}

extension StaticCategoriesDisplayManager: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: StaticCatalogCell = tableView.dequeueReusableCell(withIdentifier: "StaticCatalogCell") as? StaticCatalogCell else {
            return UITableViewCell()
        }
        
        let catItem = categories[indexPath.row]
        
        cell.fillStaticCategoryItem(catItem)
        
        return cell
    }
}
 
extension  StaticCategoriesDisplayManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let catItem = categories[indexPath.row]

        delegate?.didSelectCategoryItem(catItem)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return tableView.frame.height / CGFloat(categories.count)
    }
}
