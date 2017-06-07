//
//  UtilityMethods.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/7/17.
//  Copyright © 2017 Abbey Code. All rights reserved.
//

import Foundation


func createAndMountDMG(path dmgURL: URL, source: URL) -> String? {
    let task = Process()
    task.launchPath = "/usr/bin/hdiutil"
    task.arguments = ["create",
                      "-fs", "HFS+",
                      "-format", "UDRW",
                      "-volname", dmgURL.deletingPathExtension().lastPathComponent,
                      "-srcfolder", source.path,
                      "-attach", "-plist",
                      dmgURL.path]
    
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus != 0 {
        NSLog("Failed to create and mount DMG: \(dmgURL.path)");
        return nil
    }
    
    let readHandle = outputPipe.fileHandleForReading
    let outputData = readHandle.readDataToEndOfFile()
    let outputPlist = try! PropertyListSerialization.propertyList(from: outputData,
                                                                  options: [],
                                                                  format: nil)
        as! [String: Any]
    
    let entities = outputPlist["system-entities"] as! [[String:AnyObject]]
    let hfsEntry = entities.filter{ $0["content-hint"] as! String == "Apple_HFS" }.first!
    let mountPoint = hfsEntry["mount-point"] as! String
    
    return mountPoint
}

func unmountDMG(_ mountPoint: String) {
    let task = Process()
    task.launchPath = "/usr/bin/hdiutil"
    task.arguments = ["detach", mountPoint]
    
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus != 0 {
        NSLog("Failed to unmount DMG: \(unmountDMG)");
    }
}
