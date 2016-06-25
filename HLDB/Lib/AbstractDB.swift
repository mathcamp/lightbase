//
//  AbstractDB.swift
//  HLDB
//
//  Created by Ben Garrett on 6/24/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import Foundation

public protocol AbstractDBQueue {
  init(dbPath: String)
  
  func execInDatabase(block: (FMAbstractDB) -> ())
//  public func exec
  func execInTransaction(block: (FMAbstractDB, inout Bool) -> ())
  //  public func exec
}

public protocol AbstractDB {
  func executeUpdate(query: NSString, withArgumentsInArray args:[AnyObject]) -> Bool
  func executeUpdate(query: NSString, withArgumentsInArray args:[AnyObject]) -> AbstractDBResultSet
  func lastErrorMessage() -> String
  func lastErrorCode() -> Int
}

public protocol AbstractDBResultSet {
  
  //TODO implement this as generatorType, then Sequence Type (returning itself)
  // then you can do: for element in sequence {
  func next()
  func resultDictionary()
}



public class FMAbstractDB: AbstractDB {
  
  public func executeUpdate(query: NSString, withArgumentsInArray args:[AnyObject]) -> Bool {
    return false
  }
  public func executeUpdate(query: NSString, withArgumentsInArray args:[AnyObject]) -> AbstractDBResultSet {
    return FMAbstractDBResultSet()
  }
  
  public func lastErrorMessage() -> String {
    return ""
  }
  
  public func lastErrorCode() -> Int {
    return 0
  }
  
}


public class FMAbstractDBQueue: AbstractDBQueue {
  let dbPath: String
  
  public required init(dbPath: String) {
    self.dbPath = dbPath
  }
  
  public func execInDatabase(block: (FMAbstractDB) -> ()) {
    // TODO!
  }
  
  public func execInTransaction(block: (FMAbstractDB, inout Bool) -> ()) {
    // TODO!
  }
}

public class FMAbstractDBResultSet: AbstractDBResultSet {


}

