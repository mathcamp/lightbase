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

public class DBModel {
  public let dbFileName = "hldb"
  public let db: HLDB.DB
  public var tables = Dictionary<String, HLDB.Table>()
  
  public init() {
    db = HLDB.DB(fileName: dbFileName)
  }
  
  public func resetAll() {
    for (_, table) in tables { table.dropAndCreate() }
  }
  
  public func registerTable(t: HLDB.Table) {
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
  
  public func getTable(name: String, fields: [NSDictionary]) -> HLDB.Table {
    //see if table exists first
    if let table = tables[name] {
      return table
    }
    
    //otherwise create it
    let table = HLDB.Table(db: db, name: name, fields: arrayToFields(fields))
    if fields.count > 1 {
      table.create()
    } else {
      print("HLDB: Cannot create a table with less than 2 fields!!!")
      return table
    }
    
    registerTable(table)
    return table
  }
  
  
  public func arrayToFields(fields: [NSDictionary]) -> [HLDB.Table.Field] {
    var fieldsArr: [HLDB.Table.Field] = []
    for dict in fields {
      if let name = dict["name"] as? String, type = dict["type"] as? String, index = dict["index"] as? String {
        if let type = HLDB.Table.Type(rawValue: type), index = HLDB.Table.Index(rawValue: index) {
          fieldsArr.append(HLDB.Table.Field(name: name, type: type, index: index, defaultValue: .NonNull))
        }
      }
    }
    return fieldsArr
  }
  
}
