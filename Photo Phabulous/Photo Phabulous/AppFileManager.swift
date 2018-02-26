//
//  AppFileManager.swift
//  Photo Phabulous
//
//  Created by HYOUNGSUN park on 2/25/18.
//  Copyright © 2018 stanleypark. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class AppFileManager {
    static let sharedInstance = AppFileManager()
    
    /// attribute: http://www.techotopia.com/index.php/Working_with_Files_in_Swift_on_iOS_8
    // save to file in documents
    func saveToFile(data:Data){
        
        let docDirectPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let docsDirectPath = NSURL(string: docDirectPath) else {return}
        guard let jsonFilePath = docsDirectPath.appendingPathComponent("phabulous.json") else {return}
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            let created = fileManager.createFile(atPath: jsonFilePath.absoluteString, contents: nil, attributes: nil)
            if created {
                print("File created")
            } else {
                print("File cannot be created")
            }
        } else {
            print("File already exists")
        }
        
        do {
            let file = try FileHandle(forWritingTo: jsonFilePath)
            file.write(data as Data)
            print("Data written")
        }
        catch let error as NSError {
            print("Couldn't write to file: \(error.localizedDescription)")
        }
    }
    
    // read data from file
    func getCoreFile() -> Data?{
        let docDirectPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let docsDirectPath = NSURL(string: docDirectPath) else { return nil}
        guard let jsonFilePath = docsDirectPath.appendingPathComponent("phabulous.json") else { return nil }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        if fileManager.fileExists(atPath: jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            do{
                let file = try FileHandle(forReadingFrom: jsonFilePath)
                print("Data read from file")
                return file.readDataToEndOfFile()
            }
            catch let error as NSError {
                print("Couldn't read from file: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
}
