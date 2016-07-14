//
//  DBModel.swift
//  NeoHighlight
//
//  Created by Ben Garrett on 11/7/15.
//  Copyright © 2015 Mathcamp. All rights reserved.
//

import Foundation
import Result
import BrightFutures

public class DBModel <BackDB: AbstractDB, BackDBQueue: AbstractDBQueue where BackDB.Cursor : LazySequenceType, BackDB.Cursor.Generator.Element == NSDictionary, BackDBQueue.DB == BackDB> {
  public let dbFileName = "hldb"
  public let db: DB<BackDB, BackDBQueue>
  public var tables = Dictionary<String, Table<BackDB, BackDBQueue>>()
  
  public init() {
    db = DB(fileName: dbFileName)
  }
  
  public func resetAll() {
    for (_, table) in tables { table.dropAndCreate() }
  }
  
  public func registerTable(t: Table<BackDB, BackDBQueue>) {
    if tables[t.name] == nil {
      tables[t.name] = t
    }
  }
  
  public func dropTable(name: String) -> Future<(), NoError> {
    if let zombieTable = tables[name] {
      tables[name] = nil
      return zombieTable.drop()
    } else {
      return Future(value: ())
    }
  }
  
  public func getTable(name: String, fields: [NSDictionary]) -> Table<BackDB, BackDBQueue> {
    //see if table exists first
    if let table = tables[name] {
      return table
    }
    
    //otherwise create it
    let table = Table(db: db, name: name, fields: arrayToFields(fields))
    if fields.count > 1 {
      table.create()
    } else {
      print("HLDB: Cannot create a table with less than 2 fields!!!")
      return table
    }
    
    registerTable(table)
    return table
  }
  
  
  public func arrayToFields(fields: [NSDictionary]) -> [TableField] {
    var fieldsArr: [TableField] = []
    for dict in fields {
      if let name = dict["name"] as? String, type = dict["type"] as? String, index = dict["index"] as? String {
        if let type = TableType(rawValue: type), index = TableIndex(rawValue: index) {
          fieldsArr.append(TableField(name: name, type: type, index: index, defaultValue: .NonNull))
        }
      }
    }
    return fieldsArr
  }
  
}
