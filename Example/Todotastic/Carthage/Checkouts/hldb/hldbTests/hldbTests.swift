//
//  hldbTests.swift
//  hldbTests
//
//  Created by Ben Garrett on 6/14/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import XCTest
import hldb
import Result
import Nimble
import Quick


public class TestEntity: Entity {
  lazy var id: String = self.stringValue("id")
  lazy var info: String = self.stringValue("info")
  lazy var num: Int = self.intValue("num")
  
  override public func toFields() -> NSMutableDictionary {
    return ["id": id,
            "info": info,
            "num" : num]
  }
}


class hldbTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
  func testCreatingandDestroyingTable() {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
      
        // given
        let fields: [HLDB.Table.Field] = [
          HLDB.Table.Field(name: "id",       type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
          HLDB.Table.Field(name: "ts",       type: .Real, index: .Index, defaultValue: .NonNull),
          HLDB.Table.Field(name: "kind",     type: .Text, index: .None, defaultValue: .NonNull)
        ]
      
        let tableName = "mytable"
        let dbModel = DBModel()
      
      
        // when
        let table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
        table.create()
        dbModel.registerTable(table)
      
      
        // then
        expect(dbModel.tables.count).to(equal(1))
        let tableCheck = dbModel.getTable(tableName, fields: [])
        
        expect(table.fieldNames).to(equal(tableCheck.fieldNames))
      
        // when
        dbModel.dropTable(tableName)
      
      
        //then
        expect(dbModel.tables.count).to(equal(0))
 
      
      
    }
  
  
  func testCreatingDuplicateTable() {
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    // given
    let fields: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",       type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "ts",       type: .Real, index: .Index, defaultValue: .NonNull),
      HLDB.Table.Field(name: "kind",     type: .Text, index: .None, defaultValue: .NonNull)
    ]
    
    let fields2: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",       type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "ts2",       type: .Real, index: .Index, defaultValue: .NonNull),
      HLDB.Table.Field(name: "kind2",     type: .Text, index: .None, defaultValue: .NonNull)
    ]
    
    let tableName = "mytable"
    let dbModel = DBModel()
    
    
    // when
    let table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    table.create()
    dbModel.registerTable(table)
    
    let tableDup = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    tableDup.create()
    dbModel.registerTable(tableDup)
    
    let table2 = HLDB.Table(db: dbModel.db, name: tableName, fields: fields2)
    table2.create()
    dbModel.registerTable(table2)

    
    // then
    expect(dbModel.tables.count).to(be(1)) // "dbModel tables length incorrect"
    let tableCheck = dbModel.getTable(tableName, fields: [])
    
    expect(table.fieldNames).to(equal(tableCheck.fieldNames))
  
    dbModel.dropTable(tableName)
    
  }
  
  func testInsertingAndDeletingRowsFromTable() {
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    // given
    let fields: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",     type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "count",  type: .Real, index: .Index, defaultValue: .NonNull),
      HLDB.Table.Field(name: "type",   type: .Text, index: .None, defaultValue: .NonNull)
    ]
    
    let tableName = "mytable"
    let dbModel = DBModel()
    
    let table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    table.create()
    dbModel.registerTable(table)
    
    
    // when
    let rows: [HLDB.Table.Row] = [
      HLDB.Table.Row(fields: ["id": "new", "count": 35, "type": "book"]),
      HLDB.Table.Row(fields: ["id": "new2", "count": -1035, "type": "movie"]),
      HLDB.Table.Row(fields: ["id": "new3", "count": -5, "type": "cash"])
    ]
    
    table.insert(rows)
    
    
    // then
    table.select("WHERE count >= 0").onSuccess{ (result: HLDB.DB.Result) in
      switch(result) {
      
      case .Items(let items):
        expect(items.count).to(equal(1))
        let item = items[0]
        expect(item["id"] as? String).to(equal("new"))
        expect(item["count"] as? Int).to(equal(35))
        expect(item["type"] as? String).to(equal("book"))
        
      case .Success:
        XCTAssert(false, "call returned without items")
        
      case .Error(_, _):
        XCTAssert(false, "call failed with error")
        
      }
    }
    
    
    // when
    table.delete(rows)
    
    
    // then
    table.select("WHERE count >= 0").onSuccess{ (result: HLDB.DB.Result) in
      switch(result) {
        
      case .Items(let items):
        expect(items.count).to(equal(0))
        
      case .Success:
        XCTAssert(false, "call returned without items")
        
      case .Error(_, _):
        XCTAssert(false, "call failed with error")
        
      }
    }
  
    
    dbModel.dropTable(tableName)
    
  }
  
  func testInsertingAndUpdatingRowsFromTable() {
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    // given
    let fields: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",     type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "count",  type: .Real, index: .Index, defaultValue: .NonNull),
      HLDB.Table.Field(name: "type",   type: .Text, index: .None, defaultValue: .NonNull)
    ]
    
    let tableName = "mytable"
    let dbModel = DBModel()
    
    let table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    table.create()
    dbModel.registerTable(table)
    
    
    // when
    let rows: [HLDB.Table.Row] = [
      HLDB.Table.Row(fields: ["id": "new", "count": 35, "type": "book"]),
      HLDB.Table.Row(fields: ["id": "new2", "count": -1035, "type": "movie"]),
      HLDB.Table.Row(fields: ["id": "new3", "count": -5, "type": "cash"])
    ]
    
    table.insert(rows)
    
    
    // then
    table.select("WHERE count >= 0").onSuccess{ (result: HLDB.DB.Result) in
      switch(result) {
        
      case .Items(let items):
        expect(items.count).to(equal(1))
        let item = items[0]
        expect(item["id"] as? String).to(equal("new"))
        expect(item["count"] as? Int).to(equal(35))
        expect(item["type"] as? String).to(equal("book"))
        
      case .Success:
        XCTAssert(false, "call returned without items")
        
      case .Error(_, _):
        XCTAssert(false, "call failed with error")
        
      }
    }
    
    
    // when
    let newRows: [HLDB.Table.Row] = [
      HLDB.Table.Row(fields: ["id": "new", "count": 36, "type": "comic book"]),
      HLDB.Table.Row(fields: ["id": "new2", "count": -2, "type": "action movie"]),
      HLDB.Table.Row(fields: ["id": "new3", "count": -10, "type": "cash money"])
    ]
    
    table.update(newRows)
    
    
    // then
    table.select("WHERE count >= 0").onSuccess{ (result: HLDB.DB.Result) in
      switch(result) {
        
      case .Items(let items):
        expect(items.count).to(equal(1))
        let item = items[0]
        expect(item["id"] as? String).to(equal("new"))
        expect(item["count"] as? Int).to(equal(36))
        expect(item["type"] as? String).to(equal("comic book"))
        
        
      case .Success:
        XCTAssert(false, "call returned without items")
        
      case .Error(_, _):
        XCTAssert(false, "call failed with error")
        
      }
    }
    
    
    dbModel.dropTable(tableName)
    
  }
  
  func testEntityMD5Functionality() {
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    // given
    let fields: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",     type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "info",   type: .Text, index: .None, defaultValue: .NonNull),
      HLDB.Table.Field(name: "num",  type: .Integer, index: .Index, defaultValue: .NonNull)
    ]
    
    
    // TODO: make testentity, save md5 and insert into table- then pop out of table, and compare to prev md5 and manually calculated md5
    
    // maybe also test toJSON?
    
    
    let tableName = "mytable"
    let dbModel = DBModel()
    
    let table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    table.create()
    dbModel.registerTable(table)
    
    let entity: TestEntity = TestEntity(fields: ["id":"test","info":"this is a test","num":4])
    
    let prevMD5 = entity.md5()
    
    let tr: HLDB.Table.Row = entity.toRow()
    
    // when
    table.upsert([tr])

    
    // then
    table.select("").onSuccess{ (result: HLDB.DB.Result) in
      switch(result) {
        
      case .Items(let items):
        expect(items.count).to(equal(1))
        let item = items[0]
        expect(item["id"] as? String).to(equal("test"))
        expect(item["num"] as? Int).to(equal(4))
        expect(item["info"] as? String).to(equal("this is a test"))
        
        let compareEntity = TestEntity(fields: item)
        
        let newMD5 = compareEntity.md5()
        
        expect(prevMD5).to(equal(newMD5))
        expect(newMD5).to(equal(self.md5(compareEntity.toJSON().dataUsingEncoding(NSUTF8StringEncoding))))
      case .Success:
        XCTAssert(false, "call returned without items")
        
      case .Error(_, _):
        XCTAssert(false, "call failed with error")
        
      }
    }
    
    
    dbModel.dropTable(tableName)
    
  }
  
  func md5(d: NSData?) -> String {
    guard let data = d else { return "FAIL" }
    
    let digestLength = Int(CC_MD5_DIGEST_LENGTH)
    let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
    
    CC_MD5(data.bytes, CC_LONG(data.length), md5Buffer)
    let output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
    for i in 0..<digestLength {
      output.appendFormat("%02x", md5Buffer[i])
    }
    return NSString(format: output) as String
  }
  
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
