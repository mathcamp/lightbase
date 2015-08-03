# hldb

## Work in progress

[![CircleCI build status badge](https://img.shields.io/circleci/project/mathcamp/hldb/master.svg)](https://circleci.com/gh/mathcamp/hldb) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods version](https://img.shields.io/cocoapods/v/hldb.svg)](https://cocoapods.org/pods/hldb) [![MIT License](https://img.shields.io/cocoapods/l/hldb.svg)](LICENSE) ![Platform iOS](https://img.shields.io/cocoapods/p/hldb.svg)

hldb is a swifty wrapper ontop of FMDB, which itself is an Objective-C wrapper on top of sqlite.
hldb makes extensive use of reactive programming paradigms like [Promises or futures](https://github.com/Thomvis/BrightFutures).
// Other things? more rationale @benagarr??

## Installation

#### Pods

`pod 'hldb'`

#### Carthage

`github "mathcamp/hldb"`

## Usage Example

### Playground
To get the program to recognize and import the `hldb.framework`, you first need to build the framework itself. To do this
1. Open `hldb.xcworkspace`
2. Select `hldb-iOS` framework as your scheme and build on a device. (this builds the framework)
3. After this you should be able to use `hldb.playground` freely 😄

### Example project
@benagarr what do you think? I haven't really done a lot with this
