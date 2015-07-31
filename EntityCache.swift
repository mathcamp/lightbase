//
//  EntityCache.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

class EntityCache<T> {
  enum Status {
    case Cached(NSTimeInterval)
    case Unknown
  }
  
  var map: [String: Entity] = [:]
  let table: Table
  
  init(table: Table) {
    self.table = table
  }
  
  func erase() {
    map = [:]
  }
  
  func removeKeys(keys: [String]) {
    keys.map { self.map.removeValueForKey($0) }
  }
  
  func primaryKey() -> String? {
    let primaryKey = table.primaryKey
    if let field = table.definition[primaryKey] {
      // we only support String primary keys right now
      if field.type != .Text { return nil }
      return primaryKey
    }
    return nil
  }
  
  func remove(entities: [Entity]) {
    if let primaryKey = primaryKey() {
      var keys: [String] = []
      for entity in entities {
        if let primaryKeyValue = entity.fields[primaryKey] as? String {
          keys.append(primaryKeyValue)
        }
      }
      removeKeys(keys)
    }
  }
  
  func store(entities: [Entity]) {
    if let primaryKey = primaryKey() {
      let updateTime = NSDate().timeIntervalSince1970
      for entity in entities {
        if let primaryKeyValue = entity.fields[primaryKey] as? String {
          entity.cacheStatus = .Cached(updateTime)
          map[primaryKeyValue] = entity
        }
      }
    }
  }
  
  func find(keys: [String]) -> [Entity] {
    var entities: [Entity] = []
    if map.count == 0 { return entities }
    for key in keys {
      if let foundEntity = self.map[key] {
        entities.append(foundEntity)
      }
    }
    return entities
  }
  
  func findAsMap(keys: [String]) -> [String: Entity] {
    var entities: [Entity] = find(keys)
    var entityMap: [String: Entity] = [:]
    if let primaryKey = primaryKey() {
      for entity in entities {
        if let primaryKeyValue = entity.fields[primaryKey] as? String {
          entityMap[primaryKeyValue] = entity
        }
      }
    }
    return entityMap
  }
}
