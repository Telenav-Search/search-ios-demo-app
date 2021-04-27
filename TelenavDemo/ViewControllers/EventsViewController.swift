//
//  EventsViewController.swift
//  TelenavDemo
//
//  Created by Evgeniy Gushchin on 27.04.2021.
//

import UIKit
import TelenavSDKDataCollector

class EventsViewController: UIViewController {
    
    @IBOutlet weak var accelerometerView: AccelerationEventDataView!
    
    @IBOutlet weak var linearAccelerationView: AccelerationEventDataView!
    
    @IBOutlet weak var gyroscopeView: AccelerationEventDataView!
    
    typealias AccelerationData = (x: Double, y: Double, z: Double)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        accelerometerView.nameLabel.text = "Accelerometer"
        linearAccelerationView.nameLabel.text = "Linear accelaration"
        gyroscopeView.nameLabel.text = "Gyroscope"
        
        subscribeToSensor()
    }
    

    private func subscribeToSensor() {
        let client = TNDataCollectorService.sharedClient
        client?.subscribe(consumerWithName: "EventsViewController",
                          forEventTypes: TNEventType.Sensor.values,
                          withCallBack: { [weak self] (event) in
            
                            var data: AccelerationData? = nil
                            var dataView: AccelerationEventDataView? = nil
                            if let e = event as? TNAccelerometerEvent,
                               let item = e.accelerometerList.first {
                                data =  (item.x, item.y, item.z)
                                dataView = self?.accelerometerView
                                
                            } else if let e = event as? TNGyroscopeEvent,
                                      let item = e.gyroscopeList.first {
                                data =  (item.x, item.y, item.z)
                                dataView = self?.gyroscopeView
                            } else if let e = event as? TNLinearAccelerationEvent,
                                      let item = e.linearAccelerationList.first {
                                data =  (item.x, item.y, item.z)
                                dataView = self?.linearAccelerationView
                            }
                            
                            guard let view = dataView, let dataTouple = data else {
                                return
                            }
                            DispatchQueue.main.async {
                                self?.updateValuesFor(dataView: view, data: dataTouple)
                            }
                          })
    }

    private func updateValuesFor(dataView: AccelerationEventDataView, data: AccelerationData) {
        dataView.xValueLabel.text = "\(data.x)"
        dataView.yValueLabel.text = "\(data.y)"
        dataView.zValueLabel.text = "\(data.z)"
    }
}
