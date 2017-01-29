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

    @IBAction func listFiles(_ sender: AnyObject) {
        let fileURL = Bundle.main.url(forResource: "Test Data/Test Archive", withExtension: "zip")!
        
        do {
            let archive = try! UZKArchive(url: fileURL)
            let filesList = try archive.listFilenames()
            self.textView.text = filesList.joined(separator: "\n")
        } catch let error as NSError {
            self.textView.text = error.localizedDescription
        }
    }

}

