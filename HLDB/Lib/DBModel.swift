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
  public var tables: [HLDB.Table] = []
  
  public init() {
    db = HLDB.DB(fileName: dbFileName)
  }
  
  public func resetAll() {
    for table in tables { table.dropAndCreate() }
  }
  
  public func registerTable(t: HLDB.Table) {
    tables.append(t)
  }
  
  public func dropTable(name: String) -> Future<(), NoError> {
    if let idx = (tables.map{ $0.name }.indexOf(name)) {
      let zombieTable = tables.removeAtIndex(idx)
      return zombieTable.drop()
    } else {
      return Future(value: ())
    }
  }
  
  public func getTable(name: String, fields: [NSDictionary]) -> HLDB.Table {
    //see if table exists first
    for table in tables {
      if table.name == name { return table }
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
