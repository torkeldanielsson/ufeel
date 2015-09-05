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
    let time: Double
    init(movement: Double, time: Double){
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

    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var lineChartView: LineChartView!
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
        
        lineChartView = LineChartView()
        
        fillNightsWithRandomData()
        
        lineChartView.noDataText = "No data."
        
        var dataEntries: [ChartDataEntry] = []
        var xVals: [String] = []
        
        for i in 0..<nights.count {
            let data_points: [DataPoint] = nights[i].dataPoints
            for j in 0...data_points.count {
                let dataEntry = ChartDataEntry(value: data_points[i].movement,
                                               xIndex: j)
                dataEntries.append(dataEntry)
                xVals.append(String(format:"%f", data_points[i].time))
            }
        }
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: "Units Sold")
        let chartData = LineChartData(xVals: xVals, dataSet: chartDataSet)
        lineChartView.data = chartData
        lineChartView.frame.size = CGSizeMake(self.view.frame.width, 320)
        
        imageView = UIImageView(image: UIImage(named: "image.png"))
        imageView.frame = CGRectMake(0, lineChartView.frame.size.height, self.view.frame.width, 320)
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.contentSize = CGSizeMake(self.view.frame.width,
            imageView.frame.size.height+imageView.frame.size.height)
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        scrollView.addSubview(lineChartView)
        scrollView.addSubview(imageView)
        
        view.addSubview(scrollView)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fillNightsWithRandomData() {
        let expected_samples_per_night = 480
        var night = NightData()
        for index in 1...expected_samples_per_night {
            let angle: Double = (Double(index)/Double(expected_samples_per_night))*2.0*M_PI
            let data_point = DataPoint(movement: angle, time: Double(index) / Double(expected_samples_per_night))
            night.dataPoints.append(data_point)
        }
        nights.append(night)
    }
}

