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
  var done: Bool = false
}

class TodoTableViewController: UITableViewController {
  
  var editState: EditState = .NotEditing
  var todoList: [TodoItem] = [TodoItem(label: "Meet w/ Jennifer for breakfast", done: false),TodoItem(label: "Present at beach", done: false),TodoItem(label: "Build something beautiful", done: false)]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(newButtonTapped))
    
    let longpress = UILongPressGestureRecognizer(target: self, action: #selector(TodoTableViewController.longPressGestureRecognized(_:)))
    tableView.addGestureRecognizer(longpress)
    
    var refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(newButtonTapped), forControlEvents: UIControlEvents.ValueChanged)
    refreshControl.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    self.refreshControl = refreshControl
    
    
    
    
  }
  
  
  override func tableView(_ tableView: UITableView,
                            editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    
    let more = UITableViewRowAction(style: .Normal, title: "More") { action, index in
      print("more button tapped")
    }
    more.backgroundColor = UIColor.lightGrayColor()
    
    let favorite = UITableViewRowAction(style: .Normal, title: "Favorite") { action, index in
      print("favorite button tapped")
    }
    favorite.backgroundColor = UIColor.orangeColor()
    
    let share = UITableViewRowAction(style: .Normal, title: "Share") { action, index in
      print("share button tapped")
    }
    share.backgroundColor = UIColor.blueColor()
    
    return [share, favorite, more]
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
    print("NEW!")
    
    var addTextField: UITextField?
    let alertController = UIAlertController(title: "Ttle", message: "A standard alert", preferredStyle: .Alert)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action:UIAlertAction!) in
      print("you have pressed the Cancel button");
    }
    let addAction = UIAlertAction(title: "Add New", style: .Default) { (action:UIAlertAction!) in
      print("you have pressed OK button");
      var item = TodoItem()
      item.label = (addTextField?.text)!
      
      self.todoList.append(item)
      
      self.tableView.reloadData()
    }
    
    alertController.addTextFieldWithConfigurationHandler { (textField) in
      addTextField = textField
      addTextField?.placeholder = "Add a Task Label"
    }
    
    alertController.addAction(cancelAction)
    alertController.addAction(addAction)
    
    refreshControl?.endRefreshing()
    self.presentViewController(alertController, animated: true, completion:nil)
    
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
  
  
  
  /*override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
    // 1
    var shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Share" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
      // 2
      let shareMenu = UIAlertController(title: nil, message: "Share using", preferredStyle: .ActionSheet)
      
      let twitterAction = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.Default, handler: nil)
      let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
      
      shareMenu.addAction(twitterAction)
      shareMenu.addAction(cancelAction)
      
      
      self.presentViewController(shareMenu, animated: true, completion: nil)
    })
    // 3
    var rateAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Rate" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
      // 4
      let rateMenu = UIAlertController(title: nil, message: "Rate this App", preferredStyle: .ActionSheet)
      
      let appRateAction = UIAlertAction(title: "Rate", style: UIAlertActionStyle.Default, handler: nil)
      let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
      
      rateMenu.addAction(appRateAction)
      rateMenu.addAction(cancelAction)
      
      
      self.presentViewController(rateMenu, animated: true, completion: nil)
    })
    // 5
    return [shareAction,rateAction]
  }*/
  
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
