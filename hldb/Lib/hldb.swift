//
//  DBTable.swift
//  HLModular
//
//  Created by Ben Garrett on 7/10/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation
import BrightFutures
import Result

// Allows two Rows in a HLDB.Table to be compared using ==
public func ==(lhs: TableRow, rhs: TableRow) -> Bool {
  var leftKeys: [String] = lhs.fields.allKeys as! [String]
  var rightKeys: [String] = rhs.fields.allKeys as! [String]
  if leftKeys.count != rightKeys.count { return false }
  leftKeys.sortInPlace { $0 < $1 }
  rightKeys.sortInPlace { $0 < $1 }
  
  for (idx, k) in leftKeys.enumerate() {
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



public enum DBResult {
  case Success
  case Items([NSDictionary])
  case Error(Int, String)
}

public struct DBQueryArgs {
  let query: String
  let args: [AnyObject]
}

public class DB <BackDB: AbstractDB, BackDBQueue: AbstractDBQueue where BackDB.Cursor : LazySequenceType, BackDB.Cursor.Generator.Element == NSDictionary, BackDBQueue.DB == BackDB> {
  
    public lazy var queue: BackDBQueue = BackDBQueue(dbPath: self.dbPath)
    public let fileName: String
    public let dbPath: String
  
    public init(fileName: String) {
      self.fileName = fileName
      self.dbPath = DB.pathForDBFile(fileName)
      print("HLDB: inited at path=\(self.dbPath)")
    }
    
    public class func pathForDBFile(fileName: String) -> String {
      let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
      return (documentsFolder as NSString).stringByAppendingPathComponent(fileName)
    }
    
    class func deleteDB(fileName: String) -> NSError? {
      let dbPath = DB.pathForDBFile(fileName)
      var error: NSError? = nil
      let fm = NSFileManager.defaultManager()
      if fm.fileExistsAtPath(dbPath) {
        do {
          try fm.removeItemAtPath(dbPath)
        } catch let error1 as NSError {
          error = error1
        }
      }
      return error
    }
    
    // do a query that does not return results without using a transaction
    public func updateWithoutTx(query: String, args:[AnyObject] = []) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      queue.execInDatabase { db in
        if !db.executeUpdate(query, withArgumentsInArray:args as [AnyObject]) {
          print("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
          p.success(DBResult.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
          return
        }
        p.success(DBResult.Success)
      }
      
      return p.future
    }
    
    // do a query that does not return result using a transaction and rollback upon failure
    public func update(queries: [DBQueryArgs]) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      queue.execInTransaction() { db in
        for query in queries {
          //          NSLog("Running query=\(query.query) argCount=\(query.args.count) args=\(query.args)")
          if !db.executeUpdate(query.query, withArgumentsInArray:query.args as [AnyObject]) {
            print("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
            p.success(DBResult.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
            return .Rollback
          }
        }
        p.success(DBResult.Success)
        return .Ok
      }
      
      return p.future
    }
    
    // do a select style query that returns result
    public func query(query: String, args:[AnyObject] = []) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      queue.execInDatabase() {
        db in
        
        if let rs = db.executeQuery(query, withArgumentsInArray:args as [AnyObject]) {
          let items = Array(rs)
          p.success(DBResult.Items(items))
        } else {
          print("DB Query \(self.fileName) failed: \(db.lastErrorMessage()) query: \(query)")
          p.success(DBResult.Error(Int(db.lastErrorCode()), db.lastErrorMessage()))
        }
      }
      
      return p.future
    }
    
    // only use within txBlock
    public func txUpdate(db: BackDB, queries: [DBQueryArgs]) -> DBResult {
      for query in queries {
        if !db.executeUpdate(query.query, withArgumentsInArray:query.args as [AnyObject]) {
          print("DB Query \(self.fileName) failed: \(db.lastErrorMessage())")
          return DBResult.Error(Int(db.lastErrorCode()), db.lastErrorMessage())
        }
      }
      return DBResult.Success
    }
    
    // only use within txBlock
    public func txQuery(db: BackDB, query: String, args:[AnyObject] = []) -> DBResult  {
      if let rs = db.executeQuery(query, withArgumentsInArray:args) {
        let items = Array(rs)
        return DBResult.Items(items)
      } else {
        print("DB Query \(self.fileName) failed: \(db.lastErrorMessage()) query: \(query)")
        return DBResult.Error(Int(db.lastErrorCode()), db.lastErrorMessage())
      }
    }
    
    public func txBlock(block: (BackDB) -> (DBResult)) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      queue.execInTransaction() { db in
        let result = block(db)
        switch result {
        case .Error:
          p.success(result)
          return .Rollback
        default: break
        }
        p.success(result)
        return .Ok
      }
      return p.future
    }
    
  }

  public struct TableRow: Equatable {
    let fields: NSMutableDictionary
  
    public init(fields: NSMutableDictionary) {
      self.fields = fields
    }
  }

public enum TableType: String {
  case Integer = "INT"
  case Real = "REAL"
  case Text = "TEXT"
  case Blob = "BLOB"
  case Bool = "BOOL"
}

public enum TableIndex: String {
  case None = "none"
  case PrimaryKey = "primaryKey"
  case Unique = "unique"
  case Index = "index"
  case Packed = "packed"
  case Private = "private"
}

public enum TableDefault {
  case None
  case NonNull
  case Value(AnyObject)
}

public struct TableField {
  let name: String
  let type: TableType
  let index: TableIndex
  let defaultValue: TableDefault
  
  public init(name: String, type: TableType, index: TableIndex, defaultValue: TableDefault) {
    self.name = name
    self.type = type
    self.index = index
    self.defaultValue = defaultValue
  }
  
  public init(fromDict: NSDictionary) {
    defaultValue = .NonNull
    
    self.name = (fromDict["name"] as? String) ?? ""
    
    if let typeValue = fromDict["type"] as? String {
      if let type = TableType(rawValue: typeValue) {
        self.type = type
      } else {
        type = .Text
      }
    } else {
      type = .Text
    }
    
    if let isPrimaryKey = fromDict["pk"] as? Int where isPrimaryKey == 1 {
      self.index = .PrimaryKey
    } else {
      index = .None
    }
  
  }
  
  public func toDictionary() -> NSDictionary {
    let outDict = NSMutableDictionary()
    outDict["name"] = name
    outDict["type"] = type.rawValue
    outDict["index"] = index.rawValue
    return outDict
  }
}


  public class Table <BackDB: AbstractDB, BackDBQueue: AbstractDBQueue where BackDB.Cursor : LazySequenceType, BackDB.Cursor.Generator.Element == NSDictionary, BackDBQueue.DB == BackDB> {
    
    public let name: String
    public let primaryKey: String
    public let definition: [String: TableField]
    public let db: DB<BackDB, BackDBQueue>
    public var debug: Bool = true
    
    public lazy var fieldNames: [String] = Array(self.definition.keys)
    public lazy var fieldNamesPlaceholderStr: String = {
      var holders: [String] = []
      for field in self.fieldNames {
        holders.append("?")
      }
      return holders.joinWithSeparator(",")
    }()
    
    public lazy var fieldNamesStr: String = self.fieldNames.joinWithSeparator(",")
    
    public init(db: DB<BackDB, BackDBQueue>, name: String, fields:[TableField]) {
      self.db = db
      self.name = name
      
      var foundPrimaryKey = false
      var pKey = ""
      var def: [String: TableField] = [:]
      for field in fields {
        def[field.name] = field
        if !foundPrimaryKey && field.index == .PrimaryKey {
          pKey = field.name
          foundPrimaryKey = true
        }
      }
      // TODO: Add packed data later
      // let packedDataFieldName = "packeddata"
      // definition[packedDataFieldName] = Field(name: packedDataFieldName, type: .Blob, index: .Private, defaultValue: .NonNull)
      
      // add a primary key if there wasn't one
      if !foundPrimaryKey {
        pKey = "id"
        def[pKey] = TableField(name: pKey, type: .Text, index: .PrimaryKey, defaultValue: .NonNull)
      }
      self.primaryKey = pKey
      self.definition = def
    }
    
    var createTableQueryString: String {
      var fields: [String] = []
      for (_, field) in definition {
        let fieldType = field.type.rawValue
        var constraintStr = ""
        switch field.index {
        case .Unique:
          constraintStr = " UNIQUE"
        case .PrimaryKey:
          constraintStr = " PRIMARY KEY"
        default:
          break
        }
        var fieldDefault = ""
        switch field.defaultValue {
        case .None:
          break
        case .NonNull:
          fieldDefault = " NOT NULL"
        case .Value(let v):
          fieldDefault = " DEFAULT \(v)"
        }
        fields.append("\(field.name) \(fieldType)\(constraintStr)\(fieldDefault)")
      }
      let fieldsStr = fields.joinWithSeparator(",")
      return "CREATE TABLE IF NOT EXISTS \(name) (\(fieldsStr));"
    }
    
    var indicesToBeCreated: [String] {
      var statements: [String] = []
      for (_, field) in definition {
        switch field.index {
        case .Unique:
          statements.append("CREATE UNIQUE INDEX IF NOT EXISTS \(self.name)_\(field.name) ON \(self.name)(\(field.name));")
        case .Index:
          statements.append("CREATE INDEX IF NOT EXISTS \(self.name)_\(field.name) ON \(self.name)(\(field.name));")
        default:
          break
        }
      }
      return statements
    }
    
    public func schema() -> Future<[TableField], NoError> {
      
      let p = Promise<[TableField], NoError>()
      let query = "pragma table_info(\(name))"
      
      db.txBlock { db in return self.db.txQuery(db, query: query)
        }.onSuccess { result in
          var fields: [TableField] = []
          
          switch result {
          case .Items(let items):
            for item in items {
              let f = TableField(fromDict: item)
              fields.append(f)
            }
            p.success(fields)
          default:
            p.success([])
            break
          }
      }
      return p.future
    }
    
    public func create() -> Future<Void, NoError> {
      //NSLog("Create table query string =\(createTableQueryString)")
      let p = Promise<Void, NoError>()
      db.updateWithoutTx(createTableQueryString).onSuccess { result in
        switch result {
        case .Success:
          for statement in self.indicesToBeCreated {
            self.db.updateWithoutTx(statement)
          }
        default:
          break
        }
        p.success()
      }
      return p.future
    }
    
    public func drop() -> Future<Void, NoError> {
      let p = Promise<Void, NoError>()
      db.updateWithoutTx("DROP TABLE \(name)").onSuccess {_ in
        p.success()
      }
      return p.future
    }
    
    public func dropAndCreate() -> Future<Void, NoError> {
      let p = Promise<Void, NoError>()
      drop().onSuccess {
        self.create().onSuccess {
          p.success()
        }
      }
      return p.future
    }
    
    func rowFields(r: TableRow) -> [String] {
      // TODO: implement packed
      var fieldStrArr = [String]()
      for (fieldName, field) in definition {
        switch field.type {
        case .Integer:
          var value = 0
          if let v = r.fields[fieldName] as? Int {
            value = v
          } else {
            switch field.defaultValue {
            case .Value(let v):
              if let v = v as? Int {
                value = v
              }
            default:
              break
            }
          }
          fieldStrArr.append("\(value)")
        case .Real:
          var value: Double = 0.0
          if let v = r.fields[fieldName] as? Double {
            value = v
          } else {
            switch field.defaultValue {
            case .Value(let v):
              if let v = v as? Double {
                value = v
              }
            default:
              break
            }
          }
          fieldStrArr.append("\(value)")
          break
        case .Text:
          var value = ""
          if let v = r.fields[fieldName] as? String {
            value = v
          } else {
            switch field.defaultValue {
            case .Value(let v):
              if let v = v as? String {
                value = v
              }
            default:
              break
            }
          }
          fieldStrArr.append("\(value)")
          break
        case .Blob:
          // TODO: implement blobs
          fieldStrArr.append("NOBLOBS")
          break
        case .Bool:
          var value = false
          if let v = r.fields[fieldName] as? Bool {
            value = v
          } else {
            switch field.defaultValue {
            case .Value(let v):
              if let v = v as? Bool {
                value = v
              }
            default:
              break
            }
          }
          fieldStrArr.append("\(value)")
          break
        }
      }
      return fieldStrArr
    }
    
    func insertAndUpdate(insertRows: [TableRow], updateRows: [TableRow]) -> Future<DBResult, NoError> {
      var queries: [DBQueryArgs] = []
      if insertRows.count > 0 {
        let query = "INSERT INTO \(name) (\(fieldNamesStr)) values (\(fieldNamesPlaceholderStr))"
        for row in insertRows {
          let args = rowFields(row)
          queries.append(DBQueryArgs(query: query, args: args))
        }
      }
      if updateRows.count > 0 {
        for row in updateRows {
          if let primaryKeyVal = row.fields[primaryKey] as? String {
            var pairs: [String] = []
            var args: [AnyObject] = []
            for (k, v) in row.fields {
              if let k = k as? String {
                if k == primaryKey { continue }
                pairs.append("\(k) = ?")
                args.append(v)
              }
            }
            let pairsStr = pairs.joinWithSeparator(", ")
            let query = "UPDATE \(name) SET \(pairsStr) WHERE \(primaryKey) = ?"
            args.append(primaryKeyVal)
            queries.append(DBQueryArgs(query: query, args: args))
          } else {
            let p = Promise<DBResult, NoError>()
            p.success(.Error(-1, "Cannot update without primary key!"))
            return p.future
          }
        }
      }
      return db.update(queries)
    }
    
    public func insert(rows: [TableRow]) -> Future<DBResult, NoError> {
      return insertAndUpdate(rows, updateRows: [])
    }
    
    public func update(rows: [TableRow]) -> Future<DBResult, NoError> {
      return insertAndUpdate([], updateRows: rows)
    }
    
    public func upsert(rows: [TableRow]) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      
      // bail if you are trying to upsert nothing
      if rows.count == 0 {
        p.trySuccess(.Success)
        return p.future
      }
      
      var idList: [String] = []
      var placeholderList: [String] = []
      for row in rows {
        if let rowId = row.fields[primaryKey] as? String {
          idList.append(rowId)
          placeholderList.append("?")
        }
      }
      let placeholderListStr = placeholderList.joinWithSeparator(",")
      
      let selectQuery = "SELECT \(primaryKey) FROM \(name) WHERE \(primaryKey) in (\(placeholderListStr))"
      if debug { NSLog("HLDB: \(name): Upsert idList=\(idList) selectQuery=\(selectQuery)") }
      
      db.txBlock { db in
        var foundIds: [String: Bool] = [:]
        let selectResult = self.db.txQuery(db, query: selectQuery, args: idList)
        
        switch selectResult {
        case .Success:
          break
        case .Error:
          return selectResult
        case .Items(let items):
          if self.debug { NSLog("HLDB: \(self.name): Found \(items.count) items out of idList of count=\(idList.count)") }
          for item in items {
            if let v = item[self.primaryKey] as? String {
              foundIds[v] = true
            }
          }
        }
        
        if self.debug { NSLog("HLDB: \(self.name): Upsert numRows=\(rows.count) foundRows=\(foundIds)") }
        
        if foundIds.count == 0 {
          // Simple case: everything should be inserted
          return self.insertWithinTx(db, rows: rows)
        } else {
          // Complex case: mixture of insert and update
          var insertRows: [TableRow] = []
          var updateRows: [TableRow] = []
          
          for row in rows {
            if let rowId = row.fields[self.primaryKey] as? String {
              if let _ = foundIds[rowId] {
                updateRows.append(row)
              } else {
                insertRows.append(row)
              }
            }
          }
          if self.debug { NSLog("HLDB: \(self.name): Upsert insertRows=\(insertRows.count) updateRows=\(updateRows.count)") }
          return self.insertAndUpdateWithinTx(db, insertRows: insertRows, updateRows: updateRows)
        }
        }.onSuccess { result in
          p.success(result)
      }
      
      return p.future
    }
    
    public func upsertNoTx(rows: [TableRow]) -> Future<DBResult, NoError> {
      let p = Promise<DBResult, NoError>()
      
      // bail if you are trying to upsert nothing
      if rows.count == 0 {
        p.trySuccess(.Success)
        return p.future
      }
      
      var idList: [String] = []
      var placeholderList: [String] = []
      for row in rows {
        if let rowId = row.fields[primaryKey] as? String {
          idList.append(rowId)
          placeholderList.append("?")
        }
      }
      let placeholderListStr = placeholderList.joinWithSeparator(",")
      var foundIds: [String: Bool] = [:]
      
      let selectQuery = "SELECT \(primaryKey) FROM \(name) WHERE \(primaryKey) in (\(placeholderListStr))"
      if debug { NSLog("HLDB: \(name): Upsert idList=\(idList) selectQuery=\(selectQuery)") }
      db.query(selectQuery, args: idList).onSuccess(Queue.global.context) { result in
        switch result {
        case .Success:
          break
        case .Error:
          return p.success(result)
        case .Items(let items):
          if self.debug { NSLog("HLDB: \(self.name): Found \(items.count) items out of idList of count=\(idList.count)") }
          for item in items {
            if let v = item[self.primaryKey] as? String {
              foundIds[v] = true
            }
          }
        }
        
        if self.debug { NSLog("HLDB: \(self.name): Upsert numRows=\(rows.count) foundRows=\(foundIds)") }
        
        if foundIds.count == 0 {
          // Simple case: everything should be inserted
          self.insert(rows).onSuccess(Queue.global.context) { result in
            p.success(result)
          }
        } else {
          // Complex case: mixture of insert and update
          var insertRows: [TableRow] = []
          var updateRows: [TableRow] = []
          
          for row in rows {
            if let rowId = row.fields[self.primaryKey] as? String {
              if let _ = foundIds[rowId] {
                updateRows.append(row)
              } else {
                insertRows.append(row)
              }
            }
          }
          if self.debug { NSLog("HLDB: \(self.name): Upsert insertRows=\(insertRows.count) updateRows=\(updateRows.count)") }
          
          self.insertAndUpdate(insertRows, updateRows: updateRows).onSuccess(Queue.global.context) { result in
            p.success(result)
          }
        }
      }
      
      return p.future
    }
    
    public func select(whereStr: String = "") -> Future<DBResult, NoError> {
      let finalWhereString = whereStr
      let query = "SELECT * FROM \(name) \(finalWhereString)"
      return db.query(query)
    }
    
    public func deleteAll() -> Future<DBResult, NoError> {
      var queries: [DBQueryArgs] = []
      let query = "DELETE FROM \(name)"
      queries.append(DBQueryArgs(query: query, args: []))
      return db.update(queries)
    }
    
    public func delete(rows: [TableRow]) -> Future<DBResult, NoError> {
      var queries: [DBQueryArgs] = []
      for row in rows {
        if let primaryKeyValue: AnyObject = row.fields[primaryKey] {
          let query = "DELETE FROM \(name) WHERE \(primaryKey) = ?"
          queries.append(DBQueryArgs(query: query, args: [primaryKeyValue]))
        } else {
          let p = Promise<DBResult, NoError>()
          p.success(.Error(-1, "Cannot update without primary key!"))
          return p.future
        }
      }
      return db.update(queries)
    }
    
    private func insertAndUpdateWithinTx(abdb: BackDB, insertRows: [TableRow], updateRows: [TableRow]) -> DBResult {
      var queries: [DBQueryArgs] = []
      if insertRows.count > 0 {
        let query = "INSERT INTO \(name) (\(fieldNamesStr)) values (\(fieldNamesPlaceholderStr))"
        for row in insertRows {
          let args = rowFields(row)
          //          log("Q=\(query) Inserting=\(args)")
          queries.append(DBQueryArgs(query: query, args: args))
        }
      }
      if updateRows.count > 0 {
        for row in updateRows {
          if let primaryKeyVal = row.fields[primaryKey] as? String {
            var pairs: [String] = []
            var args: [AnyObject] = []
            for (k, v) in row.fields {
              if let k = k as? String {
                if k == primaryKey { continue }
                pairs.append("\(k) = ?")
                args.append(v)
              }
            }
            let pairsStr = pairs.joinWithSeparator(", ")
            let query = "UPDATE \(name) SET \(pairsStr) WHERE \(primaryKey) = ?"
            args.append(primaryKeyVal)
            queries.append(DBQueryArgs(query: query, args: args))
          } else {
            return .Error(-1, "Cannot update without primary key!")
          }
        }
      }
      
      return db.txUpdate(abdb, queries: queries)
    }
    
    public func insertWithinTx(abdb: BackDB, rows: [TableRow]) -> DBResult {
      return insertAndUpdateWithinTx(abdb, insertRows: rows, updateRows: [])
    }
    
    public func updateWithinTx(abdb: BackDB, rows: [TableRow]) -> DBResult {
      return insertAndUpdateWithinTx(abdb, insertRows: [], updateRows: rows)
    }
  }
  

