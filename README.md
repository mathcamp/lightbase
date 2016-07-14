<<<<<<< HEAD
#Lightbase

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods version](https://img.shields.io/cocoapods/v/hldb.svg)](https://cocoapods.org/pods/hldb) [![MIT License](https://img.shields.io/cocoapods/l/hldb.svg)](LICENSE) ![Platform iOS](https://img.shields.io/cocoapods/p/hldb.svg)

Lightbase is a lightweight swifty wrapper for sqlite.

Using Lighbase, you can create, update and delete sqlite tables; you can insert, upsert, update, and delete rows; you can query over the database with all the sqlite filters and accumulators you've come to know and love; and you can verify that everything is saving properly using MD5 hashes. Best of all, you can do it simply and swift-ily!

Lightbase makes extensive use of reactive programming paradigms like [Promises or Futures](https://github.com/Thomvis/BrightFutures).
=======
# hldb [![TravisCI build status badge](https://api.travis-ci.org/mathcamp/hldb.svg)](https://travis-ci.org/mathcamp/hldb) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods version](https://img.shields.io/cocoapods/v/hldb.svg)](https://cocoapods.org/pods/hldb) [![MIT License](https://img.shields.io/cocoapods/l/hldb.svg)](LICENSE) ![Platform iOS](https://img.shields.io/cocoapods/p/hldb.svg)

hldb is a swifty wrapper ontop of FMDB, which itself is an Objective-C wrapper on top of sqlite.
It makes extensive use of reactive programming paradigms like [Promises and Futures](https://github.com/Thomvis/BrightFutures).
>>>>>>> 69e1cc103f67319886d21a2d9f776d1c209a81e6

## Installation

#### Pods

`pod 'hldb'`

#### Carthage

`github "mathcamp/lightbase"`

## Usage Example

### Playground
To get the program to recognize and import the `hldb.framework`, you first need to build the framework itself. To do this

1. Open `hldb.xcworkspace`

2. Select `hldb-iOS` framework as your scheme and build on a device. (this builds the framework)

<<<<<<< HEAD
3. After this you should be able to use `hldb.playground` freely :)

### Example project
Refer to our Example folder in the Lightbase repo for our example app 'Todotastic', a Todo App with a variety of gesture integrations. The example app demonstrates table and row manipulation, and is a great starting point for integrating Lightbase into your own projects!
=======
3. After this you should be able to use `hldb.playground` freely 😄

### Example project
In progress
>>>>>>> 69e1cc103f67319886d21a2d9f776d1c209a81e6
