//
//  SuggestionsDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavEntitySDK

protocol SuggestionsDisplayManagerDelegate: AnyObject {
    func didSelectSuggestion(entity: TNEntity, distance: String?)
    func didSelectQuery(_ query: String)
}

class SuggestionsDisplayManager: NSObject {

    var suggestions: [TNEntitySuggestion] = []
    
    weak var delegate: SuggestionsDisplayManagerDelegate?
    
    func reloadTable() {
        if (tableView?.delegate is SuggestionsDisplayManager) == false {
            tableView?.delegate = self
        }
        
        if (tableView?.dataSource is SuggestionsDisplayManager) == false {
            tableView?.dataSource = self
        }
        
        tableView?.reloadData()

    }
    
    @IBOutlet weak var tableView: UITableView?
}

extension SuggestionsDisplayManager: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: SuggesstionCell = tableView.dequeueReusableCell(withIdentifier: "SuggesstionCell") as? SuggesstionCell else {
            return UITableViewCell()
        }
     
        let suggestion = suggestions[indexPath.row]
        
        cell.fillSuggestion(suggestion)
        cell.accessibilityIdentifier = "suggestionCell"
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Suggestions"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let myLabel = UILabel()
        myLabel.frame = CGRect(x: 20, y: 8, width: 320, height: 20)
        myLabel.font = UIFont.systemFont(ofSize: 14)
        myLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        myLabel.backgroundColor = UIColor.clear
        
        let headerView = UIView()
        headerView.addSubview(myLabel)
        headerView.backgroundColor = UIColor.systemGray6
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension SuggestionsDisplayManager: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let _ = suggestions[indexPath.row].id,
           let entity = suggestions[indexPath.row].entity {
            delegate?.didSelectSuggestion(entity: entity, distance: entity.formattedDistance)
        } else if let query = suggestions[indexPath.row].formattedLabel,
                  suggestions[indexPath.row].type == "QUERY" {
            delegate?.didSelectQuery(query)
        }
        
    }
}
