[![Build](https://github.com/swhitty/Awaiting/actions/workflows/build.yml/badge.svg)](https://github.com/swhitty/Awaiting/actions/workflows/build.yml)
[![Codecov](https://codecov.io/gh/swhitty/Awaiting/graphs/badge.svg)](https://codecov.io/gh/swhitty/Awaiting)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20Mac%20|%20Linux-lightgray.svg)]()
[![Swift 5.5](https://img.shields.io/badge/swift-5.5%20|%205.7-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@simonwhitty-blue.svg)](http://twitter.com/simonwhitty)

# Introduction

**@Awaiting** is a Swift `@propertyWrapper` that waits asynchronously until the value matches a predicate.

# Usage

Any class can declare a property to be `@Awaiting` as follows:

```swift
@Awaiting var isComplete: Bool = false
```

You then use its [projected value](https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID619) to await until some predicate is met;

```swift
// Suspends until isComplete == true
_ = try await $isComplete.first(where: { $0 == true })
```

### Cancellation

[`CancellationError`](https://developer.apple.com/documentation/swift/cancellationerror) is thrown if the task is cancelled before the predicate is met.

### Optionals

When optionals are wrapped you can wait for the first non nil value:

```swift
@Awaiting var name: String?

// Suspends until name != nil
let name = try await $name.some()
```

### Equatables

When equatables are wrapped you can wait for the first value that equals an element:

```swift
@Awaiting var name: String?

// Suspends until name == "Fish"
try await $name.equals("Fish")
```

### Collections
When collections are wrapped you can wait for an element to exist at an index:
```swift
@Awaiting var names = [String]()

// Suspends until names[2] exists
let name = try await $names.element(at: 2)
```

Or wait for an element that matches the predicate:
```swift
// Suspends until a name contains an element that contains 5 or more letters
let name = try await $names.element { $0.count > 5}
```

Or wait for at least _n_ elements to exist:

```swift
// Suspends until names.count >= 3
let nonEmpty = try await $names.first(withAtLeast: 3)
```

# Credits

`@Awaiting` is primarily the work of [Simon Whitty](https://github.com/swhitty).
