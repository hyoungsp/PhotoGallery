//
//  SharedNetworking.swift
//  Photo Phabulous
//
//  Created by HYOUNGSUN park on 2/25/18.
//  Copyright © 2018 stanleypark. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration

var imageCache = NSCache<AnyObject, UIImage>.sharedInstance

//Error Type
enum networkError: Error {
    case Connection
}

class SharedNetworking {
    
    static let sharedInstance = SharedNetworking()
    let username: String
    let urlString: String
    init() {
        username = "hyoungsun"
        urlString = "http://stachesandglasses.appspot.com/user/\(username)/json/"
    }
    
    func connectionToNetwork() throws {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            throw networkError.Connection
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            throw networkError.Connection
        }
        

        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        if ret == false {
            throw networkError.Connection
        }
        
    }
    //    let images_cache = NSCache<AnyObject, UIImage>.sharedInstance
    
    var images = [String]()
    
    func createDirectory(){
        let fileManager = FileManager.default
        let filePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("phabulous")
        if !fileManager.fileExists(atPath: filePath){
            try! fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        }else{
            print("Dictionary Already Created.")
        }
    }
    
    //: # Prototype function to retrieve JSON and pass the results to a completion block
    func get_image(url: String, completion:@escaping ([String]?) -> Void) {
        var imageArray = [String]()
 
        guard let url = URL(string: url) else {
            //  fatalError("Unable to create NSURL from string")
            //            self.showAlert()
            completion(nil)
            return
        }
        
        // Create a vanilla url session
        let session = URLSession.shared
        
        // Create a data task
        let task = session.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
            
            // Ensure there were no errors returned from the request
            guard error == nil else {
        
                completion(nil)
                return
            }
            
            // Ensure there is data and unwrap it
            guard let data = data else {
    
                completion(nil)
                return
            }
            
            
            AppFileManager.sharedInstance.saveToFile(data: data)
            
      
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                //                print(json)
                
                // Cast JSON as an array of dictionaries
                guard let results = json as? [String: AnyObject] else {
    
                    completion(nil)
                    return
                }
                let arrayOfImage = results["results"] as? [[String: AnyObject]]
                
                // parse json
                for json in arrayOfImage! {
                    
                    var url = json["image_url"] as? String
                    
                    if (url != nil) {
                        url = "http://stachesandglasses.appspot.com/" + url!
                        imageArray.append(url!)
                    }
                    
                }

                completion(imageArray)
                
                
            } catch {
                print("error serializing JSON: \(error)")
                completion(nil)
                return
            }
        })
        
        // Tasks start off in suspended state, we need to kick it off
        task.resume()
    }
    
    func uploadRequest(user: NSString, image: UIImage, caption: NSString, completion:@escaping ([String]?) -> Void){
        var imageArray = [String]()
        do {
            try connectionToNetwork()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let boundary = generateBoundaryString()
            let scaledImage = resize(image: image, scale: 0.1)
            let imageJPEGData = UIImageJPEGRepresentation(scaledImage,0.1)
            
            guard let imageData = imageJPEGData else {
                completion(nil)
                return
            }
            
            // Create the URL, the user should be unique
            let url = NSURL(string: "http://stachesandglasses.appspot.com/post/\(user)/")
            
            // Create the request
            let request = NSMutableURLRequest(url: url! as URL)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Set the type of the data being sent
            let mimetype = "image/jpeg"
            // This is not necessary
            let fileName = "test.png"
            
            // Create data for the body
            let body = NSMutableData()
            body.append("\r\n--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            
            // Caption data
            body.append("Content-Disposition:form-data; name=\"caption\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("CaptionText\r\n".data(using: String.Encoding.utf8)!)
            
            // Image data
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition:form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: String.Encoding.utf8)!)
            
            // Trailing boundary
            body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
            
            // Set the body in the request
            request.httpBody = body as Data
            
            // Create a data task
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                // Need more robust errory handling here
                // 200 response is successful post
                //            print(error!)
                guard response != nil else{
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    completion(nil)
                    return
                }
                //            print(response)
                
                if let error = error{
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    print(error)
                    completion(nil)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    //                print(json)
                    
                    // Cast JSON as an array of dictionaries
                    guard let results = json as? [String: AnyObject] else {
                        // fatalError("We couldn't cast the JSON to a dictionary")
                        completion(nil)
                        return
                    }
                    let arrayOfImage = results["results"] as? [[String: AnyObject]]
                    
                    // parse json
                    for json in arrayOfImage! {
                        
                        var url = json["image_url"] as? String
                        
                        if (url != nil) {
                            url = "http://stachesandglasses.appspot.com/" + url!
                  
                            imageArray.insert(url!, at: 0)
                        }
                        
                    }
                    completion(imageArray)
                } catch {
                    print("error serializing JSON: \(error)")
                    // self.showAlert("connection")
                    completion(nil)
                    return
                }
                
            }
            
            task.resume()
        } catch let error {
            completion(nil)
            print("error: \(error.localizedDescription)")
        }
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    /// based on session6 playground
    func resize(image: UIImage, scale: CGFloat) -> UIImage {
        let size = image.size.applying(CGAffineTransform(scaleX: scale,y: scale))
        let hasAlpha = true
        
        // Automatically use scale factor of main screen
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
}
