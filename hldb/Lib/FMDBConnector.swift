//
//  FMDBConnector.swift
//  hldb
//
//  Created by Noah Picard on 6/27/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import Foundation


public struct FMCursor: LazySequenceType, GeneratorType {
  public typealias Element = NSDictionary
  
  let fmResult: FMResultSet
  
  public mutating func next() -> NSDictionary? {
    if fmResult.next() {
      return fmResult.resultDictionary()
    } else {
      return nil
    }
  }
}



public class FMAbstractDB: AbstractDB {
  
  public typealias Cursor = FMCursor
  
  internal let fmdb: FMDatabase
  
  public init(fmdb: FMDatabase) {
    self.fmdb = fmdb
  }
  
  public func executeUpdate(sql: String, withArgumentsInArray args:[AnyObject]) -> Bool {
    return fmdb.executeUpdate(sql, withArgumentsInArray: args)
  }
  public func executeQuery(query: String, withArgumentsInArray args:[AnyObject]) -> FMCursor? {
    return (fmdb.executeQuery(query, withArgumentsInArray: args) as FMResultSet?).map(FMCursor.init)
  }
  
  public func lastErrorMessage() -> String {
    return fmdb.lastErrorMessage()
  }
  
  public func lastErrorCode() -> Int {
    return Int(fmdb.lastErrorCode())
  }
  
}


public class FMAbstractDBQueue: AbstractDBQueue {
  
  public typealias DB = FMAbstractDB
  
  let dbPath: String
  
  let fmdbQueue: FMDatabaseQueue
  
  public required init(dbPath: String) {
    self.dbPath = dbPath
    fmdbQueue = FMDatabaseQueue.init(path: dbPath)
  }
  
  public func execInDatabase(block: DB -> ()) {
    fmdbQueue.inDatabase{ db in block(FMAbstractDB(fmdb: db)) }
  }
  
  public func execInTransaction(block: DB -> RollbackChoice) {
    let fullBlock: (FMDatabase!, UnsafeMutablePointer<ObjCBool>) -> () = {db, success in
      success.initialize(ObjCBool(
        {
          switch block(FMAbstractDB(fmdb: db)) {
          case .Rollback:
            return true
          case .Ok:
            return false
          }}()
        ))
    }
    fmdbQueue.inTransaction(fullBlock)
  }
}
