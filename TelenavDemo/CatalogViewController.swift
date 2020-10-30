//
//  CatalogViewController.swift
//  TelenavDemo
//
//  Created by ezaderiy on 30.10.2020.
//

import UIKit

protocol CatalogViewControllerDelegate {
    func didSelectNode()
}

class CatalogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var delegate: CatalogViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //tableView.register(CatalogBaseCell.self, forCellReuseIdentifier: "CatalogBaseCell")
    }

    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CatalogBaseCell") as? CatalogBaseCell else {
            return UITableViewCell()
        }
        
        cell.mainLabel.text = "Return to map"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectNode()
    }

}
