//
//  AbstractDB.swift
//  HLDB
//
//  Created by Ben Garrett on 6/24/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import Foundation

public enum RollbackChoice {
  case Rollback
  case Ok
}

public protocol AbstractDBQueue {
  typealias DB
  init(dbPath: String)
  func execInDatabase(block: DB -> ())
  func execInTransaction(block: DB -> RollbackChoice)

}

public protocol AbstractDB {
  typealias Cursor
  func executeUpdate(sql: String, withArgumentsInArray args:[AnyObject]) -> Bool
  func executeQuery(query: String, withArgumentsInArray args:[AnyObject]) -> Cursor?
  func lastErrorMessage() -> String
  func lastErrorCode() -> Int
}





