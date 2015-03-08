//
//  WebViewController.swift
//  Heat Tool
//
//  Created by E J Kalafarski on 2/28/15.
//  Copyright (c) 2015 OSHA. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var localfilePath = NSURL()
    var infoContent = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = infoContent

        // Do any additional setup after loading the view.
        var localFilePath = NSBundle.mainBundle().pathForResource(infoContent
            , ofType: "html")
        var contents = NSString(contentsOfFile: localFilePath!, encoding: NSUTF8StringEncoding, error: nil)
        
        // Set the base URL for the web view so we can access resources
        var path = NSBundle.mainBundle().bundlePath
        var baseUrl  = NSURL.fileURLWithPath("\(path)")
        
        webView.loadHTMLString(contents, baseURL: baseUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
