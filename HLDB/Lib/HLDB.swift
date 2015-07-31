//
//  DBTable.swift
//  HLModular
//
//  Created by Ben Garrett on 7/10/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation
import BrightFutures

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

public class HLDB {
  
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
        if !db.executeUpdate(query, withArgumentsInArray:args as! [AnyObject]) {
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
          if !db.executeUpdate(query.query, withArgumentsInArray:query.args as! [AnyObject]) {
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
  
  public class Entity {
    let fields: NSMutableDictionary
    
    public init(obj: AnyObject?) {
      var f = NSMutableDictionary()
      if let obj: AnyObject = obj {
        if let fields = obj as? NSMutableDictionary {
          f = fields
        } else if let json = obj as? String {
          var error: NSError? = nil
          if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            if let jsonObject: NSMutableDictionary = NSJSONSerialization.JSONObjectWithData(detailsData, options: nil, error:&error) as? NSMutableDictionary {
              f = jsonObject
            }
          }
        }
      }
      self.fields = f
    }
    
    public init(fields: NSMutableDictionary = [:]) {
      self.fields = fields
    }
    
    public func toFields() -> NSMutableDictionary {
      // override this in subclass
      return [:]
    }
    
    public func toJSON() -> String {
      return serializeToJSON(toFields())
    }
    
    func serializeToJSON(obj: AnyObject) -> String {
      var error: NSError? = nil
      if let data = NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(0), error: &error) {
        if let s = NSString(data: data, encoding: NSUTF8StringEncoding) {
          return s as String
        }
      }
      return ""
    }
    
    func deserializeFromJSON(json: String) -> AnyObject? {
      var error: NSError? = nil
      if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
        if let jsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(detailsData, options: nil, error:&error) {
          return jsonObject
        }
      }
      return nil
    }
    
    func deserializeJSONFieldAsArray(fieldName: String) -> [AnyObject]? {
      if let dict = deserializeJSONField(fieldName) as? [AnyObject] {
        return dict
      }
      return nil
    }
    
    func deserializeJSONFieldAsDictionary(fieldName: String) -> NSMutableDictionary? {
      if let dict = deserializeJSONField(fieldName) as? NSMutableDictionary {
        return dict
      }
      return nil
    }
    
    func deserializeJSONField(fieldName: String) -> AnyObject? {
      if let json = fields[fieldName] as? String {
        return deserializeFromJSON(json)
      }
      return nil
    }
    
    func value(fieldName: String) -> AnyObject? {
      return fields[fieldName]
    }
    
    func boolValue(fieldName: String, defaultValue: Bool = false) -> Bool {
      var outValue = defaultValue
      if let v = fields[fieldName] as? Bool {
        outValue = v
      }
      return outValue
    }
    
    func intValue(fieldName: String, defaultValue: Int = 0) -> Int {
      var outValue = defaultValue
      if let v = fields[fieldName] as? Int {
        outValue = v
      }
      return outValue
    }
    
    func floatValue(fieldName: String, defaultValue: Float = 0) -> Float {
      var outValue = defaultValue
      if let v = fields[fieldName] as? Float {
        outValue = v
      }
      return outValue
    }
    
    func doubleValue(fieldName: String, defaultValue: Double = 0) -> Double {
      var outValue = defaultValue
      if let v = fields[fieldName] as? Double {
        outValue = v
      }
      return outValue
    }
    
    func stringValue(fieldName: String, defaultValue: String = "") -> String {
      var outValue = defaultValue
      if let v = fields[fieldName] as? String {
        outValue = v
      }
      return outValue
    }
    
    func arrayValue(fieldName: String, defaultValue: [AnyObject] = []) -> [AnyObject] {
      var outValue = defaultValue
      // if this is a string then decode json
      if let v = fields[fieldName] as? String {
        if let array = deserializeJSONFieldAsArray(fieldName) {
          return array
        }
      }
      // if it's a dictionary, then just return the dict
      if let v = fields[fieldName] as? [AnyObject] {
        outValue = v
      }
      return outValue
    }
    
