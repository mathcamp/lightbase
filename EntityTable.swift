//
//  EntityTable.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

public class EntityTable {
  public let table: Table
  let useCache: Bool
  let cache: EntityCache
  
  public enum Result {
    case Success
    case Entities([Entity])
    case Error(Int, String)
  }
  
  public init(table: Table, useCache: Bool = false) {
    self.table = table
    self.useCache = useCache
    cache = EntityCache(table: self.table)
  }
  
  // override this in your subclass
  func constructEntity(fromFields: NSDictionary) -> Entity {
    return Entity(fields: fromFields)
  }
  
  public func create() { table.create() }
  public func drop() {
    eraseCache()
    table.drop()
  }
  
  public func eraseCache() {
    cache.erase()
  }
  
  public func select(whereStr: String = "") -> Future<Result> {
    let p = Promise<Result>()
    table.select(whereStr: whereStr).onSuccess { result in
      switch result {
      case .Success:
        p.success(.Success)
      case .Items(let items):
        
        if self.useCache {
          // even though we just got these out of the db, if we're using the cache
          // we should pull the Entities from the cache since it will be the most
          // recently updated version
          var outEntities: [Entity] = []
          if let primaryKey = self.cache.primaryKey() {
            var keys: [String] = []
            for item in items {
              if let k = item[primaryKey] as? String {
                keys.append(k)
              }
            }
            
            let cachedEntityMap = self.cache.findAsMap(keys)
            var uncachedRows: [Table.Row] = []
            for item in items {
              if let k = item[primaryKey] as? String {
                if let entity = cachedEntityMap[k] {
                  outEntities.append(entity)
                } else {
                  outEntities.append(self.constructEntity(item))
                }
              }
            }
          }
          p.success(.Entities(outEntities))
        } else {
          let entities = items.map { self.constructEntity($0) }
          p.success(.Entities(entities))
        }
      case .Error(let code, let message):
        p.success(.Error(code, message))
      }
    }
    return p.future
  }
  
  public func delete(keys: [String]) -> Future<Result> {
    let p = Promise<Result>()
    var rows: [Table.Row] = keys.map { Table.Row(fields: [self.table.primaryKey: $0]) }
    
    table.delete(rows).onSuccess { result in
      switch result {
      case .Success:
        if self.useCache {
          // delete these items from the cache
          self.cache.removeKeys(keys)
        }
        p.success(.Success)
      case .Items(let items):
        p.success(.Error(-1, "Expected success rather than "))
      case .Error(let code, let message):
        p.success(.Error(code, message))
      }
    }
    return p.future
  }
  
  func insertAndUpdate(insertRows: [Table.Row], updateRows: [Table.Row]) -> Future<DB.Result> {
    return table.insertAndUpdate(insertRows, updateRows: updateRows)
  }
  
  public func insert(rows: [Table.Row]) -> Future<DB.Result> {
    return table.insert(rows)
  }
  
  public func update(rows: [Table.Row]) -> Future<DB.Result> {
    return table.update(rows)
  }
}
