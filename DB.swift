//
//  DB.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

public class DB {
  public var queue: FMDatabaseQueue?
  public let fileName: String
  public let dbPath: String
  
  public enum Result {
    case Success
    case Items([NSDictionary])
    case Error(Int, String)
  }
  
  public struct QueryArgs {
    let query: String
    let args: [AnyObject]
  }
  
  public init(fileName: String) {
    self.fileName = fileName
    self.dbPath = DB.pathForDBFile(fileName)
  }
  
  public class func pathForDBFile(fileName: String) -> String {
    let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    return documentsFolder.stringByAppendingPathComponent(fileName)
  }
  
  class func deleteDB(fileName: String) -> NSError? {
    let dbPath = DB.pathForDBFile(fileName)
    var error: NSError? = nil
    let fm = NSFileManager.defaultManager()
    if fm.fileExistsAtPath(dbPath) {
      fm.removeItemAtPath(dbPath, error: &error)
    }
    return error
  }
  
  public func getQueue() -> FMDatabaseQueue? {
    if queue == nil {
      queue = FMDatabaseQueue(path: self.dbPath)
    }
    return queue
  }
  
  // do a query that does not return results without using a transaction
  public func updateWithoutTx(query: String, args:[AnyObject] = []) -> Future<Result> {
    let p = Promise<Result>()
    getQueue()?.inDatabase() {
      db in
      
      // TODO: SWIFTUP: typecast to [AnyObject] may be slow, look at
      if !db.executeUpdate(query, withArgumentsInArray:args as [AnyObject]) {
        println("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
        p.success(Result.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
        return
      }
      p.success(Result.Success)
    }
    
    return p.future
  }
  
  // do a query that does not return result using a transaction and rollback upon failure
  public func update(queries: [QueryArgs]) -> Future<Result> {
    let p = Promise<Result>()
    getQueue()?.inTransaction() {
      db, rollback in
      
      for query in queries {
        //NSLog("Running query=\(query.query) argCount=\(query.args.count) args=\(query.args)")
        // TODO: SWIFTUP: typecast to [AnyObject] may be slow, look at
        if !db.executeUpdate(query.query, withArgumentsInArray:query.args as [AnyObject]) {
          rollback.initialize(true)
          println("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
          p.success(Result.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
          return
        }
      }
      p.success(Result.Success)
    }
    
    return p.future
  }
  
  // do a select style query that returns result
  public func query(query: String, args:[AnyObject] = []) -> Future<Result> {
    let p = Promise<Result>()
    getQueue()?.inDatabase() {
      db in
      
      if let rs = db.executeQuery(query, withArgumentsInArray:args as [AnyObject]) {
        var items = [NSDictionary]()
        while rs.next() {
          items.append(rs.resultDictionary())
        }
        p.success(Result.Items(items))
      } else {
        println("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
        p.success(Result.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
      }
    }
    
    return p.future
  }
}
