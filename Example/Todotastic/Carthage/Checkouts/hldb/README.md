# hldb [![TravisCI build status badge](https://api.travis-ci.org/mathcamp/hldb.svg)](https://travis-ci.org/mathcamp/hldb) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CocoaPods version](https://img.shields.io/cocoapods/v/hldb.svg)](https://cocoapods.org/pods/hldb) [![MIT License](https://img.shields.io/cocoapods/l/hldb.svg)](LICENSE) ![Platform iOS](https://img.shields.io/cocoapods/p/hldb.svg)

hldb is a swifty wrapper ontop of FMDB, which itself is an Objective-C wrapper on top of sqlite.
It makes extensive use of reactive programming paradigms like [Promises and Futures](https://github.com/Thomvis/BrightFutures).

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
In progress
