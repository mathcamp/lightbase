//
//  ViewController.swift
//  HLDB-Demo
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Highlight. All rights reserved.
//

import UIKit
import hldb

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var data: [String]? {
        willSet {
            
        }
        didSet {
            tableView.reloadData()
            if data!.count > 0 {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: data!.count - 1, inSection: 0), atScrollPosition: .Bottom, animated: true)
            }
        }
    }
    
    let database = HLDB.DB(fileName: "superNecessaryDateDatabase")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func insertObjectsButtonWasHit(sender: UIButton) {
        if let num = (split(sender.titleLabel!.text!) { $0 == " " }).last?.toInt() {
            if data == nil {
                data = [String]()
            }
            let start = NSDate()
            data! += (0..<num).map { "\($0 + 1))" }
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        
        cell.textLabel!.text = data![indexPath.row]
        return cell
        
    }
}

