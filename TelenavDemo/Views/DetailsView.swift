//
//  DetailsView.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavSDK

class DetailsView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UINib(nibName: "DetailViewCell", bundle: nil), forCellReuseIdentifier: "DetailViewCell")
        }
    }
    
    var content = [DetailViewDisplayModel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed(String(describing: DetailsView.self), owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.isUserInteractionEnabled = true
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func fillEntity(_ entity: TelenavEntity) {
        
        switch entity.type {
        case .address:
            break
        case .place:
            
            content = [
                DetailViewDisplayModel(fieldName: "Name", fieldValue: entity.place?.name ?? ""),
                DetailViewDisplayModel(fieldName: "Address", fieldValue: entity.place?.address?.addressLines?.joined(separator: "\n") ?? ""),
                DetailViewDisplayModel(fieldName: "Website", fieldValue: entity.place?.websites?.joined(separator: "\n") ?? "")
            ]
            
            if let distance = entity.formattedDistance {
                content.append( DetailViewDisplayModel(fieldName: "Distance", fieldValue: distance))
            }
            
            tableView.reloadData()
            
        case .none:
            break
        }
    }
}

extension DetailsView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: DetailViewCell = tableView.dequeueReusableCell(withIdentifier: "DetailViewCell", for: indexPath) as?  DetailViewCell else {
            return UITableViewCell()
        }
        
        cell.fillDetail(content[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
