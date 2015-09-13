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
            //getHPA_JSON()
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
        yPos += imageView.frame.size.height - 50

        //Create button
        let button   = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.frame = CGRectMake(0, yPos, self.view.frame.width, 60)
        button.setTitle("Är allt ok?", forState: UIControlState.Normal)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        button.addTarget(self, action: "switchToProblemViewAction:", forControlEvents: UIControlEvents.TouchUpInside)

        yPos += button.frame.size.height

        // Create nightly log line chart view
        var dataEntries: [ChartDataEntry] = []
        var xVals: [String] = []
        var accVals: [Double] = [0.09, 0.06, 0.10, 0.14, 0.11, 0.14, 0.20, 0.18, 0.21, 0.16, 0.15, 0.14, 0.10, 0.11, 0.13, 0.13, 0.14, 0.09, 0.15, 0.20, 0.11, 0.12, 0.16, 0.23, 0.19, 0.14, 0.16, 0.15, 0.16, 0.06, 0.09, 0.07, 0.04, 0.06, 0.08, 0.10, 0.17, 0.27, 0.23, 0.22, 0.12, 2.21, 1.34, 0.12, 0.20, 0.14, 0.26, 0.06, 0.09, 0.04, 0.04, 0.08, 0.82, 0.17, 0.35, 0.21, 0.44, 0.52, 0.28, 0.04, 0.17, 0.08, 0.17, 1.94, 0.67, 0.55, 0.15, 1.06, 0.44, 0.09, 0.96, 0.21, 0.05, 0.13, 0.17, 0.82, 0.06, 0.25, 0.16, 0.96, 0.51, 0.51, 0.34, 0.78, 1.04, 0.34, 0.40, 0.08, 0.74, 0.39, 0.32, 0.88, 1.24, 0.37, 0.87, 0.83, 0.47, 1.16, 2.12, 1.96, 1.00, 0.53, 1.38, 1.64, 0.74, 1.11, 3.72, 0.57, 1.16, 1.69, 1.76, 2.63, 0.69, 0.51, 0.76, 0.73, 1.17, 1.04, 0.46, 1.82, 0.30, 1.28, 1.13, 0.82, 1.03, 0.67, 0.47, 0.26, 0.31, 0.27, 0.22, 0.35, 1.25, 0.88, 1.29, 0.45, 1.17, 0.82, 0.16, 0.57, 0.41, 0.73, 0.94, 0.27, 0.55, 0.49, 0.92, 0.15, 0.98, 1.65, 0.91, 0.70, 0.48, 0.28, 0.94, 2.70, 1.19, 0.83, 0.19, 0.35, 0.91, 1.01, 0.35, 0.91, 0.57, 0.50, 0.48, 1.55, 4.91, 4.45, 2.38, 4.14, 1.24, 0.40, 0.82, 0.88, 2.05, 4.01, 29.46, 32.15, 36.90, 45.83, 22.57, 41.82, 16.03, 23.27, 37.60, 5.11, 8.02, 3.67, 8.28, 3.65, 7.23, 5.35, 1.56, 4.23, 3.25, 4.21, 2.74, 1.62, 4.19, 2.93, 1.24, 1.34, 2.32, 4.14, 3.70, 1.17, 2.07, 1.33, 1.30, 0.70, 0.54, 0.48, 0.53, 0.52, 0.32, 0.15, 0.41, 0.40, 0.74, 0.60, 0.19, 0.39, 1.08, 1.00, 0.77, 0.74, 0.61, 1.31, 0.90, 0.99, 0.76, 0.67, 1.87, 1.84, 1.07, 0.69, 0.40, 1.12, 1.15, 2.27, 1.44, 0.74, 0.57, 0.97, 0.34, 0.45, 0.44, 0.62, 0.57, 0.67, 0.77, 1.36, 1.10, 0.96, 0.31, 0.44, 0.82, 0.89, 0.57, 0.37, 0.49, 0.65, 0.29, 0.86, 1.19, 0.41, 0.37, 0.82, 0.39, 0.62, 0.34, 0.52, 0.40, 0.47, 0.42, 0.97, 0.42, 0.33, 0.50, 0.61, 0.42, 0.46, 0.45, 0.56, 0.38, 0.36, 0.41, 0.40, 0.35, 0.57, 0.85, 0.34, 0.77, 0.43, 1.15, 0.09, 0.86, 0.76, 0.70, 0.35, 0.52, 0.13, 0.48, 0.74, 0.80, 0.80, 1.41, 0.97, 0.44, 0.83, 1.10, 0.71, 0.31, 0.51, 0.44, 0.42, 0.31, 0.45, 0.49, 0.40, 0.32, 0.32, 0.55, 0.98, 0.96, 0.82, 0.75, 0.45, 0.36, 0.39, 0.27, 0.39, 0.46, 0.29, 0.73, 0.73, 0.77, 1.20, 0.56, 0.30, 0.47, 1.18, 0.97, 0.28, 0.50, 0.21, 0.27, 1.33, 0.69, 1.35, 1.80, 2.00, 1.54, 0.56, 0.64, 1.32, 0.56, 0.35, 0.95, 0.52, 0.38, 0.55, 0.42, 0.46, 0.39, 0.18, 0.54, 1.10, 0.86, 0.17, 0.34, 0.84, 0.71, 0.56, 0.93, 0.52, 0.21, 0.42, 0.27, 0.09, 0.48, 0.27, 0.17, 0.26, 0.30, 0.36, 0.54, 1.04, 1.00, 0.61, 1.11, 0.62, 0.55, 0.64, 0.14, 0.59, 0.48, 0.26, 0.76, 0.34, 0.28, 0.51, 0.89, 0.89, 0.29, 0.24, 0.26, 0.46, 0.97, 0.97, 1.19, 0.61, 1.99, 1.88, 1.29, 1.31, 0.99, 0.34, 0.39, 2.15, 2.78, 1.02, 1.62, 0.43, 1.63, 0.99, 1.04, 0.89, 3.19, 1.28, 0.65, 2.05, 1.32, 3.77, 2.11, 1.17, 2.00, 4.70, 4.19, 1.41, 0.89, 3.15, 20.23, 23.15, 15.10, 13.96, 2.90, 15.17, 9.87, 8.33, 12.45, 1.40, 1.72, 4.98, 2.56, 1.37, 1.10, 1.37, 0.64, 1.46, 0.98, 2.59, 2.35, 0.80, 3.37, 3.12, 0.99, 1.24, 2.02, 0.85, 3.07, 1.11, 1.08, 1.19, 0.97, 0.92, 0.71, 0.26, 1.08, 1.43, 0.94, 1.27, 1.63, 0.75, 0.87, 1.80, 0.63, 1.91, 2.80, 0.99, 1.27, 0.56, 1.57, 2.67, 1.86, 0.90, 0.59, 1.51, 0.88, 2.97, 1.66, 2.25, 2.26, 1.14, 1.07, 0.87, 1.29, 1.65, 0.86, 1.31, 1.61, 0.67, 1.39, 0.75, 3.19, 2.12, 2.10, 2.06, 1.87, 0.71, 0.63, 0.92, 1.08, 0.49, 1.09, 2.45, 1.04, 0.65, 1.03, 0.65, 0.41, 0.51, 2.81, 1.77, 2.87, 1.68, 1.63, 3.09, 1.65, 1.26, 1.12, 2.56, 1.09, 1.73, 1.45, 1.72, 1.68, 1.40, 0.42, 1.50, 0.96, 1.04, 2.55, 2.51, 1.73, 0.68, 2.12, 1.25, 1.31, 0.91, 0.70, 1.18, 1.01, 5.18, 1.99, 3.99, 5.46, 2.20, 4.47, 1.25, 0.70, 0.96, 0.64, 1.81, 3.04, 2.37, 1.21, 1.03, 2.02, 2.36, 1.49, 2.98, 0.99, 1.45, 1.52, 0.59, 0.89, 0.78, 0.71, 0.32, 1.28, 0.87, 0.34, 1.11, 0.37, 0.82, 0.68, 0.56, 0.55, 1.16, 1.58, 0.88, 1.54, 0.58, 1.14, 0.48, 0.42, 0.72, 0.54, 1.03, 1.16, 1.69, 0.81, 0.89, 0.85, 0.83, 0.81, 0.63, 2.76, 1.25, 1.83, 1.52, 1.19, 1.74, 1.81, 3.03, 0.62, 1.36, 0.90, 2.68, 0.40, 0.28, 0.20, 0.27, 0.25, 0.23, 0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.10, 0.11, 0.10, 0.09, 0.09, 0.13, 0.20, 0.17, 0.21, 0.16, 0.12, 0.15, 0.11, 0.09, 0.11, 0.10, 0.11, 0.11, 0.09, 0.09, 0.10, 0.15, 0.20, 0.17, 0.16, 0.16, 0.15, 0.09, 0.10, 0.20, 0.09, 0.10, 0.13, 0.10, 0.07, 0.10, 0.18, 0.18, 0.19, 0.16, 0.11, 0.13, 0.10, 0.09, 0.10, 0.09, 0.06, 0.08, 0.08, 0.09, 0.08, 0.19, 0.19, 0.13, 0.13, 0.09, 2.87, 1.67, 0.77, 0.84, 0.62, 0.56, 1.61, 1.34, 0.76, 0.31, 0.83, 0.58, 0.38, 1.26, 0.50, 3.04, 0.82, 1.85, 2.23, 0.68, 0.89, 1.40, 0.65, 1.65, 0.48, 0.85, 0.36, 1.23, 1.03, 0.81, 0.69, 0.42, 0.62, 0.35, 0.33, 0.48, 0.44, 0.74, 1.38, 1.89, 1.36, 0.18, 1.50, 2.18, 1.65, 0.92, 2.36, 2.30, 0.71, 1.54, 0.45, 0.79, 0.86, 0.91, 0.40, 0.94, 0.49, 1.07, 1.11, 1.11, 1.65, 0.51, 1.18, 0.92, 1.09, 0.70, 3.81, 0.67, 0.81, 1.09, 0.83, 0.68, 0.42, 1.21, 0.17, 0.43, 0.04, 0.76, 0.26, 0.24, 0.22, 0.12, 0.48, 0.53, 0.25, 0.27, 0.10, 0.54, 0.37, 1.20, 1.70, 3.02, 1.73, 0.90, 0.13, 1.38, 0.29, 0.27, 0.36, 1.94, 3.16, 0.56, 1.60, 0.92, 2.34, 1.95, 0.21, 2.44, 0.47, 1.73, 1.37, 1.24, 0.82, 0.56, 0.92, 0.25, 0.10, 0.47, 1.72, 2.03, 4.33, 4.42, 2.30, 0.97, 0.86, 1.96, 0.71, 1.65, 0.99, 2.89, 2.37, 5.47, 2.05, 2.09, 0.38, 0.89, 0.04, 1.62, 1.01, 0.38, 0.30, 0.25, 0.48, 0.79, 1.00, 1.67, 1.26, 1.17, 1.03, 0.58, 1.17, 1.23, 1.17, 0.99, 1.65, 2.36, 9.53, 2.62, 5.53, 20.82, 6.08, 3.00, 5.60, 3.45, 3.73, 25.83, 3.16, 2.04, 6.21, 5.50, 0.76, 0.94, 4.36, 1.91, 1.24, 1.61, 1.18, 3.45, 2.54, 1.35, 1.44, 1.49, 1.71, 1.75, 0.33, 1.46, 1.12, 0.86, 0.19, 1.40, 0.63, 0.62, 0.54, 0.46, 1.19, 0.88, 0.47, 0.24, 0.27, 0.17, 0.07, 0.34, 0.10, 0.20, 0.21, 0.14, 0.41, 0.52, 0.59, 0.37, 0.18, 0.27, 0.96, 1.54, 0.59, 0.10, 0.15, 0.15, 1.15, 2.16, 5.34, 1.30, 2.70, 3.11, 5.48, 2.51, 7.37, 1.79, 1.57, 0.73, 1.13, 1.29, 1.03, 0.85, 0.37, 0.58, 0.36, 0.43, 2.57, 1.20, 0.84, 1.24, 1.63, 1.69, 0.69, 1.91, 2.00, 3.92, 3.39, 0.97, 3.73, 0.71, 0.29, 0.13, 1.69, 0.82, 1.14, 0.64, 0.28, 0.87, 1.23, 1.77, 0.95, 1.81, 0.60, 1.01, 3.67, 0.99, 1.58, 1.24, 4.53, 0.61, 2.18, 0.82, 1.81, 2.46, 3.83, 2.34, 3.75, 3.99, 0.97, 4.01, 3.87, 3.39, 0.87, 0.92, 2.99, 1.00, 0.54, 1.09, 0.18, 0.95, 2.34, 0.43, 0.73, 0.62, 1.20, 0.16, 0.69, 1.11, 0.13, 1.29, 0.78, 0.50, 0.45, 0.24, 1.56, 2.37, 0.84, 0.09, 0.30, 0.30, 0.53, 1.14, 2.71, 3.98, 2.19, 3.19, 0.90, 0.78, 0.86, 1.38, 2.69, 0.51, 6.15, 3.98, 3.70, 1.17, 3.90, 1.63, 2.37, 0.83, 1.95, 0.79, 1.17, 3.39, 1.36, 0.43, 1.41, 2.20, 4.01, 2.87, 0.66, 1.04, 0.59, 1.83, 0.64, 2.66, 0.88, 0.68, 0.75, 1.67, 1.01, 1.19, 3.13, 2.09, 1.84, 2.48, 2.01, 1.70, 4.90, 2.64, 3.25, 0.64, 0.50, 1.11, 0.64, 3.62, 3.70, 0.63, 2.49, 1.56, 2.46, 28.53, 8.13, 3.81, 1.67, 1.41, 1.28, 0.61, 2.68, 1.28, 1.61, 1.05, 1.08, 0.75, 1.33, 1.46, 4.65, 3.81, 3.69, 2.04, 2.94, 1.79, 3.83, 1.56, 2.73, 3.43, 2.22, 5.73, 1.58, 2.14, 2.93, 5.76, 1.63, 1.25, 4.98, 4.29, 9.22, 3.20, 0.78, 0.42, 2.35, 5.05, 2.90, 2.05, 3.19, 0.40, 0.32, 1.29, 1.28, 1.34, 1.38, 2.15, 0.91, 0.74, 0.47, 2.10, 0.18, 1.68, 0.76, 0.55, 0.74, 0.32, 0.31, 3.54, 0.64, 1.32, 1.76, 1.78, 1.21, 3.04, 1.55, 0.50, 1.48, 0.72, 0.65, 0.43, 0.68, 0.51, 1.22, 2.57, 1.26, 2.43, 1.21, 0.48, 0.34, 0.32, 0.27, 0.22, 0.22, 0.26, 0.22, 0.19, 0.24, 0.17, 0.18, 0.12, 0.14, 0.13, 0.12, 0.12, 0.12, 0.10, 0.12, 0.13, 0.12, 0.12, 0.12, 0.09, 0.10, 0.09, 0.10, 0.10, 0.10, 0.09, 0.07, 0.10, 0.06, 0.10, 0.12, 2.49, 2.35, 8.06, 1.06, 0.45, 1.63, 0.71, 0.08, 0.41, 2.85, 0.74, 3.45, 3.91, 3.15, 1.38, 1.92, 2.21, 2.31, 3.14, 2.11, 1.94, 0.41, 0.49, 0.62, 1.04, 1.70, 2.77, 2.25, 2.20, 4.07, 0.37, 0.56, 0.81, 0.16, 0.46, 0.50, 0.22, 0.56, 0.07, 0.04, 0.09, 0.29, 0.22, 0.22, 0.12, 0.10, 0.31, 0.15, 0.47, 0.29, 0.79, 0.55, 0.97, 4.71, 0.44, 2.22, 1.36, 0.93, 0.25, 0.49, 0.21, 0.54, 0.18, 0.51, 0.15, 0.48, 0.66, 0.67, 0.59, 0.40, 0.28, 2.61, 0.19, 0.17, 0.07, 1.67, 0.36, 0.69, 1.48, 1.74, 0.95, 1.17, 3.64, 1.67, 2.65, 0.75, 3.37, 1.95, 1.30, 0.67, 0.37, 1.08, 0.37, 0.66, 0.44, 1.22, 1.08, 1.28, 1.35, 0.64, 3.00, 5.28, 0.30, 0.27, 0.67, 0.27, 0.50, 1.05, 1.46, 0.98, 1.17, 0.72, 0.48, 6.76, 2.60, 4.00, 1.48, 0.82, 1.00, 3.27, 2.76, 1.77, 0.65, 1.38, 1.60, 2.06, 1.46, 1.02, 0.81, 0.49, 0.84, 0.13, 0.33, 0.13, 0.18, 0.56, 0.23, 0.28, 0.35, 0.40, 1.13, 0.41, 0.69, 1.69, 3.30, 3.37, 0.93, 0.66, 1.19, 0.44, 0.18, 0.24, 0.54, 1.52, 4.77, 1.09, 6.18, 0.38, 0.31, 0.42, 0.54, 0.36, 0.30, 0.26, 0.23, 0.30, 0.99, 0.69, 1.11, 1.39, 4.62, 0.56, 0.26, 0.31, 2.77, 1.18, 1.47, 0.98, 1.25, 0.88, 0.44, 0.36, 0.38, 0.32, 0.32, 0.31, 0.24, 0.45, 0.31, 0.21, 0.21, 0.11, 0.17, 0.16, 0.13, 0.22, 0.19, 0.15, 0.16, 0.18, 0.14, 0.09, 0.53, 0.86, 0.70, 0.21, 0.75, 0.11, 0.11, 0.10, 0.05, 0.16, 0.11, 0.12, 0.13, 0.13, 0.11, 0.08, 0.08, 0.09, 6.90, 1.32, 0.28, 0.25, 2.03, 0.74, 0.16, 0.15, 0.22, 1.07, 0.22, 0.30, 0.16, 0.30, 0.25, 0.40, 0.17, 0.60, 2.31, 1.28, 1.06, 1.29, 1.21, 1.72, 1.79, 0.08, 2.66, 2.28, 3.23, 1.45, 0.21, 4.29, 3.63, 1.51, 1.06, 2.76, 0.89, 0.63, 3.61, 1.31, 1.07, 1.61, 0.79, 0.83, 0.74, 0.63, 0.47, 0.41, 2.59, 0.37, 0.48, 0.90, 2.96, 0.49, 0.65, 0.45, 2.01, 2.35, 1.88, 1.86, 0.89, 1.42, 1.49, 1.33, 22.91, 2.33, 1.18, 1.50, 1.71, 2.06, 1.66, 0.86, 2.86, 0.96, 0.30, 1.22, 0.63, 0.55, 4.09, 5.92, 0.95, 4.51, 8.78, 2.22, 1.15, 1.35, 2.57, 2.36, 1.69, 2.56, 4.92, 5.63, 6.26, 0.77, 0.25, 0.23, 0.84, 1.52, 3.55, 1.82, 1.69, 5.07, 14.92, 3.83, 2.67, 3.52, 5.26, 4.99, 1.57, 1.16, 6.03, 2.68, 0.51, 0.18, 0.30, 0.20, 1.02, 1.09, 4.10, 7.62, 18.87, 5.14, 6.66, 1.31, 6.81, 0.64, 2.50, 0.75, 2.19, 1.49, 0.17, 0.29, 0.34, 0.23, 0.52, 3.30, 2.06, 1.44, 0.54, 4.46, 2.29, 0.28, 0.38, 1.21, 1.96, 1.04, 0.94, 0.51, 0.17, 0.15, 0.19, 0.15, 0.26, 4.37, 1.36, 3.16, 0.13, 0.68, 0.22, 0.59, 0.08, 1.70, 0.53, 1.58, 1.30, 1.35, 0.35, 0.34, 0.91, 0.46, 0.68, 0.21, 0.32, 1.35, 4.05, 2.72, 2.89, 0.42, 0.33, 3.24, 4.45, 1.69, 2.84, 1.02, 0.97, 1.11, 0.56, 3.86, 3.46, 3.75, 1.45, 1.10, 0.71, 2.45, 1.38, 1.20, 2.80, 2.11, 2.48, 2.33, 3.17, 11.12, 1.78, 4.18, 1.70, 4.88, 6.65, 2.17, 0.38, 0.13, 3.12, 2.43, 0.87, 0.26, 5.84, 2.21, 1.85, 1.86, 3.40, 3.51, 11.76, 0.72, 3.20, 6.00, 2.03, 3.01, 3.31, 0.80, 1.28, 2.75, 2.47, 1.15, 1.94, 4.49, 0.30, 0.97, 0.61, 0.62, 1.29, 0.99, 0.89, 0.58, 1.69, 1.06, 0.38, 1.14, 1.41, 0.82, 1.37, 1.17, 0.73, 2.21, 1.33, 1.07, 0.57, 2.67, 1.68, 0.36, 5.65, 9.17, 4.46, 4.84, 5.95, 3.47, 1.92, 1.58, 1.00, 0.91, 0.67, 0.52, 0.05, 0.16, 0.71, 0.41, 2.95, 2.11, 2.71, 5.27, 0.83, 0.16, 1.32, 1.20, 0.58, 0.27, 2.28, 1.72, 0.53, 1.21, 2.08, 0.42, 1.25, 3.65, 4.53, 11.95, 1.59, 0.36, 0.27, 0.80, 0.20, 1.76, 0.70, 1.23, 8.92, 2.94, 0.24, 0.29, 0.23, 0.20, 1.75, 0.91, 1.11, 0.36, 0.25, 0.25, 0.27, 1.56, 1.74, 0.26, 0.53, 0.81, 2.24, 4.24, 3.03, 3.29, 2.05, 5.13, 1.43, 0.62, 2.06, 1.28, 4.92, 5.10, 2.47, 1.40, 1.16, 1.20, 0.94, 1.38, 0.88, 1.19, 1.09, 2.41, 4.35, 2.08, 1.45, 4.74, 1.85, 1.29, 0.21, 0.31, 0.20, 0.19, 0.18, 0.19, 0.14, 0.18, 0.17, 0.13, 0.16, 0.16, 0.17, 0.13, 0.12, 0.15, 0.13, 0.12, 0.14, 0.15, 0.14, 0.13, 0.16, 0.15, 0.15, 0.20, 0.20, 0.18, 0.17, 0.18, 0.19, 0.17, 0.18, 0.19, 0.18, 0.16, 0.16, 0.17, 0.20, 0.17, 0.22, 0.23, 0.24, 0.19, 0.21, 0.22, 0.22, 0.14, 0.15, 0.23, 0.34, 0.19, 0.19, 0.14, 0.15, 0.14, 0.13, 0.16, 0.15, 0.14, 0.10, 0.12, 0.15, 0.11, 0.08, 0.13, 0.20, 0.58, 0.27, 1.02, 2.13, 1.59, 0.14, 0.19, 0.13, 0.19, 0.24, 0.18, 0.20, 0.20, 0.10, 0.21, 0.19, 0.11, 0.14, 0.64, 6.33, 5.52, 1.85, 3.34, 1.04, 3.08, 2.53, 1.33, 0.79, 1.29, 1.42, 18.13, 12.20, 4.93, 1.46, 1.54, 0.39, 0.73, 1.71, 0.64, 0.47, 0.96, 1.14, 1.33, 4.74, 0.92, 7.68, 1.28, 12.03, 0.60, 0.13, 0.17, 0.13, 0.16, 0.12, 0.15, 0.15, 0.19, 0.14, 0.13, 0.16, 0.13, 0.16, 0.13, 0.14, 0.15, 0.16, 0.14, 0.15, 0.26, 0.17, 0.17, 0.17, 0.06, 1.91, 1.45, 3.44, 1.06, 0.18, 0.15, 0.16, 0.16, 1.01, 0.19, 0.19, 0.01, 0.09, 0.20, 0.14, 0.09, 0.11, 0.16, 0.14, 2.23, 0.87, 1.57, 0.19, 0.79, 0.68, 2.13, 0.62, 1.66, 0.42, 0.47, 0.58, 0.39, 1.00, 0.31, 0.51, 0.77, 1.55, 0.18, 0.12, 4.17, 0.32, 0.64, 0.23, 0.51, 0.24, 0.48, 2.63, 0.17, 0.41, 0.19, 0.17, 0.16, 0.87, 0.36, 0.12, 0.07, 0.08, 0.14, 0.05, 0.23, 0.14, 0.18, 0.49, 0.21, 0.47, 0.14, 0.06, 0.20, 0.29, 0.10, 0.06, 0.16, 0.14, 0.29, 0.13, 0.23, 2.24, 0.35, 2.17, 1.54, 0.42, 0.22, 0.44, 0.53, 1.15, 0.45, 0.09, 1.12, 0.30, 4.63, 0.78, 0.47, 2.52, 0.32, 0.32, 0.13, 0.32, 2.32, 0.27, 0.64, 0.12, 0.37, 0.09, 0.05, 0.13, 0.09, 0.69, 0.54, 0.14, 2.23, 2.67, 0.98, 1.46, 0.67, 1.58, 1.81, 1.88, 0.42, 1.23, 0.49, 0.97, 0.75, 0.30, 0.32, 1.26, 0.11, 0.17, 0.28, 0.16, 0.17, 0.14, 0.14, 0.09, 0.08, 1.64, 0.39, 0.31, 0.13, 0.12, 0.31, 0.12, 0.44, 0.82, 0.25, 0.11, 0.28, 0.08, 0.23, 0.16, 1.65, 1.10, 2.41, 0.16, 0.10, 0.03, 7.17, 0.94, 0.13, 0.50, 0.09, 0.17, 0.24, 0.15, 0.08, 0.19, 0.18, 0.84, 0.27, 5.27, 1.26, 0.19, 0.35, 9.06, 0.80, 0.17, 0.12, 0.10, 0.82, 0.08, 0.14, 0.19, 0.14, 0.07, 0.15, 0.04, 0.11, 0.13, 0.09, 0.12, 0.09, 0.09, 0.10, 0.19, 0.18, 0.15, 0.15, 0.08, 0.13, 0.16, 0.15, 0.09, 0.11, 0.13, 0.08, 0.09, 0.14, 0.15, 0.09, 0.11, 0.17, 0.16, 0.12, 0.11, 0.12, 0.14, 0.09, 0.10, 0.11, 0.08, 0.12, 0.14, 0.05, 0.06, 0.26, 0.08, 0.13, 0.16, 0.15, 0.14, 0.18, 0.12, 0.10, 0.15, 0.19, 0.14, 0.13, 0.79, 0.46, 0.10, 0.57, 0.15, 0.12, 0.31, 1.33, 0.08, 0.07, 0.10, 0.29, 0.12, 0.14, 0.07, 0.13, 0.64, 0.18, 0.59, 0.13, 0.12, 0.31, 0.15, 0.10, 0.05, 0.27, 0.37, 0.35, 0.26, 0.04, 0.12, 0.05, 0.06, 0.08, 0.11, 0.11, 0.12, 0.09, 0.11, 0.05, 2.52, 0.20, 1.55, 0.12, 0.05, 0.10, 0.08, 0.03, 0.08, 1.51, 0.19, 3.74, 0.06, 2.99, 0.51, 0.10, 0.08, 1.12, 0.25, 0.10, 0.68, 1.05, 0.14, 0.07, 2.88, 0.17, 0.12, 0.17, 0.12, 0.07, 0.09, 0.10, 0.05, 0.08, 0.21, 0.02, 0.07, 0.20, 0.11, 0.02, 0.11, 0.15, 0.16, 0.17, 0.13, 3.15, 0.43, 0.33, 0.66, 0.07, 0.49, 0.02, 0.98, 0.06, 0.10, 0.10, 0.13, 0.12, 5.04, 12.60, 0.06, 0.14, 0.12, 0.14, 0.07, 0.08, 0.09, 0.05, 0.07, 0.10, 0.08, 0.09, 0.02, 0.10, 0.10, 0.14, 0.11, 0.12, 0.17, 0.06, 0.05, 0.10, 0.13, 0.07, 0.15, 0.10, 0.21, 0.03, 0.15, 0.08, 0.15, 0.22, 0.13, 0.15, 0.31, 0.12, 0.08, 0.19, 0.11, 0.08, 0.10, 0.10, 0.06, 0.14, 0.13, 0.12, 0.11, 0.11, 0.09, 0.11, 0.08, 0.04, 0.09, 0.07, 0.09, 0.07, 0.06, 0.07, 0.11, 0.14, 0.11, 0.06, 0.08, 0.05, 0.06, 0.07, 0.09, 0.11, 0.05, 0.05, 0.07, 0.08, 0.09, 0.14, 0.14, 0.13, 0.12, 0.19, 0.14, 0.06, 0.07, 0.08, 0.07, 0.07, 0.08, 0.08, 0.08, 0.07, 0.16, 0.16, 0.16, 0.09, 0.10, 0.09, 0.12, 0.07, 0.06, 0.07, 0.07, 0.08, 0.05, 0.04, 0.07, 0.13, 0.12, 0.10, 0.07, 0.11, 0.12, 0.08, 0.07, 0.09, 0.09, 0.06, 0.10, 0.08, 0.05, 0.07, 0.11, 0.14, 0.13, 0.11, 0.10, 0.09, 0.06, 0.08, 0.11, 0.07, 0.05, 0.04, 0.08, 0.11, 0.07, 0.10, 0.12, 0.12, 0.10, 0.08, 0.07, 0.05, 0.12, 0.08, 0.02, 0.02, 0.06, 0.08, 0.09, 0.08, 0.04, 0.14, 0.18, 0.18, 0.03, 0.03, 0.10, 0.12, 0.11, 0.04, 0.03, 0.07, 0.09, 0.13, 0.07, 0.09, 0.14, 0.16, 0.15, 0.55, 0.19, 0.12, 0.09, 0.07, 0.05, 0.06, 0.05, 0.03, 0.03, 0.06, 0.06, 0.10, 0.15, 0.12, 0.07, 0.09, 0.08, 0.04, 0.04, 0.06, 0.06, 0.06, 0.06, 0.04, 0.06, 0.07, 0.10, 0.14, 0.13, 0.08, 0.09, 0.09, 0.05, 0.07, 0.02, 0.08, 0.05, 0.06, 0.05, 0.06, 0.07, 0.05, 0.13, 0.15, 0.08, 0.07, 0.09, 7.17, 3.88, 4.33, 11.52, 6.08, 17.68, 9.24, 12.65, 12.68, 8.10, 14.86, 7.74, 16.13, 14.37, 16.50, 5.42, 5.82, 11.99, 9.35, 32.66, 2.87, 4.40, 2.59, 8.05, 5.63, 6.23]
        for i in 0..<accVals.count {
            let dataEntry = ChartDataEntry(value: accVals[i],
                                               xIndex: i)
            dataEntries.append(dataEntry)
            xVals.append(String(i))
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
        //lineChartView.animate(xAxisDuration: NSTimeInterval(1.0), yAxisDuration: NSTimeInterval(5.0), easingOption: .EaseInOutBounce)
        
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
        
        // Last nights bar chart:
        var dataNightsEntries: [BarChartDataEntry] = []
        var xNightsVals: [String] = ["26","27","28","29","30","31","1","2","3","4","5"]
        var hoursNightsVals: [Double] = [8.2, 7.2, 9.5, 8.4, 5.3, 7.3, 4.3, 7.7, 8.2, 10.4, 11.3]
        for i in 0..<hoursNightsVals.count {
            let dataEntry = BarChartDataEntry(value: hoursNightsVals[i],
                xIndex: i)
            dataNightsEntries.append(dataEntry)
        }
        
    
    var barChartView = BarChartView()
    barChartView.noDataText = "No data..."
    barChartView.pinchZoomEnabled = false
    barChartView.dragEnabled = false
    barChartView.legend.enabled = false
    barChartView.xAxis.enabled = false
    barChartView.drawBordersEnabled = true
    barChartView.descriptionText = ""
    barChartView.leftAxis.enabled = false
    barChartView.rightAxis.enabled = false
    barChartView.backgroundColor = UIColor.whiteColor()
    //lineChartView.animate(xAxisDuration: NSTimeInterval(1.0), yAxisDuration: NSTimeInterval(5.0), easingOption: .EaseInOutBounce)
    //println("length: "+String(dataNightsEntries.count))
    let nightChartDataSet = BarChartDataSet(yVals: dataNightsEntries, label: "Activity")
        nightChartDataSet.colors = [UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 255/255, green: 70/255, blue: 70/255, alpha: 1),
            UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 255/255, green: 70/255, blue: 70/255, alpha: 1),
            UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 255/255, green: 30/255, blue: 30/255, alpha: 1),
            UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 70/255, green: 200/255, blue: 70/255, alpha: 1),
            UIColor(red: 255/255, green: 70/255, blue: 70/255, alpha: 1),
            UIColor(red: 255/255, green: 30/255, blue: 30/255, alpha: 1)]
    let nightChartData = BarChartData(xVals: xNightsVals, dataSet: nightChartDataSet)
    barChartView.data = nightChartData
    barChartView.frame = CGRectMake(0, yPos, self.view.frame.width, 320)
    
    yPos += lineChartView.frame.size.height
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.contentSize = CGSizeMake(self.view.frame.width, yPos)
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    
        scrollView.addSubview(lineChartView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(button)
        scrollView.addSubview(barChartView)
        
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
        
        //yPos += 40
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
        
        var label1 = UILabel(frame: CGRectMake(15, yPos, self.view.frame.width-30, 150))
        label1.textAlignment = NSTextAlignment.Left
        label1.text = "Telefonnummer till dina närmaste vårdgivare:"
        label1.numberOfLines = 3
        label1.font = label1.font.fontWithSize(22)
        yPos += label1.frame.size.height
        problemView.addSubview(label1)
        
        let telNrs: [String] = ["+4649124543", "+46424563", "+4618566143", "+4649182543", "+4613457664"]
        
        for telNr in telNrs {
            var addressLabel0 = UILabel(frame: CGRectMake(20, yPos, self.view.frame.width-20, 25))
            addressLabel0.textAlignment = NSTextAlignment.Left
            addressLabel0.text = telNr
            addressLabel0.textColor = UIColor.blueColor()
            problemView.addSubview(addressLabel0)
            yPos += addressLabel0.frame.size.height+10
           // println("vk tel "+vårdKontakt.tel)
        }
        /*
        for vårdKontakt in vårdKontakter {
            var addressLabel0 = UILabel(frame: CGRectMake(20, yPos, self.view.frame.width-20, 25))
            addressLabel0.textAlignment = NSTextAlignment.Left
            addressLabel0.text = vårdKontakt.tel
            addressLabel0.textColor = UIColor.blueColor()
            problemView.addSubview(addressLabel0)
            yPos += addressLabel0.frame.size.height+10
            println("vk tel "+vårdKontakt.tel)
        }*/
        
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
        //lineChartView.animate( yAxisDuration: NSTimeInterval(1.0))

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

