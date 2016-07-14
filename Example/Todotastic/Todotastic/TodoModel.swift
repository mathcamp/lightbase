//
//  TodoModel.swift
//  Todotastic
//
//  Created by Ben Garrett on 6/21/16.
//  Copyright © 2016 Highlight. All rights reserved.
//

import Foundation
import BrightFutures
import Result

enum EditState {
  case NotEditing
  case Editing(TodoTableViewCell)
}

struct TodoItem {
  static var idCounter = 0
  let id: Int
  var label: String
  var checked: Bool = false
  init(label: String) {
    self.id = TodoItem.idCounter
    TodoItem.idCounter += 1
    self.label = label
  }
  init(id: Int, label: String, checked: Bool) {
    self.id = id
    self.label = label
    self.checked = checked
  }
}

class TodoItemEntity : Entity {
  lazy var id: Int = self.intValue("id")
  lazy var label: String = self.stringValue("label")
  lazy var checked: Bool = self.boolValue("checked")
    
  override func toFields() -> NSMutableDictionary {
    return ["id": id,
            "label": label,
            "checked" : checked]
  }
}

class TodoModel {
  var editState: EditState = .NotEditing
  private var todoList: [TodoItem] = []
  
  private var tableName: String
  private var table: HLDB.Table
  private var dbModel: DBModel
  
  init() {
    // given
    let fields: [HLDB.Table.Field] = [
      HLDB.Table.Field(name: "id",     type: .Integer, index: .PrimaryKey, defaultValue: .NonNull),
      HLDB.Table.Field(name: "label",  type: .Text, index: .None, defaultValue: .NonNull),
      HLDB.Table.Field(name: "checked",   type: .Bool, index: .Index, defaultValue: .NonNull)
    ]
    
    tableName = "todoListTabl"
    dbModel = DBModel()
    
    table = HLDB.Table(db: dbModel.db, name: tableName, fields: fields)
    table.create()
    dbModel.registerTable(table)
    
    
  }
  
  
  func TodoItemToRow(item: TodoItem) -> HLDB.Table.Row {
    return HLDB.Table.Row(fields: ["id": item.id, "label": item.label, "checked": item.checked])
  }
  
  func ResultDictToRowItem(item: NSDictionary) -> TodoItem {
    let todoEntity = TodoItemEntity(fields:item)
    return TodoItem(id: todoEntity.id, label: todoEntity.label, checked: todoEntity.checked)
  }
  
  func loadItems() -> Future<(), NoError> {
    return table.select("ORDER BY id DESC").map({result in
      switch(result) {
      case .Success:
        break
      case .Items(let items):
        self.todoList = items.map({item in
          print(item)
          return self.ResultDictToRowItem(item)
        })
        if (self.todoList.count > 0) {
          TodoItem.idCounter = self.todoList[0].id + 1
        }
        print(TodoItem.idCounter)
        break
      case .Error( _, _):
        print("ERROR")
        break
      }
      return ()
    })
  }
  
  internal func addTodoItem(item: TodoItem) {
    self.todoList.insert(item, atIndex: 0)
    let row = TodoItemToRow(item)
    table.insert([row])
  }
  
  internal func removeTodoItemAtIndex(index: Int) {
    let item = self.todoList[index]
    self.todoList.removeAtIndex(index);
    table.delete([TodoItemToRow(item)])
  }
  
  func atIndex(index: Int) -> TodoItem{
    return self.todoList[index]
  }
  
  func setLabelAtIndex(index: Int, label: String) {
    self.todoList[index].label = label
    table.upsert([TodoItemToRow(self.todoList[index])])
  }
  
  func switchCheckedAtIndex(index: Int) {
    self.todoList[index].checked = !self.todoList[index].checked
    table.upsert([TodoItemToRow(self.todoList[index])])
  }
  
  internal func count() -> Int {
    return self.todoList.count
  }
  
  internal func swapTodoItems(index1: Int, index2: Int) {
    let item1 = todoList[index1]
    let item2 = todoList[index2]
    todoList[index1] = TodoItem(id: item1.id, label: item2.label, checked: item2.checked)
    todoList[index2] = TodoItem(id: item2.id, label: item1.label, checked: item1.checked)
    table.upsert([TodoItemToRow(todoList[index1]),TodoItemToRow(todoList[index2])])
    
  }
  
}