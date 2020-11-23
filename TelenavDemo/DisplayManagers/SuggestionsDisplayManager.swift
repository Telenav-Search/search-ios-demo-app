//
//  SuggestionsDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavEntitySDK

protocol SuggestionsDisplayManagerDelegate: class {
    func didSelectSuggestion(id: String)
}

class SuggestionsDisplayManager: NSObject {

    var suggestions: [TelenavSuggestionResult] = []
    
    weak var delegate: SuggestionsDisplayManagerDelegate?
    
    func reloadTable() {
        
        if (tableView.delegate is SuggestionsDisplayManager) == false {
            tableView.delegate = self
        }
        
        if (tableView.dataSource is SuggestionsDisplayManager) == false {
            tableView.dataSource = self
        }
        
        tableView.reloadData()

    }
    
    @IBOutlet weak var tableView: UITableView!
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
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Suggestions"
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
        
        guard let suggestionId = suggestions[indexPath.row].id else {
            return
        }
        
        delegate?.didSelectSuggestion(id: suggestionId)
    }
}
