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
  
  let todoModel = TodoModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let longpress = UILongPressGestureRecognizer(target: self, action: #selector(TodoTableViewController.longPressGestureRecognized(_:)))
    tableView.addGestureRecognizer(longpress)
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(newButtonTapped), forControlEvents: UIControlEvents.ValueChanged)
    refreshControl.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    self.refreshControl = refreshControl
    
    let view = UIView()
    view.backgroundColor = UIColor.redColor()
    
    view.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 70)
    
    /*let plusImage = UIImage(named: "plus.png")
    let plusView = UIImageView(image: plusImage)
    view.addSubview(plusView)*/
    
    
    let gestureRec = UITapGestureRecognizer(target: self, action: #selector(self.newButtonTapped(_:)))
    
    view.addGestureRecognizer(gestureRec)
    
    self.tableView.tableFooterView = view
    
    self.todoModel.loadItems().onSuccess{result in self.tableView.reloadData()}
    
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
        self.todoModel.swapTodoItems(indexPath!.row, index2: Path.initialIndexPath!.row)
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
    stopIfEditingCell()
    let item = TodoItem(label: "")
    self.todoModel.addTodoItem(item)
    
    
    
    self.tableView.reloadData()
    
    /*let rowsHeight: CGFloat = CGFloat(self.todoModel.count())*70.0
    
    self.tableView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height-rowsHeight)
    print(UIScreen.mainScreen().bounds.height)*/
   
    
    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! TodoTableViewCell
    startEditingCell(cell)
    
    refreshControl?.endRefreshing()
  }
  
  override func tableView(tableView: UITableView,
                          editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    
    let more = UITableViewRowAction(style: .Normal, title: "Check") { action, index in
      self.todoModel.switchCheckedAtIndex(indexPath.row)
      self.tableView.reloadData()
    }
    more.backgroundColor = UIColor(red:0.75, green: 0, blue:0.5, alpha:1.0)
    
    let deleteButton = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
      self.todoModel.removeTodoItemAtIndex(indexPath.row);
      self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic);
    }
    deleteButton.backgroundColor = UIColor.blueColor()
    
    return [deleteButton, more]
  }
  

  
  
}

extension TodoTableViewController {
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.todoModel.count()
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let tableViewCell = tableView.dequeueReusableCellWithIdentifier("TodoTableViewCell", forIndexPath: indexPath)
    
    if let todoCell = tableViewCell as? TodoTableViewCell {
      let cellModel = self.todoModel.atIndex(indexPath.row)
      todoCell.start()
      todoCell.textField.text = self.todoModel.atIndex(indexPath.row).label
      todoCell.delegate = self
      if cellModel.checked {
        tableViewCell.backgroundColor = UIColor(red: 0.75, green: 0, blue: 0.5, alpha: 1)
      } else {
        tableViewCell.backgroundColor = UIColor(red: 0.349, green: 0.255, blue: 0.639, alpha: 1)
      }
    }
    
    
    
    return tableViewCell
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 70
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    stopIfEditingCell()
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
}


extension TodoTableViewController: TodoCellDelegate {
  
  func stopEditingCell(cell: TodoTableViewCell) {
    cell.textField.resignFirstResponder()
    cell.textField.userInteractionEnabled = false
    self.todoModel.editState = .NotEditing
  }
  
  func stopIfEditingCell() -> Bool {
    switch(self.todoModel.editState) {
    case .Editing(let cell):
      stopEditingCell(cell)
      return true
    case .NotEditing:
      return false
    }
  }
  
  func startEditingCell(cell: TodoTableViewCell) {
    stopIfEditingCell()
    cell.textField?.userInteractionEnabled = true
    cell.textField.becomeFirstResponder()
    self.todoModel.editState = .Editing(cell)
  }
  
  func saveUpdatedText(cell: TodoTableViewCell) {
    if let indexPath = self.tableView.indexPathForCell(cell) {
      self.todoModel.setLabelAtIndex(indexPath.row, label: cell.textField.text!)
    }
  }
  
}
