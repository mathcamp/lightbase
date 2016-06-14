//
//  hldbTests.swift
//  hldbTests
//
//  Created by Ben Garrett on 6/14/16.
//  Copyright © 2016 Mathcamp. All rights reserved.
//

import XCTest
import hldb

class hldbTests: XCTestCase {
    
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
        // Use XCTAssert and related functions to verify your tests produce the correct results.
      
        let fields: [HLDB.Table.Field] = [
          HLDB.Table.Field(name: "id",       type: .Text, index: .PrimaryKey, defaultValue: .NonNull),
          HLDB.Table.Field(name: "ts",       type: .Real, index: .Index, defaultValue: .NonNull),
          HLDB.Table.Field(name: "kind",     type: .Text, index: .None, defaultValue: .NonNull)
        ]
      
        let db = DBModel()
        let tableName = "mytable"
        let table = db.getTable(tableName, fields: fields)
      
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
