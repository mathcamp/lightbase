//
//  Operators.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

public func ==(lhs: HLDB.Table.Row, rhs: HLDB.Table.Row) -> Bool {
  var leftKeys: [String] = lhs.fields.allKeys as! [String]
  var rightKeys: [String] = rhs.fields.allKeys as! [String]
  if leftKeys.count != rightKeys.count { return false }
  leftKeys.sort { $0 < $1 }
  rightKeys.sort { $0 < $1 }
  
  for (idx, k) in enumerate(leftKeys) {
    if rightKeys[idx] != k { return false }
    
    var valuesMatch = false
    if let leftVal = lhs.fields[k] as? String {
      if let rightVal = rhs.fields[k] as? String {
        if leftVal == rightVal {
          valuesMatch = true
        }
      }
    }
    if let leftVal = lhs.fields[k] as? Int {
      if let rightVal = rhs.fields[k] as? Int {
        if leftVal == rightVal {
          valuesMatch = true
        }
      }
    }
    if let leftVal = lhs.fields[k] as? Double {
      if let rightVal = rhs.fields[k] as? Double {
        if leftVal == rightVal {
          valuesMatch = true
        }
      }
    }
    if let leftVal = lhs.fields[k] as? Bool {
      if let rightVal = rhs.fields[k] as? Bool {
        if leftVal == rightVal {
          valuesMatch = true
        }
      }
    }
    
    if !valuesMatch { return false }
  }
  
  return true
}