[![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20Mac%20|%20tvOS%20|%20Linux-lightgray.svg)]()
[![Swift 5.5](https://img.shields.io/badge/swift-5.5-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@simonwhitty-blue.svg)](http://twitter.com/simonwhitty)

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Credits](#credits)

# Introduction

**@Awaiting** is an open-source Swift `@propertyWrapper` that waits asynchronously until the value matches a predicate.

# Usage

Any class can declare a property to be `@Awaiting` as follows:

```swift
@Awaiting var isComplete: Bool = false
```

You can then use its [projected value](https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID619) to asynchronously wait until some predicate is met;

```swift
// Suspends until isComplete == true
_ = await $isComplete.first(where: { $0 })
```

### Optionals

When optionals are wrapped you can wait for the first non nil value:

```swift
@Awaiting var name: String?

let name = await $names.first()
```

### Collections

When collections are wrapped you can wait for at least _n_ elements to exist:

```swift
@Awaiting var names = [String]()

let nonEmpty = await $names.first(withAtLeast: 1)
```

# Credits

`@Awaiting` is primarily the work of [Simon Whitty](https://github.com/simonwhitty).
