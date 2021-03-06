//
//  SearchResultViewController.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavEntitySDK

protocol SearchResultViewControllerDelegate: class {
    func goBack()
    func didSelectResultItem(entity: TNEntity, distance: String?)
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
    
    @IBOutlet weak var noResultsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layer.masksToBounds = false
        self.view.layer.cornerRadius = 18
        self.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.view.layer.shadowColor = UIColor.black.cgColor
        self.view.layer.shadowPath = UIBezierPath(roundedRect: self.view.bounds,
                                                  cornerRadius: self.view.layer.cornerRadius).cgPath
        self.view.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
        self.view.layer.shadowOpacity = 0.5
        self.view.layer.shadowRadius = 10.0
    }
    
    func fillSearchResults(_ content: [TNEntity], resetPagination: Bool = false) {
        self.content = content
        DispatchQueue.main.asyncAfter(deadline: .now() ) {
            self.noResultsView.isHidden = content.count != 0
        }
        if resetPagination == true {
            tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: false)
            self.lastDisplayedIndexPath = nil
        }
        self.tableView.reloadData()
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
        
        guard item.id != nil else {
            return
        }
        
        delegate?.didSelectResultItem(entity: item , distance: item.formattedDistance)
    }
}
