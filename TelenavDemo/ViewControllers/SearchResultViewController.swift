//
//  SearchResultViewController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavSDK

protocol SearchResultViewControllerDelegate: class {
    func goBack()
    func didSelectResultItem(id: String)
    func loadMoreSearchResults()
}

class SearchResultViewController: UIViewController {

    @IBOutlet weak var backBtn: UIButton!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    var lastDisplayedIndexPath: IndexPath?
    
    private var content = [TNEntity]()
    
    weak var delegate: SearchResultViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func fillSearchResults(_ content: [TNEntity], resetPagination: Bool = false) {
        self.content = content
        
        if resetPagination == true {
            self.lastDisplayedIndexPath = nil
        }
        
        tableView.reloadData()
    }

    @IBAction func didClickBack(_ sender: Any) {
        delegate?.goBack()
    }
}

extension SearchResultViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: SearchResultCell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") as? SearchResultCell else {
            return UITableViewCell()
        }
        
        cell.fillSearchResultItem(content[indexPath.row], itemNumber: indexPath.row + 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let lastDisplayedIndexPath = lastDisplayedIndexPath else {
            self.lastDisplayedIndexPath = indexPath
            return
        }
        
        guard indexPath > lastDisplayedIndexPath else {
            return
        }
        
        self.lastDisplayedIndexPath = indexPath
        
        if indexPath.row == content.count - 1 {
            delegate?.loadMoreSearchResults()
        }
    }
}

extension SearchResultViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = content[indexPath.row]
        
        guard let id = item.id else {
            return
        }
        
        delegate?.didSelectResultItem(id: id)
    }
}
