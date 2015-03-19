//
//  ViewController.swift
//  Heat Tool
//
//  Created by E J Kalafarski on 1/14/15.
//  Copyright (c) 2015 OSHA. All rights reserved.
//

import UIKit
import CoreLocation

class HeatIndexController: GAITrackedViewController, CLLocationManagerDelegate, NSXMLParserDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var locationTextField: UITextField!
    var locationImageView = UIImageView()
    
    var temperatureImageView = UIImageView()
    @IBOutlet weak var temperatureTextField: UITextField!
    var temperatureLabel = UILabel()
    var humidityLabel = UILabel()
    
    var humidityImageView = UIImageView()
    @IBOutlet weak var humidityTextField: UITextField!
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var nowLabel: UILabel!
    @IBOutlet weak var riskButtonNow: UIButton!
    @IBOutlet weak var feelsLikeNow: UILabel!
    
    @IBOutlet weak var todaysMaxContainer: UIView!
    @IBOutlet weak var todaysMaxLabel: UILabel!
    @IBOutlet weak var todaysMaxRisk: UIButton!
    @IBOutlet weak var todaysMaxTime: UILabel!
    
    @IBOutlet var bgView: UIView!
    
    @IBOutlet weak var containerView: UIView!
    
    var locManager: CLLocationManager!
    
    var parser = NSXMLParser()
    var times = NSMutableArray()
    var temperatures = NSMutableArray()
    var humidities = NSMutableArray()
    var elements = NSMutableDictionary()
    var element = NSString()
    var buffer = NSMutableString()
    var inHourlyTemp = false
    var inHourlyHumidity = false
    
    var riskLevel = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up reference to this view for app delegate so we can refresh data when the app enters the foreground
        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate! as AppDelegate
        appDelegate.myHeatIndexController = self
        
        // View name for Google Analytics
        self.screenName = "Heat Index Screen"
        
        // Starter colors for navbar
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
        
        temperatureTextField.layer.cornerRadius = 6.0;
        humidityTextField.layer.cornerRadius = 6.0;
        
        var temperatureImageView = UIImageView(image: UIImage(named: "temperature")?.imageWithRenderingMode(.AlwaysTemplate))
        var humidityImageView = UIImageView(image: UIImage(named: "humidity")?.imageWithRenderingMode(.AlwaysTemplate))
        var locationImageView = UIImageView(image: UIImage(named: "geo")?.imageWithRenderingMode(.AlwaysTemplate))
        
        temperatureTextField.leftViewMode = UITextFieldViewMode.Always
        temperatureTextField.leftView = temperatureImageView
        humidityTextField.leftViewMode = UITextFieldViewMode.Always
        humidityTextField.leftView = humidityImageView
        locationTextField.leftViewMode = UITextFieldViewMode.Always
        locationTextField.leftView = locationImageView
        
        temperatureLabel = UILabel(frame: CGRectZero)
        temperatureLabel.backgroundColor = UIColor.clearColor()
        temperatureLabel.font = UIFont.systemFontOfSize(15)
        temperatureLabel.textColor = UIColor.blackColor()
        temperatureLabel.alpha = 1
        temperatureLabel.text = "°F"
        
        temperatureLabel.frame = CGRect(x:0, y:0, width:20, height:15)
        
        temperatureTextField.rightViewMode = UITextFieldViewMode.Always
        temperatureTextField.rightView = temperatureLabel
        
        humidityLabel = UILabel(frame: CGRectZero)
        humidityLabel.backgroundColor = UIColor.clearColor()
        humidityLabel.font = UIFont.systemFontOfSize(15)
        humidityLabel.textColor = UIColor.blackColor()
        humidityLabel.alpha = 1
        humidityLabel.text = "%"
        
        humidityLabel.frame = CGRect(x:0, y:0, width:20, height:15)
        
        humidityTextField.rightViewMode = UITextFieldViewMode.Always
        humidityTextField.rightView = humidityLabel
        
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
        self.locationTextField.delegate = self
        
        // Center button text
        self.riskButtonNow.titleLabel?.textAlignment = .Center
        self.todaysMaxRisk.titleLabel?.textAlignment = .Center
        
        // Set button images so they always respect tint color
        self.riskButtonNow.setImage(UIImage(named:"chevron")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.todaysMaxRisk.setImage(UIImage(named:"chevron")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        
        // Set up location manager for getting our location
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization();
    }
    
    // Update state with the user's location on load
    func locationManager(manager: CLLocationManager!,didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            self.locationActivityIndicator.startAnimating()
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        locManager.stopUpdatingLocation()
        
        println("http://forecast.weather.gov/MapClick.php?lat=\(locations[locations.count-1].coordinate.latitude)&lon=\(locations[locations.count-1].coordinate.longitude)&FcstType=digitalDWML")
        
        times = []
        temperatures = []
        humidities = []
        parser = NSXMLParser(contentsOfURL: (NSURL(string: "http://forecast.weather.gov/MapClick.php?lat=\(locations[locations.count-1].coordinate.latitude)&lon=\(locations[locations.count-1].coordinate.longitude)&FcstType=digitalDWML")))!
//        parser = NSXMLParser(contentsOfURL: (NSURL(string: "http://forecast.weather.gov/MapClick.php?lat=30.129592,&lon=-83.909629&FcstType=digitalDWML")))!
        parser.delegate = self
        parser.parse()
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        element = elementName
        
        buffer = NSMutableString.alloc()
        buffer = ""
        
        if (attributeDict["type"] != nil) {
            if attributeDict["type"] as NSString == "hourly" {
                inHourlyTemp = true
            }
        }
        
        if elementName == "humidity" {
            inHourlyHumidity = true
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        buffer.appendString(string)
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if elementName == "description" || elementName == "area-description" {
            self.locationTextField.text = buffer
        }
        
        if elementName == "start-valid-time" {
            times.addObject(buffer)
        }
        
        if elementName == "value" && inHourlyTemp {
            temperatures.addObject(buffer)
        }
        
        if elementName == "value" && inHourlyHumidity {
            humidities.addObject(buffer)
        }
        
        if elementName == "temperature" && inHourlyTemp {
            inHourlyTemp = false
        }
        
        if elementName == "humidity" {
            inHourlyHumidity = false
        }
        
        // If parsing is complete
        if elementName == "dwml" {
            // Set current temperature and humidity to the first hour in the forecast
            self.temperatureTextField.text = temperatures[0] as NSString
            self.humidityTextField.text = humidities[0] as NSString
            
            // Look for the maximum in the next 12 hours
            var maxIndex = -1
            var maxTime:String = ""
            var maxHeatIndex = -1000.0
            for index in 0...23 {
                var newTime = (times[index] as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                let newDateFormatter = NSDateFormatter()
                newDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
                let newDate = newDateFormatter.dateFromString(newTime)
                newDateFormatter.dateFormat = "h:mm a"
                var newHour = newDateFormatter.stringFromDate(newDate!)
                
                if newHour == "12:00 AM" {
                    break
                }
                
                var newTempDouble = (temperatures[index] as NSString).doubleValue
                var newHumidityDouble = (humidities[index] as NSString).doubleValue
                var newHeatIndex = calculateHeatIndex(newTempDouble, humidity: newHumidityDouble)
                
                println("Hour \(index): Time: \(newHour) Temp: \(temperatures[index]), Humidity: \(humidities[index])")

                if newTempDouble > 80.0 && newHeatIndex > maxHeatIndex {
                    maxIndex = index
                    maxHeatIndex = newHeatIndex
                    maxTime = newTime
                }
            }
            println("Max \(maxIndex): Heat: \(maxHeatIndex)")
            
            // Risk won't be greater than minimal for the rest of the day
            if maxIndex == -1 {
                self.todaysMaxRisk.setTitle("Minimal Risk\nFrom Heat", forState: .Normal)
                self.todaysMaxTime.text = ""
            // The risk now is the highest for the rest of the day
            } else if maxIndex == 0 {
                switch maxHeatIndex {
                case 0..<91:
                    self.todaysMaxRisk.setTitle("Lower Risk\n(Use Caution)", forState: .Normal)
                case 91..<104:
                    self.todaysMaxRisk.setTitle("Moderate Risk", forState: .Normal)
                case 104..<116:
                    self.todaysMaxRisk.setTitle("High\nRisk", forState: .Normal)
                case 116..<1000:
                    self.todaysMaxRisk.setTitle("Very High To Extreme Risk", forState: .Normal)
                default:
                    println("default")
                }
                
                self.todaysMaxTime.text = "Now"
            // There's a higher risk coming
            } else {
                switch maxHeatIndex {
                case 0..<91:
                    self.todaysMaxRisk.setTitle("Lower Risk\n(Use Caution)", forState: .Normal)
                case 91..<104:
                    self.todaysMaxRisk.setTitle("Moderate Risk", forState: .Normal)
                case 104..<116:
                    self.todaysMaxRisk.setTitle("High\nRisk", forState: .Normal)
                case 116..<1000:
                    self.todaysMaxRisk.setTitle("Very High To Extreme Risk", forState: .Normal)
                default:
                    println("default")
                }
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
                println(maxTime)
                let date = dateFormatter.dateFromString(maxTime)
                println(date)
                dateFormatter.dateFormat = "h:mm a"
                self.todaysMaxTime.text = "At \(dateFormatter.stringFromDate(date!))"
            }
            
            // Switch temperature and humidity fields to auto-filled styling
            self.temperatureTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.0)
            self.humidityTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.0)
            
            UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
                self.todaysMaxContainer.alpha = 1
                
                // Disable precautions button if minimal risk state
                if (self.todaysMaxRisk.titleLabel?.text == "Minimal Risk\nFrom Heat") {
                    self.todaysMaxRisk.enabled = false
                } else {
                    self.todaysMaxRisk.enabled = true
                }

                }, completion: nil)
            
            self.locationActivityIndicator.stopAnimating()
            
            self.updateRiskLevel()
        }
    }
    
    func calculateHeatIndex(tempInF: Double, humidity: Double) -> Double {
        var calculatedHeatIndexF = 0.0
        
        // Broke the formula up in pieces since its orginal incarnation was causing problems with Xcode
        calculatedHeatIndexF = -42.379 + (2.04901523 * tempInF)
        calculatedHeatIndexF += 10.14333127 * humidity
        calculatedHeatIndexF -= 0.22475541 * tempInF * humidity
        calculatedHeatIndexF -= 6.83783 * pow(10, -3) * pow(tempInF,2)
        calculatedHeatIndexF -= 5.481717 * pow(10,-2) * pow(humidity,2)
        calculatedHeatIndexF += 1.22874 * pow(10, -3) * pow(tempInF,2) * humidity
        calculatedHeatIndexF += 8.5282 * pow(10,-4) * tempInF * pow(humidity,2)
        calculatedHeatIndexF -= 1.99 * pow(10,-6) * pow(tempInF, 2) * pow(humidity, 2)
        
        return calculatedHeatIndexF
    }
    
    func updateRiskLevel() {
        var tempInF = Double(temperatureTextField.text.toInt()!)
        var humidity = Double(humidityTextField.text.toInt()!)
        var calculatedHeatIndexF = 0.0
        
        var backgroundColor = UIColor()
        var buttonColor = UIColor()
        var labelColor = UIColor()
        var disabledColor = UIColor()
        var riskTitleString = ""
        
        // If the temperature is below 80 degrees, the heat index does not apply.
        if tempInF < 80 {
            self.riskLevel = 0
            riskTitleString = "Minimal Risk From Heat"
            
            backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
            buttonColor = UIColor.blackColor()
            labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            disabledColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.2)
        } else {
            calculatedHeatIndexF = calculateHeatIndex(tempInF, humidity: humidity)
            
            switch Int(calculatedHeatIndexF) {
            case 0..<91:
                self.riskLevel = 1
                riskTitleString = "Lower Risk (Use Caution)"
                
                backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
                buttonColor = UIColor.blackColor()
                labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
                disabledColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.3)
            case 91..<104:
                self.riskLevel = 2
                riskTitleString = "Moderate Risk"
                
                backgroundColor = UIColor(red: 1.0, green: 0.675, blue: 0.0, alpha: 1.0)
                buttonColor = UIColor.blackColor()
                labelColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
                disabledColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.3)
            case 104..<116:
                self.riskLevel = 3
                riskTitleString = "High\nRisk"

                backgroundColor = UIColor.orangeColor()
                buttonColor = UIColor.whiteColor()
                labelColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
                disabledColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.4)
            case 116..<1000:
                self.riskLevel = 4
                riskTitleString = "Very High To Extreme Risk"
                
                backgroundColor = UIColor.redColor()
                buttonColor = UIColor.whiteColor()
                labelColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
                disabledColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.4)
            default:
                println("default")
            }
        }
        
        // Update the interface
        UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
            
            // Set text
            self.riskButtonNow.setTitle(riskTitleString, forState: .Normal)
            if self.locationTextField.text == "" {
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
            
            self.locationActivityIndicator.color = buttonColor
            
            // Change label colors
            self.temperatureLabel.textColor = labelColor
            self.humidityLabel.textColor = labelColor
            self.nowLabel.textColor = labelColor
            self.feelsLikeNow.textColor = labelColor
            self.todaysMaxLabel.textColor = labelColor
            self.todaysMaxTime.textColor = labelColor
            
            // Change button colors
            self.view.tintColor = buttonColor
            self.navigationController?.navigationBar.tintColor = buttonColor
            self.navigationController?.navigationBar.barStyle = (buttonColor == UIColor.blackColor() ? UIBarStyle.Default : UIBarStyle.Black)
            self.locationTextField.textColor = buttonColor
            self.temperatureTextField.textColor = buttonColor
            self.humidityTextField.textColor = buttonColor
            
            // Disable precautions button if minimal risk state
            if (self.riskLevel == 0) {
                self.riskButtonNow.enabled = false
                self.riskButtonNow.setTitleColor(disabledColor, forState: .Normal)
                self.riskButtonNow.imageView?.alpha = 0
            } else {
                self.riskButtonNow.enabled = true
                self.riskButtonNow.setTitleColor(buttonColor, forState: .Normal)
                self.riskButtonNow.imageView?.alpha = 1
            }
            
            if self.todaysMaxRisk.enabled == false {
                self.todaysMaxRisk.setTitleColor(disabledColor, forState: .Normal)
                self.todaysMaxRisk.imageView?.alpha = 0
            } else {
                self.todaysMaxRisk.setTitleColor(buttonColor, forState: .Normal)
                self.todaysMaxRisk.imageView?.alpha = 1
            }
            
            }, completion: nil)
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        // When location field is tapped
        if textField == locationTextField {
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse {
                self.locationActivityIndicator.startAnimating()
                self.locManager.startUpdatingLocation()
            } else {
                let alertController = UIAlertController(
                    title: "Location Access Disabled",
                    message: "To get your local conditions, visit settings to allow the OSHA Heat Safety Tool to use your location when the app is in use.",
                    preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                alertController.addAction(cancelAction)
                
                let openAction = UIAlertAction(title: "Settings", style: .Default) { (action) in
                    if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
                alertController.addAction(openAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            }

            return false
        } else {
            return true
        }
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
        
        self.locationTextField.text = ""
        
        // Change backgrounds of text fields to show they're in "manual" mode
        self.temperatureTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        self.humidityTextField.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        
        // Hide "today's max" for user-entered values
        UIView.animateWithDuration(0.75, delay: 0.0, options: nil, animations: {
            self.todaysMaxContainer.alpha = 0
            }, completion: nil)
        
        updateRiskLevel()
    }
    
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
        if (segue.identifier == "nowPrecautionsSegue") {
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
        
        if (segue.identifier == "todaysMaxPrecautionsSegue") {
            var svc = segue.destinationViewController as PrecautionsController
            if let text = self.todaysMaxRisk.titleLabel?.text {
                switch text {
                case "Lower Risk\n(Use Caution)":
                    svc.precautionLevel = "precautions_lower"
                case "Moderate Risk":
                    svc.precautionLevel = "precautions_moderate"
                case "High\nRisk":
                    svc.precautionLevel = "precautions_high"
                case "Very High To Extreme Risk":
                    svc.precautionLevel = "precautions_veryhigh"
                default:
                    svc.precautionLevel = "precautions_lower"
                }
            }
        }
        
        if (segue.identifier == "moreInfoSegue") {
            var svc = segue.destinationViewController as UINavigationController
            
            // Set tint color of the incoming more info navigation controller to match the app state
            if (self.riskLevel == 0) {
                svc.navigationBar.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            } else {
                svc.navigationBar.tintColor = self.bgView.backgroundColor
            }
        }
    }
}

