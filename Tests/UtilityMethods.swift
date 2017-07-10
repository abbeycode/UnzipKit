//
//  UtilityMethods.swift
//  UnzipKit
//
//  Created by Dov Frankel on 6/7/17.
//  Copyright © 2017 Abbey Code. All rights reserved.
//

import Foundation

#if os(OSX)

public enum FileSystem: String {
    case HFS  = "HFS+"
    case APFS = "APFS"
}

public func createAndMountDMG(path dmgURL: URL, source: URL, fileSystem: FileSystem) -> URL? {
    let task = Process()
    task.launchPath = "/usr/bin/hdiutil"
    
    var args = ["create",
                "-fs", fileSystem.rawValue]
    
    switch fileSystem {
    case .HFS:
        args += ["-format", "UDRW",
                 "-srcfolder", source.path]
        break;
        
    case .APFS:
        args += ["-size", "100m"]
        break;
    }
    
    args += ["-volname", dmgURL.deletingPathExtension().lastPathComponent,
             "-attach", "-plist",
             //             "-verbose",
        dmgURL.path]
    
    task.arguments = args
    
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    let errorPipe = Pipe()
    task.standardError = errorPipe
    
    let inputPipe = Pipe()
    task.standardInput = inputPipe
    inputPipe.fileHandleForWriting.write("y\n".data(using: String.Encoding.utf8)!)
    
    task.launch()
    task.waitUntilExit()
    
    let readHandle = outputPipe.fileHandleForReading
    let outputData = readHandle.readDataToEndOfFile()
    
    guard task.terminationStatus == 0 else {
        let errorHandle = errorPipe.fileHandleForReading
        let errorData = errorHandle.readDataToEndOfFile()
        
        let outputString = String(data: outputData, encoding: String.Encoding.utf8)!
        let errorString = String(data: errorData, encoding: String.Encoding.utf8)!
        
        NSLog("Failed to create and mount DMG: \(dmgURL.path)\n\n\toutput: \(outputString)\n\nerror: \(errorString)");
        return nil
    }
    
    let outputPlist = try! PropertyListSerialization.propertyList(from: outputData,
                                                                  options: [],
                                                                  format: nil)
        as! [String: Any]
    
    let entities = outputPlist["system-entities"] as! [[String:AnyObject]]
    let mountPoint: URL
    
    switch fileSystem {
    case .HFS:
        let hfsEntry = entities.filter{ $0["content-hint"] as! String == "Apple_HFS" }.first!
        let mountPointPath = hfsEntry["mount-point"] as! String
        mountPoint = URL(fileURLWithPath: mountPointPath)
        break;
        
    case .APFS:
        let mountPointEntry = entities.filter{ $0.contains { (k, v) in k == "mount-point" } }.first!
        let mountPointPath = mountPointEntry["mount-point"] as! String
        mountPoint = URL(fileURLWithPath: mountPointPath)
        
        // Need to copy the folder's contents in, since -srcfolder doesn't work. Reportedly fixed in 10.13
        let folderContents = try! FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0))
        for sourceItemURL in folderContents {
            let sourceItemPathRelativeToSource = sourceItemURL.path.replacingOccurrences(of: source.path, with: "")
            let destinationURL = mountPoint.appendingPathComponent(sourceItemPathRelativeToSource)
            try! FileManager.default.copyItem(at: sourceItemURL, to: destinationURL)
        }
        break;
    }
    
    
    return mountPoint
}


public func unmountDMG(URL mountPoint: URL) {
    let task = Process()
    task.launchPath = "/usr/bin/hdiutil"
    task.arguments = ["detach", mountPoint.path]
    
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus != 0 {
        NSLog("Failed to unmount DMG: \(mountPoint)");
    }
}

#endif
