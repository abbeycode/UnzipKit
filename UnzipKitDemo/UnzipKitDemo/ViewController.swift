//
//  ViewController.swift
//  UnzipKitDemo
//
//  Created by Dov Frankel on 4/8/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func listFiles(sender: AnyObject) {
        let fileURL = NSBundle.mainBundle().URLForResource("Test Data/Test Archive", withExtension: "zip")
        let archive = UZKArchive.zipArchiveAtURL(fileURL!)
        
        do {
            let filesList = try archive.listFilenames() as? [String]
            if let list = filesList {
                self.textView.text = list.joinWithSeparator("\n")
            }
        }catch let error as NSError {
            self.textView.text = error.localizedDescription
        }
    }
}

