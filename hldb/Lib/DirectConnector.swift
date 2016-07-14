//
//  DirectConnector.swift
//  hldb
//
//  Created by Ben Garrett on 6/29/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import Foundation
import SQLite

public struct DirectCursor: LazySequenceType, GeneratorType {
  public typealias Element = NSDictionary // or whatever
  
  private let statement: COpaquePointer
  
  init(statement: COpaquePointer) {
    self.statement = statement
  }
  
  public mutating func next() -> NSDictionary? {
    let rc: Int32 = sqlite3_step(statement)
    if (SQLITE_DONE == rc || SQLITE_ROW == rc) {
      let num_cols: Int32 = sqlite3_data_count(statement)
      
      if (num_cols > 0) {
        let dict = NSMutableDictionary()
        
        let columnCount = sqlite3_column_count(statement);
        
        for colIdx in 0..<columnCount {
          let columnName: String = String.fromCString(sqlite3_column_name(statement, colIdx))!
          print(columnName)
          let objectValue = self.objectForColumnIndex(Int(colIdx));
          dict.setValue(objectValue, forKeyPath: columnName)
        }
        
        return dict;
      } else {
        NSLog("Warning: There seem to be no columns in this set.");
        return nil;
      }
      
    } else {
      return nil
    }
  }
  
  func objectForColumnIndex(colIndex: Int) -> AnyObject? {
    let colIdx = Int32(colIndex)
    let columnType = Int32(sqlite3_column_type(statement, colIdx));
    
    let returnValue: AnyObject?;
    
    if (columnType == SQLITE_INTEGER) {
      returnValue = NSNumber(longLong: sqlite3_column_int64(statement, colIdx))
    } else if (columnType == SQLITE_FLOAT) {
      returnValue = NSNumber(double: sqlite3_column_double(statement, colIdx))
    } else if (columnType == SQLITE_BLOB) {
      
      let bytes = sqlite3_column_blob(statement, colIdx)
      let length = Int(sqlite3_column_bytes(statement, colIdx))
      returnValue = Blob(bytes: bytes, length: length)
    } else {
      //default to a string for everything else
      returnValue = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, colIdx)))
    }
    
    return returnValue;
  }
  
}



public class DirectDB: AbstractDB {
  
  public typealias Cursor = DirectCursor
  
  //private let dbPath = "DirectDB"
  
  internal let dbPointer: COpaquePointer?
  private private(set) var inTransaction: Bool {
    get {
      return self.inTransaction
    }
    set {}
  }
  private let loggingErrors = true
  private var errorMessage: String = ""
  
  static let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
  
