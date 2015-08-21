//
//  HLModularTests.swift
//  HLModularTests
//
//  Created by Ben Garrett on 7/3/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import UIKit
import XCTest

class HLDBTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testExample() {
    // This is an example of a functional test case.
    XCTAssert(true, "Pass")
  }
  
  func testCreateDB() {
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    let q = db.getQueue()
    
    // does the file exist?
    let dbPath = HLDB.DB.pathForDBFile(fileName)
    
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath(dbPath) {
      XCTAssert(false, "DB file did not exist!")
    }
    
    // delete it
    HLDB.DB.deleteDB(fileName)
    
    // is it gone?
    if fm.fileExistsAtPath(dbPath) {
      XCTAssert(true, "DB file is still there!")
    }
    
    // it worked
    XCTAssert(true, "Pass")
  }
  
  func simpleTable(db: HLDB.DB, name: String) -> HLDB.Table {
    let fields = [ HLDB.Table.Field(name: "id", type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "v", type: .Text, index: .None, defaultValue: .NonNull),
      HLDB.Table.Field(name: "ts", type: .Integer, index: .None, defaultValue: .NonNull)]
    return HLDB.Table(db: db, name: name, fields: fields)
  }
  
  func testCreateTable() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    let tableName = "Mucus"
    let table = simpleTable(db, name: tableName)
    table.create()
    
    db.query("select name from sqlite_master where type='table'").onSuccess { result in
      switch result {
      case .Success:
        XCTAssert(false, "Tables query returned success rather than the tables")
      case .Error(let code, let message):
        XCTAssert(false, "Tables query returned error \(code) \(message)")
      case .Items(let arr):
        if arr.count != 1 {
          XCTAssert(false, "Expected one table")
        }
        let firstItem = arr[0]
        if let t = firstItem["name"] as? String {
          if t != tableName {
            XCTAssert(false, "Expected found table name to match")
          }
        } else {
          XCTAssert(false, "Expected table name to be a string")
        }
      }
      
      table.drop()
      db.query("select name from sqlite_master where type='table'").onSuccess { result in
        switch result {
        case .Success:
          XCTAssert(false, "Tables query returned success rather than the tables")
        case .Error(let code, let message):
          XCTAssert(false, "Tables query returned error \(code) \(message)")
        case .Items(let arr):
          if arr.count != 0 {
            XCTAssert(false, "Expected zero tables")
          }
          
          finishedExpectation.fulfill()
        }
      }
    }
    
    // Loop until the expectation is fulfilled
    waitForExpectationsWithTimeout(1) { error in
      XCTAssertNil(error, "Error")
    }
  }

  func testDelete() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    
    let tableName = "DeletableTable"
    let table = simpleTable(db, name: tableName)
    table.create()
    
    // now insert an item
    let row1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
      "v"  : "monkeyvalue",
      "ts" : 1000])
    let row2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
      "v"  : "marsupialvalue",
      "ts" : 1001])
    table.insert([row1, row2]).onSuccess { result in
      
      switch result {
      case .Success:
        break
      case .Error(let code, let message):
        XCTAssert(false, "Insert query returned error \(code) \(message)")
      case .Items(let items):
        XCTAssert(false, "Insert query returned items rather than success")
      }
      
      // query to see if we can find those items
      table.select().onSuccess { result in
        switch result {
        case .Success:
          XCTAssert(false, "Insert query returned success rather than items")
        case .Error(let code, let message):
          XCTAssert(false, "Insert query returned error \(code) \(message)")
        case .Items(let items):
          
          if items.count != 2 {
            XCTAssert(false, "Expected two items!")
          }
          
          // now delete these two items
          let deleteRow1 = HLDB.Table.Row(fields: ["id": "monkeyid"])
          let deleteRow2 = row2
          table.delete([deleteRow1, deleteRow2]).onSuccess { result in
            
            switch result {
            case .Success:
              break
            case .Error(let code, let message):
              XCTAssert(false, "Delete query returned error \(code) \(message)")
            case .Items(let items):
              XCTAssert(false, "Delete query returned items instead of success")
            }
            
            table.select().onSuccess { result in
              switch result {
              case .Success:
                XCTAssert(false, "Select query returned success rather than items")
              case .Error(let code, let message):
                XCTAssert(false, "Select query returned error \(code) \(message)")
              case .Items(let items):
                if items.count != 0 {
                  XCTAssert(false, "Select query returned more than zero items.")
                }
              }
              
              // and drop the table
              table.drop()
              finishedExpectation.fulfill()
            }
          }
        }
      }
    }
    
    // Loop until the expectation is fulfilled
    waitForExpectationsWithTimeout(1) { error in
      XCTAssertNil(error, "Error")
    }
  }
  
  func testUpdate() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    
    let tableName = "UpdateableTable"
    let table = simpleTable(db, name: tableName)
    table.create()
    
    // now insert an item
    let row1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
      "v"  : "monkeyvalue",
      "ts" : 1000])
    let row2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
      "v"  : "marsupialvalue",
      "ts" : 1001])
    table.insert([row1, row2]).onSuccess { result in
      
      switch result {
      case .Success:
        break
      case .Error(let code, let message):
        XCTAssert(false, "Insert query returned error \(code) \(message)")
      case .Items(let items):
        XCTAssert(false, "Insert query returned items rather than success")
      }
      
      // now update an item
      let row1Update = HLDB.Table.Row(fields: ["id" : "monkeyid", "v" : "monkeyvalue2", "ts": 2000])
      let row2Update = HLDB.Table.Row(fields: ["id" : "marsupialid", "v" : "marsupialvalue2"])
      
      table.update([row1Update, row2Update]).onSuccess { result in
        
        switch result {
        case .Success:
          break
        case .Error(let code, let message):
          XCTAssert(false, "Insert query returned error \(code) \(message)")
        case .Items(let items):
          XCTAssert(false, "Insert query returned items rather than success")
        }
        
        // query to see if we can find those items
        table.select().onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Insert query returned success rather than items")
          case .Error(let code, let message):
            XCTAssert(false, "Insert query returned error \(code) \(message)")
          case .Items(let items):
            
            if items.count != 2 {
              XCTAssert(false, "Expected two items!")
            }
            
            var matched = false
            if let item1 = items[0] as? NSMutableDictionary {
              let foundRow1 = HLDB.Table.Row(fields: item1)
              if foundRow1 == row1Update {
                matched = true
              }
            }
            if matched == false {
              XCTAssert(false, "Updated item did not match")
            }
            
            if let item2 = items[1] as? NSMutableDictionary {
              let foundRow2 = HLDB.Table.Row(fields: item2)
              if foundRow2 == row2 || foundRow2 == row2Update {
                XCTAssert(false, "Updated row matched the wrong row")
              }
              
              let finalRow2 = HLDB.Table.Row(fields: ["id" : "marsupialid", "v" : "marsupialvalue2", "ts" : 1001])
              if foundRow2 != finalRow2 {
                XCTAssert(false, "Updated row did not match what final row should be")
              }
            }
          }
          
          // and drop the table
          table.drop()
          finishedExpectation.fulfill()
        }
        
        return
      }
    }
    
    // Loop until the expectation is fulfilled
    waitForExpectationsWithTimeout(1) { error in
      XCTAssertNil(error, "Error")
    }
  }
  
  func testInsert() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    
    let tableName = "InsertableTable"
    let table = simpleTable(db, name: tableName)
    table.create()
    
    // now insert an item
    let row1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
      "v"  : "monkeyvalue",
      "ts" : 1000])
    let row2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
      "v"  : "marsupialvalue",
      "ts" : 1001])
    table.insert([row1, row2]).onSuccess { result in
      
      switch result {
      case .Success:
        break
      case .Error(let code, let message):
        XCTAssert(false, "Insert query returned error \(code) \(message)")
      case .Items(let items):
        XCTAssert(false, "Insert query returned items rather than success")
      }
      
      // query to see if we can find those items
      table.select().onSuccess { result in
        switch result {
        case .Success:
          XCTAssert(false, "Insert query returned success rather than items")
        case .Error(let code, let message):
          XCTAssert(false, "Insert query returned error \(code) \(message)")
        case .Items(let items):
          
          if items.count != 2 {
            XCTAssert(false, "Expected two items!")
          }
          
          var matched = false
          if let item1 = items[0] as? NSMutableDictionary {
            if let item2 = items[1] as? NSMutableDictionary {
              let foundRow1 = HLDB.Table.Row(fields: item1)
              let foundRow2 = HLDB.Table.Row(fields: item2)
              if foundRow1 == row1 && foundRow2 == row2 {
                matched = true
              }
            }
          }
          
          if !matched {
            XCTAssert(false, "Rows don't match")
          }
          
          // and drop the table
          table.drop()
          finishedExpectation.fulfill()
        }
      }
    }
    
    // Loop until the expectation is fulfilled
    waitForExpectationsWithTimeout(1) { error in
      XCTAssertNil(error, "Error")
    }
  }
  
  func testUpsert() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    
    let tableName = "InsertableTable"
    let table = simpleTable(db, name: tableName)
    table.create()
    
    // now insert an item
    let row1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
      "v"  : "monkeyvalue",
      "ts" : 1000])
    let row2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
      "v"  : "marsupialvalue",
      "ts" : 1001])
    table.upsert([row1, row2]).onSuccess { result in
      
      switch result {
      case .Success:
        break
      case .Error(let code, let message):
        XCTAssert(false, "Upsert query returned error \(code) \(message)")
      case .Items(let items):
        XCTAssert(false, "Upsert query returned items rather than success")
      }
      
      // query to see if we can find those items
      table.select().onSuccess { result in
        switch result {
        case .Success:
          XCTAssert(false, "Select query returned success rather than items")
        case .Error(let code, let message):
          XCTAssert(false, "Select query returned error \(code) \(message)")
        case .Items(let items):
          
          if items.count != 2 {
            XCTAssert(false, "Expected two items!")
          }
          
          var matched = false
          if let item1 = items[0] as? NSMutableDictionary {
            if let item2 = items[1] as? NSMutableDictionary {
              let foundRow1 = HLDB.Table.Row(fields: item1)
              let foundRow2 = HLDB.Table.Row(fields: item2)
              if foundRow1 == row1 && foundRow2 == row2 {
                matched = true
              }
            }
          }
          
          if !matched {
            XCTAssert(false, "Rows don't match")
          }
        }
        
        // now upsert one of the rows and check it and add another one
        let updatedRow2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
          "v"  : "marsupialvalue2",
          "ts" : 2001])
        table.upsert([updatedRow2]).onSuccess { result in
          switch result {
          case .Success:
            break
          case .Error(let code, let message):
            XCTAssert(false, "Upsert query returned error \(code) \(message)")
          case .Items(let items):
            XCTAssert(false, "Upsert query returned itesm rather than success")
          }
          
          // now select again and validate the updated row
          table.select().onSuccess { result in
            switch result {
            case .Success:
              XCTAssert(false, "Select query returned success rather than items")
            case .Error(let code, let message):
              XCTAssert(false, "Select query returned error \(code) \(message)")
            case .Items(let items):
              
              if items.count != 2 {
                XCTAssert(false, "Expected two items!")
              }
              
              var matched = false
              if let item1 = items[0] as? NSMutableDictionary {
                if let item2 = items[1] as? NSMutableDictionary {
                  let foundRow1 = HLDB.Table.Row(fields: item1)
                  let foundRow2 = HLDB.Table.Row(fields: item2)
                  if foundRow1 == row1 && foundRow2 == updatedRow2 {
                    matched = true
                  }
                }
              }
              
              if !matched {
                XCTAssert(false, "Rows don't match")
              }
            }
            
            // now update both rows and add a third
            let updatedRow1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
              "v"  : "monkeyvalue3",
              "ts" : 3000])
            let updatedRow2 = HLDB.Table.Row(fields: ["id" : "marsupialid",
              "v"  : "marsupialvalue3",
              "ts" : 3001])
            let row3 = HLDB.Table.Row(fields: ["id" : "zebraid",
              "v"  : "zebravalue3",
              "ts" : 3002])
            table.upsert([updatedRow1, updatedRow2, row3]).onSuccess { result in
              switch result {
              case .Success:
                break
              case .Error(let code, let message):
                XCTAssert(false, "Upsert query returned error \(code) \(message)")
              case .Items(let items):
                XCTAssert(false, "Upsert query returned itesm rather than success")
              }
              
              table.select().onSuccess { result in
                switch result {
                case .Success:
                  XCTAssert(false, "Select query returned success rather than items")
                case .Error(let code, let message):
                  XCTAssert(false, "Select query returned error \(code) \(message)")
                case .Items(let items):
                  
                  if items.count != 3 {
                    XCTAssert(false, "Expected three items!")
                  }
                  
                  var matched = false
                  if let item1 = items[0] as? NSMutableDictionary {
                    if let item2 = items[1] as? NSMutableDictionary {
                      if let item3 = items[2] as? NSMutableDictionary {
                        let foundRow1 = HLDB.Table.Row(fields: item1)
                        let foundRow2 = HLDB.Table.Row(fields: item2)
                        let foundRow3 = HLDB.Table.Row(fields: item3)
                        if foundRow1 == updatedRow1 && foundRow2 == updatedRow2 && foundRow3 == row3 {
                          matched = true
                        }
                      }
                    }
                  }
                  
                  if !matched {
                    XCTAssert(false, "Rows don't match")
                  }
                }
                
                table.drop()
                finishedExpectation.fulfill()
              }
            }
          }
        }
      }
    }
    
    // Loop until the expectation is fulfilled
    waitForExpectationsWithTimeout(1) { error in
      XCTAssertNil(error, "Error")
    }
  }
  
  func testInsertPerf() {
    self.measureBlock() {
      let finishedExpectation = self.expectationWithDescription("finished")
      
      let fileName = "dbfile"
      let db = HLDB.DB(fileName: fileName)
      
      let tableName = "InsertablePerfTable"
      let table = self.simpleTable(db, name: tableName)
      table.create()
      
      // now insert an item
      var rows: [HLDB.Table.Row] = []
      for idx in 0..<100 {
        rows.append(HLDB.Table.Row(fields: ["id" : "monkeyid",
          "v"  : "monkeyvalue",
          "ts" : idx]))
      }
      
      table.insert(rows).onSuccess { result in
        table.drop()
        finishedExpectation.fulfill()
      }
      
      // Loop until the expectation is fulfilled
      self.waitForExpectationsWithTimeout(10) { error in
        XCTAssertNil(error, "Error")
      }
    }
    
  }
  
  
  func tableWithIndices(db: HLDB.DB, name: String) -> HLDB.Table {
    let fields = [ HLDB.Table.Field(name: "id", type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "a", type: .Text, index: .None, defaultValue: .NonNull),
      HLDB.Table.Field(name: "b", type: .Integer, index: .Unique, defaultValue: .NonNull),
      HLDB.Table.Field(name: "c", type: .Text, index: .Index, defaultValue: .NonNull),
      HLDB.Table.Field(name: "d", type: .Integer, index: .Index, defaultValue: .NonNull)]
    return HLDB.Table(db: db, name: name, fields: fields)
  }
  
  func testCreateIndices() {
    let finishedExpectation = expectationWithDescription("finished")
    
    let fileName = "dbfile"
    let db = HLDB.DB(fileName: fileName)
    let tableName = "IndexTable"
    let table = tableWithIndices(db, name: tableName)
    table.create()
    
    db.query("select name from sqlite_master where type='table'").onSuccess { result in
      switch result {
      case .Success:
        XCTAssert(false, "Tables query returned success rather than the tables")
      case .Error(let code, let message):
        XCTAssert(false, "Tables query returned error \(code) \(message)")
      case .Items(let arr):
        if arr.count != 1 {
          XCTAssert(false, "Expected one table")
        }
        let firstItem = arr[0]
        if let t = firstItem["name"] as? String {
          if t != tableName {
            XCTAssert(false, "Expected found table name to match")
          }
        } else {
          XCTAssert(false, "Expected table name to be a string")
        }
      }
      
      // inserting some rows
      let row1 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a1",
        "b" : 1,
        "c" : "c1",
        "d" : 1])
      let row2 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a2",
        "b" : 2,
        "c" : "c2",
        "d" : 1])
      let row3 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a3",
        "b" : 3,
        "c" : "c3",
        "d" : 2])
      let row4 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a4",
        "b" : 1,
        "c" : "c4",
        "d" : 2])
      let row5 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a5",
        "b" : 2,
        "c" : "c5",
        "d" : 3])
      let row6 = HLDB.Table.Row(fields: ["id" : "monkeyid",
        "a"  : "a6",
        "b" : 3,
        "c" : "c6",
        "d" : 3])
      table.insert([row1, row2, row3, row4, row5, row6]).onSuccess { result in
        
        switch result {
        case .Success:
          break
        case .Error(let code, let message):
          XCTAssert(false, "Insert query returned error \(code) \(message)")
        case .Items(let items):
          XCTAssert(false, "Insert query returned items rather than success")
        }
        
        // query to see if we can find those items
        table.select().onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Insert query returned success rather than items")
          case .Error(let code, let message):
            XCTAssert(false, "Insert query returned error \(code) \(message)")
          case .Items(let items):
            
            if items.count != 6 {
              XCTAssert(false, "Expected six items!")
            }
          }
        }
        
        table.select(whereStr: "c='c3'").onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Insert query returned success rather than items")
          case .Error(let code, let message):
            XCTAssert(false, "Insert query returned error \(code) \(message)")
          case .Items(let items):
            
            if items.count != 1 {
              XCTAssert(false, "Expected one item!")
            }
          }
        }
        
        table.select(whereStr: "d=3").onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Insert query returned success rather than items")
          case .Error(let code, let message):
            XCTAssert(false, "Insert query returned error \(code) \(message)")
          case .Items(let items):
            
            if items.count != 2 {
              XCTAssert(false, "Expected two items!")
            }
          }
        }
        
        table.select(whereStr: "d=2 AND c='c3'").onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Insert query returned success rather than items")
          case .Error(let code, let message):
            XCTAssert(false, "Insert query returned error \(code) \(message)")
          case .Items(let items):
            
            if items.count != 1 {
              XCTAssert(false, "Expected one item!")
            }
          }
        }
        
        table.drop()
        db.query("select name from sqlite_master where type='table'").onSuccess { result in
          switch result {
          case .Success:
            XCTAssert(false, "Tables query returned success rather than the tables")
          case .Error(let code, let message):
            XCTAssert(false, "Tables query returned error \(code) \(message)")
          case .Items(let arr):
            if arr.count != 0 {
              XCTAssert(false, "Expected zero tables")
            }
            
            finishedExpectation.fulfill()
          }
        }
      }
      
      // Loop until the expectation is fulfilled
      self.waitForExpectationsWithTimeout(1) { error in
        XCTAssertNil(error, "Error")
      }
    }
  }
}
