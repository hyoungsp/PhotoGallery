//
//  ImageDetailViewController.swift
//  Photo Phabulous
//
//  Created by HYOUNGSUN park on 2/25/18.
//  Copyright © 2018 stanleypark. All rights reserved.
//

import UIKit
import Social
import SystemConfiguration

class ImageDetailViewController: UIViewController {

    @IBOutlet weak var detailImageView: UIImageView!
    var image = UIImage()
    var tap = UITapGestureRecognizer()
    
    @IBAction func shareImageToSocialMedia(_ sender: UIBarButtonItem) {
        if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)) {
            let vc = SLComposeViewController(forServiceType:SLServiceTypeTwitter)
            vc?.add(detailImageView.image!)
            // vc?.add(URL(string: "http://www.stachesandglasses.appspot.com"))
            // vc?.setInitialText("Initial text")
            self.present(vc!, animated: true, completion: nil)
            vc?.completionHandler = { (result:SLComposeViewControllerResult) -> Void in
                switch result {
                case SLComposeViewControllerResult.cancelled:
                    print("Cancelled")
                    break
                    
                case SLComposeViewControllerResult.done:
                    if (Reachability.isConnectedToNetwork() == true) {
                        print("photo shared.")
                        let alert = UIAlertController(title: "Photo shared on Twitter", message: "Thank you for sharing", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(action)
                        if vc?.present == nil {
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.dismiss(animated: false) { () -> Void in self.present(alert, animated: true, completion: nil) }
                        }
                    } else {
                        print("photo sharing corrupted.")
                        let alert = UIAlertController(title: "Photo not shared", message: "Internet is not connected", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(action)
                        if vc?.present == nil {
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.dismiss(animated: false) { () -> Void in self.present(alert, animated: true, completion: nil) }
                        }
                    }
                    break
                }
            }
        } else {
            let alert = UIAlertController(title: "Unable to share", message: "Please to log in to twitter account", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("______________________________________111")
        self.detailImageView.image = self.image
        // Do any additional setup after loading the view.
        tap.addTarget(self, action: #selector(ImageDetailViewController.tapped))
        detailImageView.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // make the navigation bar disappear when the image is tapped
    @objc func tapped() {
        print("_______________________________________222")
        if (self.navigationController?.isNavigationBarHidden == true) {
            navigationController?.isNavigationBarHidden = false
        } else {
            navigationController?.isNavigationBarHidden = true
        }
        //        print("tapped")
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */



public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}
