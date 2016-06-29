//
//  DirectConnector.swift
//  hldb
//
//  Created by Ben Garrett on 6/29/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import Foundation
import SQLite

class SQLBlah {
  
  init() {
    
  }
  
  func openDatabase() -> COpaquePointer? {
    var db: COpaquePointer = nil
    let path = "foo"
    if sqlite3_open(path, &db) == SQLITE_OK {
      print("Successfully opened connection to database at \(path)")
      return db
    } else {
      print("Unable to open database. Verify that you created the directory described " +
        "in the Getting Started section.")
//      XCPlaygroundPage.currentPage.finishExecution()
    }
    return nil
  }
  
}