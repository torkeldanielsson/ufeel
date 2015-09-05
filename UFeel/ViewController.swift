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
        
        // Create logo view
        imageView = UIImageView(image: UIImage(named: "uFLogo.png"))
        imageView.frame = CGRectMake(0, 0, self.view.frame.width, 320)

        // Create nightly log line chart view
        fillNightsWithRandomData()
        var dataEntries: [ChartDataEntry] = []
        var xVals: [String] = []
        for i in 0..<nights.count {
            let data_points: [DataPoint] = nights[i].dataPoints
            for j in 0..<data_points.count {
                let dataEntry = ChartDataEntry(value: data_points[j].movement,
                                               xIndex: j)
                dataEntries.append(dataEntry)
                xVals.append(String(j))
                //print("i " + String(i) + " j " + String(j))
                //print(" value ")
                //println(String(format:"%f", data_points[j].movement))
            }
        }
        lineChartView = LineChartView()
        lineChartView.noDataText = "No data..."
        lineChartView.pinchZoomEnabled = false
        lineChartView.dragEnabled = false
        lineChartView.legend.enabled = false
        lineChartView.xAxis.enabled = false
        lineChartView.drawBordersEnabled = true
        lineChartView.descriptionText = ""
        lineChartView.leftAxis.enabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.backgroundColor = UIColor.whiteColor()
        
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: "Activity")
        chartDataSet.drawCubicEnabled = true
        chartDataSet.drawFilledEnabled = true
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        chartDataSet.fillColor = UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)
        let chartData = LineChartData(xVals: xVals, dataSet: chartDataSet)
        lineChartView.data = chartData
        lineChartView.frame = CGRectMake(0, imageView.frame.size.height, self.view.frame.width, 320)
        
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
            let angle: Double = 1.0+sin((Double(index)/Double(expected_samples_per_night))*2.0*M_PI)
            let data_point = DataPoint(movement: angle, time: Double(index) / Double(expected_samples_per_night))
            night.dataPoints.append(data_point)
        }
        nights.append(night)
    }
}

