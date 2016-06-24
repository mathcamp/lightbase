//
//  TodoTableViewCell.swift
//  Todotastic
//
//  Created by Noah Picard on 6/17/16.
//  Copyright © 2016 Highlight. All rights reserved.
//

import Foundation
import UIKit

protocol TodoCellDelegate {
  func saveUpdatedText(cell: TodoTableViewCell)
  func stopEditingCell(cell: TodoTableViewCell)
  func stopIfEditingCell() -> Bool
  func startEditingCell(cell: TodoTableViewCell)
}

class TodoTableViewCell: UITableViewCell {
  @IBOutlet weak var textField: UITextField!
  var delegate: TodoCellDelegate?
  var shouldEdit: Bool = false
  
  func start() {

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped))
    doubleTap.numberOfTapsRequired = 2
    self.addGestureRecognizer(doubleTap)
    
    let bgColorView = UIView()
    bgColorView.backgroundColor = UIColor(red:0.5,green:0,blue:0.5,alpha:1)
    self.selectedBackgroundView = bgColorView

    
    self.textField.userInteractionEnabled = false
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func doubleTapped() {
    delegate?.startEditingCell(self)
  }
  
}

extension TodoTableViewCell: UITextFieldDelegate {
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    delegate?.stopEditingCell(self)
    return false
  }
  
  func textFieldDidEndEditing(textField: UITextField) {
    delegate?.saveUpdatedText(self)
  }
  
}
