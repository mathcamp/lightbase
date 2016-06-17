//
//  Entity.swift
//  Roll
//
//  Created by Highlight on 8/18/15.
//  Copyright (c) 2015 Mathcamp. All rights reserved.
//

import Foundation
import BrightFutures

public class Entity {
  let fields: NSDictionary
  
  public required init(obj: AnyObject?) {
    var f = NSMutableDictionary()
    if let obj: AnyObject = obj {
      if let fields = obj as? NSMutableDictionary {
        f = fields
      } else if let json = obj as? String {
        if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
          do {
            let jsonObject: NSMutableDictionary = try NSJSONSerialization.JSONObjectWithData(detailsData, options: []) as! NSMutableDictionary
            f = jsonObject
          } catch _ {
            // do nothing
          }
        }
      }
    }
    self.fields = NSDictionary(dictionary: f)
  }
  
  public required init(fields: NSDictionary = [:]) {
    self.fields = fields
  }
  
  public func toFields() -> NSMutableDictionary {
    // override this in subclass
    return [:]
  }
  
  public func rawString() -> String? {
    guard let data = data() else { return nil }
    return String(data: data, encoding: NSUTF8StringEncoding)
  }
  
  public func data() -> NSData? {
    return toJSON().dataUsingEncoding(NSUTF8StringEncoding)
  }
  
  public func md5() -> String {
    guard let data = data() else { return "FAIL" }
    
    let digestLength = Int(CC_MD5_DIGEST_LENGTH)
    let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
    
    CC_MD5(data.bytes, CC_LONG(data.length), md5Buffer)
    let output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
    for i in 0..<digestLength {
      output.appendFormat("%02x", md5Buffer[i])
    }
    return NSString(format: output) as String
  }
  
  public func toRowFields() -> NSMutableDictionary? {
    return nil
  }
  
  public func toRow() -> HLDB.Table.Row {
    if let fields = toRowFields() {
      return HLDB.Table.Row(fields: fields)
    }
    return HLDB.Table.Row(fields: toFields())
  }
  
  public func toJSON() -> String {
    return serializeToJSON(toFields())
  }
  
  func serializeToJSON(obj: AnyObject) -> String {
    do {
      let data = try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions(rawValue: 0))
      if let s = NSString(data: data, encoding: NSUTF8StringEncoding) {
        return s as String
      }
    } catch _ {
      // do nothing
    }
    return ""
  }
  
  func deserializeFromJSON(json: String) -> AnyObject? {
    if let detailsData = (json as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
      do {
        let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(detailsData, options: NSJSONReadingOptions.AllowFragments)
        return jsonObject
      } catch _ {
        // do nothing
      }
    }
    print("Entity: Failed to parse JSON '\(json)'!!")
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
  
  public func boolValue(fieldName: String, defaultValue: Bool = false) -> Bool {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Bool {
      outValue = v
    } else if let v = fields[fieldName] as? String {
      if v == "true" { outValue = true }
      else if v == "1" { outValue = true }
      else { outValue = false }
    }
    return outValue
  }
  
  public func intValue(fieldName: String, defaultValue: Int = 0) -> Int {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Int {
      outValue = v
    }
    return outValue
  }
  
  public func floatValue(fieldName: String, defaultValue: Float = 0) -> Float {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Float {
      outValue = v
    }
    return outValue
  }
  
  public func doubleValue(fieldName: String, defaultValue: Double = 0) -> Double {
    var outValue = defaultValue
    if let v = fields[fieldName] as? Double {
      outValue = v
    }
    return outValue
  }
  
  public func stringValue(fieldName: String, defaultValue: String = "") -> String {
    var outValue = defaultValue
    if let v = fields[fieldName] as? String {
      outValue = v
    }
    return outValue
  }
  
  public func nsdataValue(fieldName: String, defaultValue: NSData = NSData()) -> NSData {
    var outValue = defaultValue
    if let v = fields[fieldName] as? String {
      outValue = NSData(base64EncodedString: v, options: [])!
    }
    
    if let v = fields[fieldName] as? NSData {
      outValue = v
    }
    return outValue
  }
  
  public func arrayValue(fieldName: String, defaultValue: [AnyObject] = []) -> [AnyObject] {
    var outValue = defaultValue
    // if this is a string then decode json
    if let _ = fields[fieldName] as? String {
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
  
  public func dictValue(fieldName: String, defaultValue: NSMutableDictionary = [:]) -> NSMutableDictionary {
    var outValue = defaultValue
    // if this is a string then decode json
    if let _ = fields[fieldName] as? String {
      if let dict = deserializeJSONFieldAsDictionary(fieldName) {
        return dict
      }
    }
    // if it's a dictionary, then just return the dict
    if let v = fields[fieldName] as? NSMutableDictionary {
      outValue = v
    }
    else if let v = fields[fieldName] as? NSDictionary {
      outValue = NSMutableDictionary(dictionary: v)
    }
    return outValue
  }
}