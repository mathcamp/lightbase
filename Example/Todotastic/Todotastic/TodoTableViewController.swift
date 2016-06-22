//
//  TodoTableViewController.swift
//  Todotastic
//
//  Created by Ben Garrett on 6/17/16.
//  Copyright © 2016 Highlight. All rights reserved.
//

import Foundation
import UIKit

enum EditState {
  case NotEditing
  case Editing(TodoTableViewCell)
}

struct TodoItem {
  var label: String = "Unlabeled"
  var checked: Bool = false
}

class TodoTableViewController: UITableViewController {
  
  var editState: EditState = .NotEditing
  var todoList: [TodoItem] = [TodoItem(label: "Meet w/ Jennifer for breakfast", checked: false),
                              TodoItem(label: "Present at beach", checked: false),
                              TodoItem(label: "Build something beautiful", checked: false)]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(newButtonTapped))
    
    let longpress = UILongPressGestureRecognizer(target: self, action: #selector(TodoTableViewController.longPressGestureRecognized(_:)))
    tableView.addGestureRecognizer(longpress)
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(newButtonTapped), forControlEvents: UIControlEvents.ValueChanged)
    refreshControl.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    self.refreshControl = refreshControl
    
    
    
    
  }
  
  
  override func tableView(tableView: UITableView,
                            editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    
    let more = UITableViewRowAction(style: .Normal, title: "Check") { action, index in
      print("more button tapped")
    }
    more.backgroundColor = UIColor(red:0.75, green: 0, blue:0.5, alpha:1.0)
    
    let deleteButton = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
      self.todoList.removeAtIndex(indexPath.row);
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic);
    
    }
    deleteButton.backgroundColor = UIColor.blueColor()
    
    return [deleteButton, more]
  }
  
}


extension TodoTableViewController {
  
  
  
  
  func snapshopOfCell(inputView: UIView) -> UIView {
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
    inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext() as UIImage
    UIGraphicsEndImageContext()
    let cellSnapshot : UIView = UIImageView(image: image)
    cellSnapshot.layer.masksToBounds = false
    cellSnapshot.layer.cornerRadius = 0.0
    cellSnapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
    cellSnapshot.layer.shadowRadius = 5.0
    cellSnapshot.layer.shadowOpacity = 0.4
    return cellSnapshot
  }
  
  func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
    let longPress = gestureRecognizer as! UILongPressGestureRecognizer
    let state = longPress.state
    let locationInView = longPress.locationInView(tableView)
    let indexPath = tableView.indexPathForRowAtPoint(locationInView)
    
    
    struct My {
      static var cellSnapshot : UIView? = nil
    }
    struct Path {
      static var initialIndexPath : NSIndexPath? = nil
    }
    
    switch state {
    case UIGestureRecognizerState.Began:
      if indexPath != nil {
        Path.initialIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath!) as UITableViewCell!
        My.cellSnapshot  = snapshopOfCell(cell)
        var center = cell.center
        My.cellSnapshot!.center = center
        My.cellSnapshot!.alpha = 0.0
        tableView.addSubview(My.cellSnapshot!)
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
          center.y = locationInView.y
          My.cellSnapshot!.center = center
          My.cellSnapshot!.transform = CGAffineTransformMakeScale(1.05, 1.05)
          My.cellSnapshot!.alpha = 0.98
          cell.alpha = 0.0
          
          }, completion: { (finished) -> Void in
            if finished {
              cell.hidden = true
            }
        })
      }
      
    case UIGestureRecognizerState.Changed:
      var center = My.cellSnapshot!.center
      center.y = locationInView.y
      My.cellSnapshot!.center = center
      if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
        swap(&todoList[indexPath!.row], &todoList[Path.initialIndexPath!.row])
        tableView.moveRowAtIndexPath(Path.initialIndexPath!, toIndexPath: indexPath!)
        Path.initialIndexPath = indexPath
      }
      
    default:
      let cell = tableView.cellForRowAtIndexPath(Path.initialIndexPath!) as UITableViewCell!
      cell.hidden = false
      cell.alpha = 0.0
      UIView.animateWithDuration(0.25, animations: { () -> Void in
        My.cellSnapshot!.center = cell.center
        My.cellSnapshot!.transform = CGAffineTransformIdentity
        My.cellSnapshot!.alpha = 0.0
        cell.alpha = 1.0
        }, completion: { (finished) -> Void in
          if finished {
            Path.initialIndexPath = nil
            My.cellSnapshot!.removeFromSuperview()
            My.cellSnapshot = nil
          }
      })
    
    
  }
  }
  
  
  
  func newButtonTapped(item: UIBarButtonItem) {
    
    switch(self.editState) {
    case .Editing(let cell):
      cell.textField.resignFirstResponder()
      cell.textField.userInteractionEnabled = false
    case .NotEditing:
      break
    }
    

    var item = TodoItem()
    item.label = ""//(addTextField?.text)!
      
    self.todoList.insert(item, atIndex: 0)
      
    self.tableView.reloadData()
    
    let indexPath = NSIndexPath(forRow: 0, inSection: 0)

    let cell = tableView.cellForRowAtIndexPath(indexPath) as! TodoTableViewCell
    
    cell.textField?.userInteractionEnabled = true
    cell.textField.becomeFirstResponder()
    
    refreshControl?.endRefreshing()
   
    
  }
}

extension TodoTableViewController {

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch editState {
    case .NotEditing:
      break
    case .Editing(let cell):
      cell.textField.userInteractionEnabled = false
      cell.textField.resignFirstResponder()
    }
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  
  
}

extension TodoTableViewController {
  
  
  
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.todoList.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let tableViewCell = tableView.dequeueReusableCellWithIdentifier("TodoTableViewCell", forIndexPath: indexPath)
    
    if let todoCell = tableViewCell as? TodoTableViewCell {
      todoCell.start()
      todoCell.textField.text = self.todoList[indexPath.row].label
      todoCell.delegate = self
    }
    
    return tableViewCell
  }
  
}


extension TodoTableViewController: TodoCellDelegate {
  func cellDoubleTapped(cell: TodoTableViewCell) {
    editState = .Editing(cell)
  }
  
  func saveUpdatedText(cell: TodoTableViewCell) {
    if let indexPath = self.tableView.indexPathForCell(cell) {
      self.todoList[indexPath.row].label = cell.textField.text!
    }
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 70
  }
  
}
