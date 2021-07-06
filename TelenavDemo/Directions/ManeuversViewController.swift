//
//  ManeuversViewController.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 05.07.2021.
//

import Foundation
import UIKit
import VividNavigationSDK

class ManeuversViewController: UITableViewController {
    
    var route: VNRoute?
    
    override func viewDidLoad() {
        title = "Route maneuvers"
    }
    
    func showManeuvers(ofRoute route: VNRoute?) {
        self.route = route
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let route = route else {
            return 0
        }
        return route.legs.count
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if let route = route,
           section < route.legs.count {
            return route.legs[section].steps.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if let route = route,
           section < route.legs.count {
            let leg = route.legs[section]
            let duration = String(format: "%.2f", leg.duration/60/60)
            return "\(section+1) leg: \(leg.length/1000)km, \(duration) h"
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let route = route else {
            return UITableViewCell()
        }
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }
        if indexPath.section < route.legs.count {
            let leg = route.legs[indexPath.section]
            if indexPath.row < leg.steps.count {
                let step = leg.steps[indexPath.row]
                if let maneuver = step.maneuver {
                    cell?.textLabel?.text = String(format: "in %.1f km", step.length/1000)
                    cell?.detailTextLabel?.text = descriptionOfManeuverAction(maneuver.action)
                }
            }
        }
        return cell!
    }
}