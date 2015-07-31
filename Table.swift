//
//  Table.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

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
