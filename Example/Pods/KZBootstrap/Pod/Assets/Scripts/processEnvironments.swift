#!/usr/bin/xcrun swift
// Playground - noun: a place where people can play

import Foundation

let envKey = "KZBEnvironments"
let overrideKey = "KZBEnvOverride"

func validateEnvSettings(envSettings: NSDictionary?, prependMessage: NSString? = nil) -> Bool {
  if envSettings == nil {
    return false
  }
  
  var settings = envSettings!.mutableCopy() as NSMutableDictionary
  let allowedEnvs = settings[envKey] as [String]
  
  settings.removeObjectForKey(envKey)
  
  var missingOptions = [String : [String]]()
  
  for (name, values) in settings {
    let variable = name as String
    let envValues = values as [String: AnyObject]
    
    let notConfiguredOptions = allowedEnvs.filter {
      return envValues.indexForKey($0) == nil
    }
    
    if notConfiguredOptions.count > 0 {
      missingOptions[variable] = notConfiguredOptions
    }
  }
  
  for (variable, options) in missingOptions {
    if let prepend = prependMessage {
      println("\(prepend) error:\(variable) is missing values for '\(options)'")
    } else {
      println("error:\(variable) is missing values for '\(options)'")
    }
  }
  
  return missingOptions.count == 0
}

func filterEnvSettings(entries: NSDictionary, forEnv env: String, prependMessage: String? = nil) -> NSDictionary {
  var settings = entries.mutableCopy() as [String:AnyObject]
  settings[envKey] = [env]
  for (name, values) in entries {
    let variable = name as String
    if let envValues = values as? [String: AnyObject] {
      if let allowedValue: AnyObject = envValues[env] {
        settings[variable] = [env: allowedValue]
      } else {
        if let prepend = prependMessage {
          println("\(prepend) missing value of variable \(name) for env \(env) available values \(values)")
        } else {
          println("missing value of variable \(name) for env \(env) available values \(values)")
        }
      }
    }
  }
  
  return settings
}


func processSettings(var settingsPath: String, availableEnvs:[String], allowedEnv: String? = nil) -> Bool {
  let preferenceKey = "PreferenceSpecifiers"
  settingsPath = (settingsPath as NSString).stringByAppendingPathComponent("Root.plist") as String

  if var settings = NSMutableDictionary(contentsOfFile: settingsPath) {
    if var existing = settings[preferenceKey] as? [AnyObject] {
      existing = existing.filter {
        if let dictionary = $0 as? [String:AnyObject] {
          let value = dictionary["Key"] as? String
          if value == overrideKey {
            return false
          }
        }
        return true
      }
      
      //! only add env switch if there isnt allowedEnv override
      var updatedPreferences = (existing as NSArray).mutableCopy() as NSMutableArray
      if allowedEnv == nil {
        updatedPreferences.addObject(
          [ "Type" : "PSMultiValueSpecifier",
            "Title" : "Environment",
            "Key" : overrideKey,
            "Titles" : availableEnvs,
            "Values" : availableEnvs,
            "DefaultValue" : ""
          ])
        }
      settings[preferenceKey] = updatedPreferences
      println("Updating settings at \(settingsPath)")
      return settings.writeToFile(settingsPath, atomically: true)
    }
  }
  return false
}

func processEnvs(bundledPath: String, #sourcePath: String, #settingsPath: String, allowedEnv: String? = nil, dstPath: String? = nil) -> Bool {
  let settings = NSDictionary(contentsOfFile: bundledPath)
  let availableEnvs = (settings as [String:AnyObject])[envKey] as [String]

  if validateEnvSettings(settings, prependMessage: "\(sourcePath):1:") {
    if let filterEnv = allowedEnv {
      let productionSettings = filterEnvSettings(settings!, forEnv: filterEnv, prependMessage: "\(sourcePath):1:")
      
      productionSettings.writeToFile(dstPath ?? bundledPath, atomically: true)
    }

    let settingsAdjusted = processSettings(settingsPath, availableEnvs, allowedEnv: allowedEnv)
    if settingsAdjusted == false {
      println("\(__FILE__):\(__LINE__): Unable to adjust settings bundle")
    }
    return settingsAdjusted
  }
  
  return false
}

let count = Process.arguments.count
if count == 1 || count > 5 {
  println("\(__FILE__):\(__LINE__): Received \(count) arguments, Proper usage: processEnvironments.swift -- [bundledPath] [srcPath] [settingsPath] [allowedEnv]")
  exit(1)
}

let path = Process.arguments[1]
let srcPath = Process.arguments[2]
let settingsPath = Process.arguments[3]
let allowedEnv: String? = (count != 5 ? nil : Process.arguments[4])

exit(processEnvs(path, sourcePath: srcPath, settingsPath: settingsPath, allowedEnv:allowedEnv) == true ? 0 : 1)
