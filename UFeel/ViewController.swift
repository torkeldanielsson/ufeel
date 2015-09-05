//
//  ViewController.swift
//  UFeel
//
//  Created by Torkel Danielsson on 05/09/15.
//  Copyright (c) 2015 Kodama AB. All rights reserved.
//

import UIKit
import Charts
import Darwin

struct DataPoint {
    let movement: Double
    let time: NSDate
    init(movement: Double, time: NSDate){
        self.movement = movement;
        self.time = time;
    }
}

class NightData {
    
    init() {
        dataPoints = [DataPoint]()
    }

    var dataPoints: [DataPoint]
}

class ViewController: UIViewController {

    @IBOutlet weak var lineChartView: Charts.LineChartView!
    var nights: [NightData]
    
    convenience init() {
        self.init()
        self.nights = [NightData]()
    }
    
    required init(coder: NSCoder) {
        self.nights = [NightData]()

        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fillNightsWithRandomData()
        
        lineChartView.noDataText = "No data."
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fillNightsWithRandomData() {
        let expected_samples_per_night = 480
        for index in 1...expected_samples_per_night {
            let angle: Double = (Double(index)/Double(expected_samples_per_night))*2.0*M_PI
            let calendar: NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let date: NSDate = calendar.dateWithEra(1, year: 1, month: 1, day: 1, hour: 1, minute: index, second: 0, nanosecond: 0)!
            let data_point = DataPoint(movement: angle, time: date)
        }
    }
}

