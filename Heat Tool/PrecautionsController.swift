//
//  PrecautionsController.swift
//  Heat Tool
//
//  Created by E J Kalafarski on 2/17/15.
//  Copyright (c) 2015 OSHA. All rights reserved.
//

import UIKit

class PrecautionsController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var localfilePath = NSURL()
    var precautionLevel = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let localfilePath = NSBundle.mainBundle().URLForResource(precautionLevel, withExtension: "html")
        let myRequest = NSURLRequest(URL: localfilePath!)
        webView.loadRequest(myRequest)
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
