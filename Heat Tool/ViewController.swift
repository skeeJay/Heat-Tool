//
//  ViewController.swift
//  Heat Tool
//
//  Created by E J Kalafarski on 1/14/15.
//  Copyright (c) 2015 OSHA. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, NSXMLParserDelegate, UITextFieldDelegate {
    
//    let newForecast = Weather(lat: "38.893554",long: "-78.015232")

    @IBOutlet weak var temperatureButton: UIButton!
    @IBOutlet weak var temperatureTextField: UITextField!
    @IBOutlet weak var humidityButton: UIButton!
    @IBOutlet weak var humidityTextField: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var nowLabel: UILabel!
    @IBOutlet weak var riskButtonNow: UIButton!
    @IBOutlet weak var feelsLikeNow: UILabel!
    
    @IBOutlet weak var todaysMaxContainer: UIView!
    @IBOutlet weak var todaysMaxLabel: UILabel!
    @IBOutlet weak var todaysMaxRisk: UILabel!
    @IBOutlet weak var todaysMaxTime: UILabel!
    
    @IBOutlet var bgView: UIView!
    
    @IBOutlet weak var containerView: UIView!
    
    var locManager: CLLocationManager!
    
    var parser = NSXMLParser()
    var posts = NSMutableArray()
    var elements = NSMutableDictionary()
    var element = NSString()
    var buffer = NSMutableString()
    
    var riskLevel = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Starter colors for navbar
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        // Set up toolbar for keyboard
        var doneToolbar: UIToolbar = UIToolbar()
        doneToolbar.barStyle = UIBarStyle.Default
        
        var flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        var done: UIBarButtonItem = UIBarButtonItem(title: "Set", style: UIBarButtonItemStyle.Done, target: self, action: Selector("doneButtonAction"))
        
        var items = NSMutableArray()
        items.addObject(flexSpace)
        items.addObject(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.temperatureTextField.inputAccessoryView = doneToolbar
        self.humidityTextField.inputAccessoryView = doneToolbar
        
        // Set up text input field handlers
        self.temperatureTextField.delegate = self
        self.humidityTextField.delegate = self
        
        // Move risk button chevron to the right
        self.riskButtonNow.titleLabel?.textAlignment = .Center
        self.riskButtonNow.imageEdgeInsets = UIEdgeInsetsMake(0, 215, 0, 0);
        self.riskButtonNow.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 30);
        
        // Set button images so they always respect tint color
        self.locationButton.setImage(UIImage(named:"geo")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.temperatureButton.setImage(UIImage(named:"temperature")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.humidityButton.setImage(UIImage(named:"humidity")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.riskButtonNow.setImage(UIImage(named:"chevron")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        
        // Set up location manager for getting our location
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization();
    }
    
//    func locationManager(manager: CLLocationManager!,didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
//            self.locationActivityIndicator.startAnimating()
//            manager.startUpdatingLocation()
//        }
//    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        locManager.stopUpdatingLocation()
        
        print("http://forecast.weather.gov/MapClick.php?lat=\(locations[locations.count-1].coordinate.latitude)&lon=\(locations[locations.count-1].coordinate.longitude)&FcstType=digitalDWML")
        
        posts = []
        parser = NSXMLParser(contentsOfURL: (NSURL(string: "http://forecast.weather.gov/MapClick.php?lat=\(locations[locations.count-1].coordinate.latitude)&lon=\(locations[locations.count-1].coordinate.longitude)&FcstType=digitalDWML")))!
        parser.delegate = self
        parser.parse()
        
//        self.newForecast.latitude = "\(locations[locations.count-1].coordinate.latitude)"
//        self.newForecast.longitude = "\(locations[locations.count-1].coordinate.longitude)"
//
//        // get data
//        self.newForecast.refreshWeatherData()
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!)
    {
        element = elementName

        buffer = NSMutableString.alloc()
        buffer = ""
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        buffer.appendString(string)
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if (elementName as NSString).isEqualToString("description") {
            self.locationButton.setTitle(buffer, forState: .Normal)
            self.locationButton.alpha = 1
            
            self.temperatureTextField.text = "34"
            self.humidityTextField.text = "41"
            
            self.temperatureTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.0)
            self.humidityTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.0)
            
            UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
                self.todaysMaxContainer.alpha = 1
                }, completion: nil)
            
            self.locationActivityIndicator.stopAnimating()

            self.updateRiskLevel()
        }
    }
    
    func updateRiskLevel() {
        var tempInF = Double(temperatureTextField.text.toInt()!)
        var humidity = Double(humidityTextField.text.toInt()!)
        var calculatedHeatIndexF = 0.0
        
        var backgroundColor = UIColor()
        var buttonColor = UIColor()
        var labelColor = UIColor()
        var riskTitleString = ""
        
        // If the temperature is below 80 degrees, the heat index does not apply.
        if tempInF < 80 {
            self.riskLevel = 0
            riskTitleString = "Minimal Risk From Heat"
            
            backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
            buttonColor = UIColor.blackColor()
            labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        } else {
            // Broke the formula up in pieces since its orginal incarnation was causing problems with Xcode
            calculatedHeatIndexF = -42.379 + (2.04901523 * tempInF)
            calculatedHeatIndexF += 10.14333127 * humidity
            calculatedHeatIndexF -= 0.22475541 * tempInF * humidity
            calculatedHeatIndexF -= 6.83783 * pow(10, -3) * pow(tempInF,2)
            calculatedHeatIndexF -= 5.481717 * pow(10,-2) * pow(humidity,2)
            calculatedHeatIndexF += 1.22874 * pow(10, -3) * pow(tempInF,2) * humidity
            calculatedHeatIndexF += 8.5282 * pow(10,-4) * tempInF * pow(humidity,2)
            calculatedHeatIndexF -= 1.99 * pow(10,-6) * pow(tempInF, 2) * pow(humidity, 2)
            
            switch Int(calculatedHeatIndexF) {
            case 0..<91:
                self.riskLevel = 1
                riskTitleString = "Lower Risk (Use Caution)"
                
                backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
                buttonColor = UIColor.blackColor()
                labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            case 91..<104:
                self.riskLevel = 2
                riskTitleString = "Moderate Risk"
                
                backgroundColor = UIColor(red: 1.0, green: 0.675, blue: 0.0, alpha: 1.0)
                buttonColor = UIColor.blackColor()
                labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            case 104..<116:
                self.riskLevel = 3
                riskTitleString = "High\nRisk"

                backgroundColor = UIColor.orangeColor()
                buttonColor = UIColor.whiteColor()
                labelColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
            case 116..<1000:
                self.riskLevel = 4
                riskTitleString = "Very High To Extreme Risk"
                
                backgroundColor = UIColor.redColor()
                buttonColor = UIColor.whiteColor()
                labelColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
            default:
                println("default")
            }
        }
        
        // Update the interface
        UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
            
            // Set text
            self.riskButtonNow.setTitle(riskTitleString, forState: .Normal)
            if self.locationButton.titleLabel?.text == "User Entered Data" {
                self.locationButton.alpha = buttonColor == UIColor.blackColor() ? 0.2 : 0.5
                self.nowLabel.text = "Calculated"
                self.feelsLikeNow.text = "Would Feel Like \(Int(calculatedHeatIndexF))º F"
            } else {
                self.nowLabel.text = "Now"
                self.feelsLikeNow.text = "Feels Like \(Int(calculatedHeatIndexF))º F"
            }
            
            // Hide "feels like" text if we're below the heat index threshold
            self.feelsLikeNow.alpha = self.riskLevel == 0 ? 0 : 1
            
            // Change background colors
            self.bgView.backgroundColor = backgroundColor
            self.navigationController?.navigationBar.barTintColor = backgroundColor
            
            // Change label colors
            self.nowLabel.textColor = labelColor
            self.feelsLikeNow.textColor = labelColor
            self.todaysMaxLabel.textColor = labelColor
            self.todaysMaxRisk.textColor = labelColor
            self.todaysMaxTime.textColor = labelColor
            
            // Change button colors
            self.view.tintColor = buttonColor
            self.temperatureTextField.textColor = buttonColor
            self.humidityTextField.textColor = buttonColor
            self.navigationController?.navigationBar.tintColor = buttonColor
            self.navigationController?.navigationBar.barStyle = (buttonColor == UIColor.blackColor() ? UIBarStyle.Default : UIBarStyle.Black)
            
            // I'm not sure why these aren't being inherited from the view tint
            self.locationButton.setTitleColor(buttonColor, forState: .Normal)
            self.riskButtonNow.setTitleColor(buttonColor, forState: .Normal)
            
            }, completion: nil)
    }

    @IBAction func focusLocation(sender: AnyObject) {
        var alert = UIAlertController(title: "Use My Location", message: "Get conditions at your current location?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Use My Location", style: .Default, handler: { action in
            self.locationActivityIndicator.startAnimating()
            self.locManager.startUpdatingLocation()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func focusTemperature(sender: AnyObject) {
        temperatureTextField.becomeFirstResponder()
    }
    
    @IBAction func focusHumidity(sender: AnyObject) {
        humidityTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(sender: AnyObject) {
        sender.resignFirstResponder()
        
        updateRiskLevel()
    }

    func doneButtonAction() {
        self.temperatureTextField.endEditing(true)
        self.humidityTextField.endEditing(true)
        
        // If a field has been left blank, default it to 0
        if self.temperatureTextField.text == "" {
            self.temperatureTextField.text = "0"
        }
        if self.humidityTextField.text == "" {
            self.humidityTextField.text = "0"
        }
        
        self.locationButton.setTitle("User Entered Data", forState: .Normal)
        
        // Change backgrounds of text fields to show they're in "manual" mode
        self.temperatureTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        self.humidityTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        
        // Hide "today's max" for user-entered values
        UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
            self.todaysMaxContainer.alpha = 0
            }, completion: nil)
        
        updateRiskLevel()
    }
    
//    func didCompleteForecast() {
////        NSLog("%d", self.newForecast.sevenDayForecast[0].maxHeatIndex)
//
//        var humid = self.newForecast.sevenDayForecast[0].humidity[0]
//        humidityButton.setTitle(String(humid) + "%", forState: .Normal)
//        locationButton.setTitle(self.newForecast.locationDescription, forState: .Normal)
//        
////        let maxHeatIndex = self.newForecast.sevenDayForecast[0].maxHeatIndex
////        println("max heat index for today is \(self.newForecast.sevenDayForecast[0].maxHeatIndex)")
//        var currentTemp = Int(self.newForecast.sevenDayForecast[0].temperature[0]["F"]!)
////        println("current temperature is \(currentTemp)")
//        let currentHeatIndex = Int(self.newForecast.sevenDayForecast[0].heatIndex[0]["F"]!)
//        let currentWindChill = Int(self.newForecast.sevenDayForecast[0].windChill[0]["F"]!)
////        println("current heat index is \(currentHeatIndex)")
////        dispatch_async(dispatch_get_main_queue()) {
////            switch currentTemp {
////            case 80..<180:
////                self.riskType.text = "Heat Index:"
////                self.perceivedTemperatureValue.text = "\(currentHeatIndex)"
////                switch currentHeatIndex {
////                case 116..<180:
////                    self.riskValue.text = "Extreme"
////                case 104..<116:
////                    self.riskValue.text = "high"
////                case 91..<104:
////                    self.riskValue.text = "moderate"
////                default:
////                    self.riskValue.text = "lower"
////                }
////            case -100..<50:
////                self.riskType.text = "Wind Chill:"
////                self.perceivedTemperatureValue.text = "\(currentWindChill)"
////            default:
////                self.riskType.text = "Temperature:"
////                println(currentTemp)
////                self.perceivedTemperatureValue.text = "\(currentTemp)"
////            }
////        }
//        
//        temperatureButton.setTitle(String(currentTemp) + "º F", forState: .Normal)
//        feelsLikeNow.text = "Feels Like \(currentWindChill)º F"
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openOSHAWebsite(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://www.osha.gov")!)
    }
    
    @IBAction func openDOLWebsite(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://www.dol.gov")!)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "precautionsSegue") {
            var svc = segue.destinationViewController as PrecautionsController
            switch riskLevel {
            case 1:
                svc.precautionLevel = "precautions_lower"
            case 2:
                svc.precautionLevel = "precautions_moderate"
            case 3:
                svc.precautionLevel = "precautions_high"
            case 4:
                svc.precautionLevel = "precautions_veryhigh"
            default:
                svc.precautionLevel = "precautions_lower"
            }
        }
    }
}

