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
import Foundation
import CoreLocation


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

struct VårdKontakt {
    let hsaID: String
    let tel: String
    let address: [String]
    let latitude: Double
    let longitude: Double
    var distance: Double
    init (tel: String, address: [String], latitude: Double, longitude: Double, distance: Double, hsaID: String) {
        self.tel = tel
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.hsaID = hsaID
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate {

    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var lineChartView: LineChartView!
    var nights: [NightData]
    
    var problemView: UIScrollView!
    
    var myLatitude: Double = 0.0;
    var myLongitude: Double = 0.0;
    
    let degreesToKm: Double = 110.57461087757687
    
    var vårdKontakter: [VårdKontakt]
    let maxVårdKontakter = 5
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    convenience init() {
        self.init()
        self.nights = [NightData]()
        self.vårdKontakter = [VårdKontakt]()
    }
    
    func initGeoPos() {
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func locationManager(manager: CLLocationManager!,   didUpdateLocations locations: [AnyObject]!) {
        var locValue:CLLocationCoordinate2D = manager.location.coordinate
        if (myLatitude < 0.1) {
            myLatitude = locValue.latitude
            myLongitude = locValue.longitude
            println("My lat: " + String(stringInterpolationSegment: myLatitude))
            println("My lon: " + String(stringInterpolationSegment: myLongitude))
            getHPA_JSON()
        }
    }
    
    func calcDistance(latitude: Double, longitude: Double) -> Double {
        let x = latitude - myLatitude
        let y = longitude - myLongitude
        let distance = sqrt(x * x + y * y)
        return distance
    }
    
    var count_discarded = 0
    var count_all = 0
    
    func addToListIfClose(vårdKontakt: VårdKontakt) {
        count_all++
        var thisIsBetter = false
        var worstValue = 0.0
        for otherVårdKontakt in vårdKontakter {
            if (otherVårdKontakt.distance > worstValue) {
                worstValue = otherVårdKontakt.distance
            }
        }
        if (worstValue > vårdKontakt.distance) {
            thisIsBetter = true
        }
        if (vårdKontakter.count < maxVårdKontakter) {
            thisIsBetter = true
        }
        if (thisIsBetter) {
            vårdKontakter.append(vårdKontakt)
        } else {
            count_discarded++
        }
        if (vårdKontakter.count > maxVårdKontakter) {
            vårdKontakter.sort({ $0.distance < $1.distance })
            vårdKontakter.removeLast()
        }
    }
    
    func parseHPA_JSON(json: JSON) {
        for result in json.arrayValue {
            let relDesName = result["relativeDistinguishedName"].stringValue
            let geoLocation_lat_str = result["geoLocation"]["latitude"].stringValue
            let geoLocation_lon_str = result["geoLocation"]["longitude"].stringValue
            let address: [String] = [result["postalAddress"][0].stringValue,
                                     result["postalAddress"][1].stringValue,
                                     result["postalAddress"][2].stringValue]
            let latitude = (geoLocation_lat_str as NSString).doubleValue
            let longitude = (geoLocation_lon_str as NSString).doubleValue
            let distance = calcDistance(latitude, longitude: longitude)
            let hsaID = result["hsaId"].stringValue
            let telephone = result["telephoneNumber"].stringValue;
            let vårdKontakt: VårdKontakt = VårdKontakt(tel: telephone, address: address, latitude: latitude, longitude: longitude, distance: distance, hsaID: hsaID)
            if (relDesName.uppercaseString.rangeOfString("VÅRDCENT") != nil)
            || (relDesName.uppercaseString.rangeOfString("PSYKIATR") != nil)
            {
                addToListIfClose(vårdKontakt)
            }
        }
        println("total nr: " + String(count_all))
        println("discarded nr: " + String(count_discarded))
        
        for vk in vårdKontakter {
            println(vk.address[0])
            println(vk.address[1])
            println(vk.address[2])
            println(vk.tel)
            println(vk.hsaID)
            println("distance: " + String(stringInterpolationSegment: vk.distance))
        }

    }
    
    func getHPA_JSON(){
        println("Reading JSON: Vårdkontakter...")
        
        var urlString = "http://api.offentligdata.minavardkontakter.se/orgmaster-hsa/v1/hsaObjects/"
        
        if let url = NSURL(string: urlString) {
            if let data = NSData(contentsOfURL: url, options: .allZeros, error: nil) {
                let json = JSON(data: data)
                
                if let mystring = json[0]["type"].string {
                    parseHPA_JSON(json)
                } else {
                    println("not ok")
                }
            }
        }
        
        println("done!")
    }
    
    required init(coder: NSCoder) {
        self.nights = [NightData]()
        self.vårdKontakter = [VårdKontakt]()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initGeoPos()
        
        var yPos: CGFloat = 0.0;
        
        // Create logo view
        imageView = UIImageView(image: UIImage(named: "uFLogo.png"))
        imageView.frame = CGRectMake(0, 0, self.view.frame.width, 320)
        yPos += imageView.frame.size.height

        //Create button
        let button   = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.frame = CGRectMake(0, yPos, self.view.frame.width, 60)
        button.setTitle("Är allt ok?", forState: UIControlState.Normal)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        button.addTarget(self, action: "switchToProblemViewAction:", forControlEvents: UIControlEvents.TouchUpInside)

        yPos += button.frame.size.height

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
        chartDataSet.colors = [UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)]
        chartDataSet.fillColor = UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)
        let chartData = LineChartData(xVals: xVals, dataSet: chartDataSet)
        lineChartView.data = chartData
        lineChartView.frame = CGRectMake(0, yPos, self.view.frame.width, 320)
        
        yPos += lineChartView.frame.size.height
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.contentSize = CGSizeMake(self.view.frame.width, yPos)
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        scrollView.addSubview(lineChartView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(button)
        
        view.addSubview(scrollView)
    }
    
    func createProblemView() {
    if (problemView == nil) {
        var yPos: CGFloat = 0.0
        
        
        problemView = UIScrollView(frame: view.bounds)
        problemView.alwaysBounceVertical = true
        problemView.backgroundColor = UIColor.whiteColor()
        problemView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        yPos += 20
        let button   = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.frame = CGRectMake(0.0, yPos, 100, 50)
        button.setTitle("tillbaka", forState: UIControlState.Normal)
        button.addTarget(self, action: "switchToMainViewAction:", forControlEvents: UIControlEvents.TouchUpInside)
        problemView.addSubview(button)
        yPos += button.frame.size.height
        
        yPos += 40
        var label0 = UILabel(frame: CGRectMake(0, yPos, self.view.frame.width, 100))
        label0.textAlignment = NSTextAlignment.Center
        label0.text = "Ta"
        label0.numberOfLines = 3
        label0.textColor = UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)
        label0.font = label0.font.fontWithSize(72)
        yPos += label0.frame.size.height
        problemView.addSubview(label0)
        var label2 = UILabel(frame: CGRectMake(0, yPos, self.view.frame.width, 100))
        label2.textAlignment = NSTextAlignment.Center
        label2.text = "det"
        label2.numberOfLines = 3
        label2.textColor = UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)
        label2.font = label2.font.fontWithSize(72)
        yPos += label2.frame.size.height
        problemView.addSubview(label2)
        var label3 = UILabel(frame: CGRectMake(0, yPos, self.view.frame.width, 100))
        label3.textAlignment = NSTextAlignment.Center
        label3.text = "lugnt"
        label3.numberOfLines = 3
        label3.textColor = UIColor(red: 255/255, green: 0/255, blue: 157/255, alpha: 1)
        label3.font = label3.font.fontWithSize(72)
        yPos += label3.frame.size.height
        problemView.addSubview(label3)
        
        var label1 = UILabel(frame: CGRectMake(0, yPos, self.view.frame.width, 150))
        label1.textAlignment = NSTextAlignment.Left
        label1.text = "Telefonnummer till dina närmaste vårdgivare:"
        label1.numberOfLines = 3
        label1.font = label1.font.fontWithSize(24)
        yPos += label1.frame.size.height
        problemView.addSubview(label1)
        
        for vårdKontakt in vårdKontakter {
            var addressLabel0 = UILabel(frame: CGRectMake(20, yPos, self.view.frame.width-20, 25))
            addressLabel0.textAlignment = NSTextAlignment.Left
            addressLabel0.text = vårdKontakt.tel
            addressLabel0.textColor = UIColor.blueColor()
            problemView.addSubview(addressLabel0)
            yPos += addressLabel0.frame.size.height+10
        }
        
        problemView.contentSize = CGSizeMake(self.view.frame.width, yPos)
        problemView.hidden = true
        
        view.addSubview(problemView)
    }
    }
    
    func switchToProblemViewAction(sender:UIButton!)
    {
        createProblemView();
        scrollView.hidden = true
        problemView.hidden = false
    }
    
    func switchToMainViewAction(sender:UIButton!)
    {
        scrollView.hidden = false
        problemView.hidden = true
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

