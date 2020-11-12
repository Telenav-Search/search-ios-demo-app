//
//  SuggestionsDisplayManager.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavSDK

class SuggestionsDisplayManager: NSObject {

    var suggestions: [TelenavSuggestionResult] = []
    
    func reloadTable() {
        
        if (tableView.delegate is SuggestionsDisplayManager) == false {
            tableView.delegate = self
        }
        
        if (tableView.dataSource is SuggestionsDisplayManager) == false {
            tableView.dataSource = self
            tableView.reloadData()
        }
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
     
        let title = suggestions[indexPath.row].formattedLabel ?? ""
        
        cell.fillTitle(title)
        
        return cell
    }

}

extension SuggestionsDisplayManager: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