  public init(dbPath: String) {
    var db: COpaquePointer = nil
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
      self.dbPointer = db
      print("Database opened!!")
    } else {
      print("Unable to open database. Verify that you created the directory described " +
        "in the Getting Started section.")
      self.dbPointer = nil
    }
  }
  
  public func executeUpdate(sql:String) -> Bool {
    return self.executeUpdate(sql, withArgumentsInArray: [])
  }
  
  public func executeUpdate(sql:String, withArgumentsInArray arrayArgs:[AnyObject]) -> Bool {
    
    guard let dbPtr = self.dbPointer else { return false }
    
    
    var rcs: Int32?
    var statement: COpaquePointer = nil
    
    /*defer {
      let closeErrorCode: Int32;
      closeErrorCode = sqlite3_finalize(statement);
      
      if (closeErrorCode != SQLITE_OK) {
        if (self.loggingErrors) {
          NSLog("Unknown error finalizing or resetting statement (%d: %s)", closeErrorCode, sqlite3_errmsg(dbPtr));
          NSLog("DB Query: %@", sql);
        }
      }
    }*/
    

    if (statement == nil) {
      
      rcs = sqlite3_prepare_v2(dbPtr, sql, -1, &statement, nil);
      
      if (SQLITE_OK != rcs) {
        if (self.loggingErrors) {
          NSLog("Error calling sqlite3_prepare SQLITE_ERROR \(rcs): \(sqlite3_errmsg(dbPtr))");
          NSLog("DB Query: %@", sql);
        }
        let errorMessage = String.fromCString(sqlite3_errmsg(dbPtr))!
        print("Query could not be prepared! \(errorMessage)")
        return false;
      }
    }
    
    
    let queryCount = Int(sqlite3_bind_parameter_count(statement))
    if (arrayArgs.count != queryCount) {
      NSLog("Error: the bind count (\(queryCount)) is not correct for the # of variables (\(arrayArgs.count)) (executeQuery)")
      sqlite3_finalize(statement)
      return false
    }
    
    for (idx, obj) in arrayArgs.enumerate() {
      let res = self.bind(obj, atIndex:idx+1, inStatement:statement)
      if (res == SQLITE_OK) {
        print("bind was successful")
      } else {
        print("failed to bind: \(res)")
      }
    }
    
    /* Call sqlite3_step() to run the virtual machine. Since the SQL being
     ** executed is not a SELECT statement, we assume no data will be returned.
     */
    
    let rc = sqlite3_step(statement);
    
    if (SQLITE_DONE == rc) {
      // all is well, let's return.
    }
    else if (SQLITE_ERROR == rc) {
      if (self.loggingErrors) {
        NSLog("Error calling sqlite3_step SQLITE_ERROR \(rc): \(sqlite3_errmsg(dbPtr))");
        NSLog("DB Query: %@", sql);
      }
    }
    else if (SQLITE_MISUSE == rc) {
      // misused sqlite!
      if (self.loggingErrors) {
        NSLog("Error calling sqlite3_step SQLITE_MISUSE \(rc): \(sqlite3_errmsg(dbPtr))");
        NSLog("DB Query: %@", sql);
      }
    }
    else {
      // unknown issue?
      if (self.loggingErrors) {
        NSLog("Error calling sqlite3_step UNKNOWN \(rc): \(sqlite3_errmsg(dbPtr))");
        NSLog("DB Query: %@", sql);
      }
    }
    
    if (rc == SQLITE_ROW) {
      sqlite3_finalize(statement);
      return false
    }
    sqlite3_finalize(statement)
    
    return (rc == SQLITE_DONE || rc == SQLITE_OK);
  }
  
  public func executeQuery(query: String, withArgumentsInArray arrayArgs:[AnyObject]) -> DirectCursor? {
    
    guard let dbPtr = self.dbPointer else { return nil }
    
    var rc: Int32?
    var statement: COpaquePointer = nil
    let rs: DirectCursor
    
    /*defer {
      let closeErrorCode: Int32;
      closeErrorCode = sqlite3_finalize(statement);
      
      if (closeErrorCode != SQLITE_OK) {
        if (self.loggingErrors) {
          NSLog("Unknown error finalizing or resetting statement (%d: %s)", closeErrorCode, sqlite3_errmsg(dbPtr));
          NSLog("DB Query: %@", query);
        }
      }
    }*/
    
    if (statement == nil) {
      
      rc = sqlite3_prepare_v2(self.dbPointer!, query, -1, &statement, nil);
      
      if (SQLITE_OK != rc) {
        if (self.loggingErrors) {
          NSLog("Error calling sqlite3_prepare SQLITE_ERROR \(rc): \(sqlite3_errmsg(dbPtr))");
          NSLog("DB Query: %@", query);
        }
        let errorMessage = String.fromCString(sqlite3_errmsg(dbPtr))!
        print("Query could not be prepared! \(errorMessage)")
        sqlite3_finalize(statement);
        return nil;
      }
    }
    
    let queryCount = Int(sqlite3_bind_parameter_count(statement))
    if (arrayArgs.count != queryCount) {
      NSLog("Error: the bind count (\(queryCount)) is not correct for the # of variables (\(arrayArgs.count)) (executeQuery)")
      sqlite3_finalize(statement);
      return nil
    }
    
    for (idx, obj) in arrayArgs.enumerate() {
      self.bind(obj, atIndex:idx, inStatement:statement)
    }
    
    
    // the statement gets closed in rs's dealloc or [rs close];
    rs = DirectCursor(statement: statement)
    
    return rs
    
    
  }
  
  func bind(obj: AnyObject?, atIndex index:Int, inStatement pStmt:COpaquePointer) -> Int32 {
    let idx = Int32(index)
    
    if obj == nil {
      return sqlite3_bind_null(pStmt, Int32(idx))
    } else if let blobObj = obj as? NSData {
      return sqlite3_bind_blob(pStmt, idx, blobObj.bytes, Int32(blobObj.length), DirectDB.SQLITE_TRANSIENT)
    } else if let stringObj = obj as? String {
      return sqlite3_bind_text(pStmt, idx, stringObj, Int32(stringObj.characters.count), DirectDB.SQLITE_TRANSIENT)
    } else if let int8Obj = obj as? Int8 {
      return sqlite3_bind_int(pStmt, idx, Int32(int8Obj))
    } else if let uint8Obj = obj as? UInt8 {
      return sqlite3_bind_int(pStmt, idx, Int32(uint8Obj))
    } else if let int16Obj = obj as? Int16 {
      return sqlite3_bind_int(pStmt, idx, Int32(int16Obj))
    } else if let uint16Obj = obj as? UInt16 {
      return sqlite3_bind_int(pStmt, idx, Int32(uint16Obj))
    } else if let int32Obj = obj as? Int32 {
      return sqlite3_bind_int(pStmt, idx, Int32(int32Obj))
    } else if let uint32Obj = obj as? UInt32 {
      return sqlite3_bind_int(pStmt, idx, Int32(uint32Obj))
    } else if let intObj = obj as? Int {
      return sqlite3_bind_int(pStmt, idx, Int32(intObj))
    } else if let uintObj = obj as? UInt {
      return sqlite3_bind_int64(pStmt, idx, Int64(uintObj))
    } else if let int64Obj = obj as? Int64 {
      return sqlite3_bind_int64(pStmt, idx, int64Obj)
    } else if let uint64Obj = obj as? UInt64 {
      return sqlite3_bind_int64(pStmt, idx, Int64(uint64Obj))
    } else if let floatObj = obj as? Float {
      return sqlite3_bind_double(pStmt, idx, Double(floatObj))
    } else if let float80Obj = obj as? Float80 {
      return sqlite3_bind_double(pStmt, idx, Double(float80Obj))
    } else if let doubleObj = obj as? Double {
      return sqlite3_bind_double(pStmt, idx, doubleObj)
    } else if let obj = obj {
      fatalError("tried to bind unexpected value \(obj)")
    }
    return 0
  }
  
  public func lastErrorMessage() -> String {
    return self.errorMessage
  }
  
  public func lastErrorCode() -> Int {
    return 0
  }
  
  
  func rollback() -> Bool {
    let b = self.executeUpdate("rollback transaction")
    
    if (b) {
      self.inTransaction = false
    }
    
    return b
  }
  
  func commit() -> Bool {
    let b =  self.executeUpdate("commit transaction")
    
    if (b) {
      self.inTransaction = false
    }
    
    return b
  }
  
  func beginDeferredTransaction() -> Bool {
    
    let b = self.executeUpdate("begin deferred transaction")
    if (b) {
      self.inTransaction = true
    }
    
    return b
  }
  
  func beginTransaction() -> Bool {
    
    let b = self.executeUpdate("begin exclusive transaction")
    if (b) {
      self.inTransaction = true
    }
    
    return b;
  }
  
}


public class DirectDBQueue: AbstractDBQueue {
  
  public typealias DB = DirectDB
  
  let dbPath: String
  
  var queue: dispatch_queue_t
  var db: DB
  
  public required init(dbPath: String) {
    self.dbPath = dbPath
    
    self.db = DB(dbPath: dbPath)
    
    queue = dispatch_queue_create("lightbase.directDBQueue", nil)
    //dispatch_queue_set_specific(self.queue, kDispatchQueueSpecificKey, (__bridge void *)self, nil);
  }
  
  public func execInDatabase(block: DB -> ()) {
  
    dispatch_sync(queue, {
      
      let db = self.db;
      block(db)
      
      });

  }
  
  public func execInTransaction(block: DB -> RollbackChoice) {

    dispatch_sync(queue, {
      
      self.db.beginTransaction()
      
      switch block(self.db) {
      case .Rollback:
        self.db.rollback()
      case .Ok:
        self.db.commit()
      }
      
      });
    
  }
}