    func dictValue(fieldName: String, defaultValue: NSMutableDictionary = [:]) -> NSMutableDictionary {
      var outValue = defaultValue
      // if this is a string then decode json
      if let v = fields[fieldName] as? String {
        if let dict = deserializeJSONFieldAsDictionary(fieldName) {
          return dict
        }
      }
      // if it's a dictionary, then just return the dict
      if let v = fields[fieldName] as? NSMutableDictionary {
        outValue = v
      }
      return outValue
    }
  }
  
  public class Table {
    public enum Type: String {
      case Integer = "INT"
      case Real = "REAL"
      case Text = "TEXT"
      case Blob = "BLOB"
    }
    
    public enum Index {
      case None
      case PrimaryKey
      case Unique
      case Index
      case Packed
      case Private
    }
    
    public enum Default {
      case None
      case NonNull
      case Value(AnyObject)
    }
    
    public struct Field {
      let name: String
      let type: Type
      let index: Index
      let defaultValue: Default
    }
    
    public struct Row: Equatable {
      let fields: NSMutableDictionary
      
      init(fields: NSMutableDictionary) {
        self.fields = fields
      }
    }
    
    public let name: String
    public let primaryKey: String
    public let definition: [String: Field]
    public let db: DB
    
    lazy var fieldNames: [String] = self.definition.keys.array
    lazy var fieldNamesPlaceholderStr: String = {
      var holders: [String] = []
      for field in self.fieldNames {
        holders.append("?")
      }
      return ",".join(holders)
      }()
    
    lazy var fieldNamesStr: String = ",".join(self.fieldNames)
    
    public init(db: DB, name: String, fields:[Field]) {
      self.db = db
      self.name = name
      
      var foundPrimaryKey = false
      var pKey = ""
      var def: [String: Field] = [:]
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
        def[pKey] = Field(name: pKey, type: .Text, index: .PrimaryKey, defaultValue: .NonNull)
      }
      self.primaryKey = pKey
      self.definition = def
    }
    
    var createTableQueryString: String {
      var fields: [String] = []
      for (name, field) in definition {
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
      let fieldsStr = ",".join(fields)
      return "CREATE TABLE IF NOT EXISTS \(name) (\(fieldsStr));"
    }
    
    public func create() {
      //NSLog("Create table query string =\(createTableQueryString)")
      db.updateWithoutTx(createTableQueryString)
    }
    
    public func drop() {
      db.updateWithoutTx("DROP TABLE \(name)")
    }
    
    func rowFields(r: Row) -> [String] {
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
        }
      }
      return fieldStrArr
    }
    
    func insertAndUpdate(insertRows: [Row], updateRows: [Row]) -> Future<DB.Result> {
      var queries: [DB.QueryArgs] = []
      if insertRows.count > 0 {
        let query = "INSERT INTO \(name) (\(fieldNamesStr)) values (\(fieldNamesPlaceholderStr))"
        for row in insertRows {
          let args = rowFields(row)
          queries.append(DB.QueryArgs(query: query, args: args))
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
            let pairsStr = ", ".join(pairs)
            let query = "UPDATE \(name) SET \(pairsStr) WHERE \(primaryKey) = ?"
            args.append(primaryKeyVal)
            queries.append(DB.QueryArgs(query: query, args: args))
          } else {
            let p = Promise<DB.Result>()
            p.success(.Error(-1, "Cannot update without primary key!"))
            return p.future
          }
        }
      }
      return db.update(queries)
    }
    
    public func insert(rows: [Row]) -> Future<DB.Result> {
      return insertAndUpdate(rows, updateRows: [])
    }
    
    public func update(rows: [Row]) -> Future<DB.Result> {
      return insertAndUpdate([], updateRows: rows)
    }
    
    public func upsert(rows: [Row]) -> Future<DB.Result> {
      let p = Promise<DB.Result>()
      
      var idList: [String] = []
      var placeholderList: [String] = []
      for row in rows {
        if let rowId = row.fields[primaryKey] as? String {
          idList.append(rowId)
          placeholderList.append("?")
        }
      }
      let placeholderListStr = ",".join(placeholderList)
      var foundIds: [String: Bool] = [:]
      
      let selectQuery = "SELECT \(primaryKey) FROM \(name) WHERE \(primaryKey) in (\(placeholderListStr))"
      // NSLog("Upsert idList=\(idList) selectQuery=\(selectQuery)")
      db.query(selectQuery, args: idList).onSuccess { result in
        
        switch result {
        case .Success:
          break
        case .Error(let code, let message):
          return p.success(result)
        case .Items(let items):
          for item in items {
            if let v = item[self.primaryKey] as? String {
              foundIds[v] = true
            }
          }
        }
        
        // NSLog("Upsert numRows=\(rows.count) foundRows=\(foundIds)")
        
        if foundIds.count == 0 {
          // Simple case: everything should be inserted
          self.insert(rows).onSuccess { result in
            p.success(result)
          }
        } else {
          // Complex case: mixture of insert and update
          var insertRows: [Row] = []
          var updateRows: [Row] = []
          
          for row in rows {
            if let rowId = row.fields[self.primaryKey] as? String {
              if let foundRowId = foundIds[rowId] {
                updateRows.append(row)
              } else {
                insertRows.append(row)
              }
            }
          }
          // NSLog("Upsert insertRows=\(insertRows.count) updateRows=\(updateRows.count)")
          
          self.insertAndUpdate(insertRows, updateRows: updateRows).onSuccess { result in
            p.success(result)
          }
        }
      }
      
      return p.future
    }
    
    public func select(whereStr: String = "") -> Future<DB.Result> {
      var finalWhereString = whereStr
      if count(finalWhereString) > 0 {
        finalWhereString = " WHERE \(whereStr)"
      }
      let query = "SELECT * FROM \(name)\(whereStr)"
      return db.query(query)
    }
    
    public func delete(rows: [Row]) -> Future<DB.Result> {
      var queries: [DB.QueryArgs] = []
      for row in rows {
        if let primaryKeyValue: AnyObject = row.fields[primaryKey] {
          let query = "DELETE FROM \(name) WHERE \(primaryKey) = ?"
          queries.append(DB.QueryArgs(query: query, args: [primaryKeyValue]))
        } else {
          let p = Promise<DB.Result>()
          p.success(.Error(-1, "Cannot update without primary key!"))
          return p.future
        }
      }
      return db.update(queries)
    }
  }
}

