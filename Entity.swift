//
//  Entity.swift
//  HLDB
//
//  Created by Andrew Breckenridge on 7/31/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation

public class Entity<T> {
  let fields: NSDictionary
  var cacheStatus: CacheStatus = .Unknown
  
  public init(obj: AnyObject?) {
    var f = NSMutableDictionary()
    if let obj: AnyObject = obj {
      if let fields = obj as? NSMutableDictionary {
        f = fields
      } else if let json = obj as? String {
        var error: NSError? = nil
        if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
          if let jsonObject: NSMutableDictionary = NSJSONSerialization.JSONObjectWithData(detailsData, options: nil, error:&error) as? NSMutableDictionary {
            f = jsonObject
          }
        }
      }
    }
    self.fields = f
  }
  
  public init(fields: NSDictionary = [:]) {
    self.fields = fields
  }
  
  public func originalFields() -> NSDictionary {
    return fields
  }
  
  public func toFields() -> NSMutableDictionary {
    // override this in subclass
    return [:]
  }
  
  public func toJSON() -> String {
    return serializeToJSON(toFields())
  }
  
  func serializeToJSON(obj: AnyObject) -> String {
    var error: NSError? = nil
    if let data = NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(0), error: &error) {
      if let s = NSString(data: data, encoding: NSUTF8StringEncoding) {
        return s as String
      }
    }
    return ""
  }
  
  func deserializeFromJSON(json: String) -> AnyObject? {
    var error: NSError? = nil
    if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
      if let jsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(detailsData, options: nil, error:&error) {
        return jsonObject
      }
    }
    return nil
  }
  
  func deserializeJSONFieldAsArray(fieldName: String) -> [AnyObject]? {
    if let dict = deserializeJSONField(fieldName) as? [AnyObject] {
      return dict
    }
    return nil
  }
  
  func deserializeJSONFieldAsDictionary(fieldName: String) -> NSMutableDictionary? {
    if let dict = deserializeJSONField(fieldName) as? NSMutableDictionary {
      return dict
    }
    return nil
  }
  
  func deserializeJSONField(fieldName: String) -> AnyObject? {
    if let json = fields[fieldName] as? String {
      return deserializeFromJSON(json)
    }
    return nil
  }
  
  func value(fieldName: String) -> AnyObject? {
    return fields[fieldName]
  }
  
  func boolValue(fieldName: String, defaultValue: Bool = false) -> Bool {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Bool {
      outValue = v
    }
    return outValue
  }
  
  func intValue(fieldName: String, defaultValue: Int = 0) -> Int {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Int {
      outValue = v
    }
    return outValue
  }
  
  func floatValue(fieldName: String, defaultValue: Float = 0) -> Float {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Float {
      outValue = v
    }
    return outValue
  }
  
  func doubleValue(fieldName: String, defaultValue: Double = 0) -> Double {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Double {
      outValue = v
    }
    return outValue
  }
  
  func stringValue(fieldName: String, defaultValue: String = "") -> String {
    var outValue = defaultValue
    if let v = fields[fieldName] as? String {
      outValue = v
    }
    return outValue
  }
  
  func arrayValue(fieldName: String, defaultValue: [AnyObject] = []) -> [AnyObject] {
    var outValue = defaultValue
    // if this is a string then decode json
    if let v = fields[fieldName] as? String {
      if let array = deserializeJSONFieldAsArray(fieldName) {
        return array
      }
    }
    // if it's a dictionary, then just return the dict
    if let v = fields[fieldName] as? [AnyObject] {
      outValue = v
    }
    return outValue
  }
  
  func dictValue(fieldName: String, defaultValue: NSMutableDictionary = [:]) -> NSMutableDictionary {
    var outValue = defaultValue
    // if this is a string then decode json
    if let v = fields[fieldName] as? String {
      if let dict = deserializeJSONFieldAsDictionary(fieldName) {
        return dict
      }
    }
    // if it's a dictionary, then just return the dict
    if let v = fields[fieldName] as? NSMutableDictionary {
      outValue = v
    }
    return outValue
  }
}