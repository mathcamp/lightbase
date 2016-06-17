//
//  TodoTableViewController.swift
//  Todotastic
//
//  Created by Ben Garrett on 6/17/16.
//  Copyright © 2016 Highlight. All rights reserved.
//

import Foundation
import UIKit

class TodoTableViewController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(newButtonTapped))
  }
  
}


extension TodoTableViewController {
  func newButtonTapped(item: UIBarButtonItem) {
    print("THEY CALLED NEW!")
  }
}

extension TodoTableViewController {

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    print("THEY SELECTED A ROW")
  }
  
}

extension TodoTableViewController {
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let tableViewCell = UITableViewCell()
    tableViewCell.textLabel?.text = "Foo?"
    return tableViewCell
  }
}