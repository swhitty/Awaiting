//
//  Awaiting.swift
//  Awaiting
//
//  Created by Simon Whitty on 26/01/2022.
//  Copyright © 2022 Simon Whitty. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/Awaiting
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// @Awaiting wraps properties and projects `Waiter` that can wait
/// until a condition is met, then returns the value.
///
/// Throws when CancellationError() when task is cancelled
///
/// ```
///  @Awaiting var name: String?
///  let name = try await $name.first() // waits for first non nil value
///
///  @Awaiting var names: [String]
///  let name = try await $names.first(withAtLeast: 5) // waits until array contains at least 5 elements
///
///  @Awaiting var age: Int?
///  let name = try await $age.first(where: { $0 > 92 }) // waits until age > 92
///  ```
@propertyWrapper
public final class Awaiting<Element: Sendable>: @unchecked Sendable {

    public init(wrappedValue: Element) {
        self.mutex = .init(State(storage: wrappedValue))
    }

    public var projectedValue: Waiter {
        Waiter(getter: firstElement)
    }

    public struct Waiter: Sendable {
        fileprivate let getter: @Sendable (@escaping @Sendable (Element) -> Bool) async throws -> Element

        /// Retrieves first`wrappedValue` that matches the supplied predicate.
        ///
        /// - Parameter predicate: A closure that takes `wrappedValue` as its argument and returns a
        ///   Boolean value indicating whether the element is a match.
        /// - Returns: The `wrappedValue` when it passes the predicate.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        public func first(where predicate: @escaping @Sendable (Element) -> Bool) async throws -> Element {
            try await getter(predicate)
        }

        /// Retrieves first`wrappedValue` that contains >= the requested number of elements.
        ///
        /// - Parameter minCount: The minimum number of elements the collection must contain before the predicate is met.
        /// - Returns: The collection when `count >= minCount`
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        ///
        public func first(withAtLeast minCount: Int) async throws -> Element where Element: Collection {
            try await first { $0.count >= minCount }
        }

        /// Retrieves element from`wrappedValue` at the suppplied index.
        ///
        /// - Parameter index: The index within `wrappedValue` that must exist before the preficate is met.
        /// - Returns: The element within the collection at the supplied index.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        ///
        @available(*, deprecated, renamed: "element(at:)")
        public func value(at index: Element.Index) async throws -> Element.Element where Element: Collection, Element.Index: Sendable {
            try await element(at: index)
        }

        /// Retrieves element from`wrappedValue` at the suppplied index.
        ///
        /// - Parameter index: The index within `wrappedValue` that must exist before the preficate is met.
        /// - Returns: The element within the collection at the supplied index.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        ///
        public func element(at index: Element.Index) async throws -> Element.Element where Element: Collection, Element.Index: Sendable {
            let collection = try await first { $0.indices.contains(index) }
            return collection[index]
        }

        /// Retrieves element from`wrappedValue` that matches the suppplied predicate.
        ///
        /// - Parameter predicate: A closure that takes the element of `wrappedValue`  as its argument and returns a
        ///   Boolean value indicating whether the element is a match.
        /// - Returns: The  first element of`wrappedValue` that passes the predicate.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        ///
        public func element(where predicate: @escaping @Sendable (Element.Element) -> Bool) async throws -> Element.Element where Element: Collection, Element.Index: Sendable {
            let collection = try await first { $0.contains(where: predicate) }
            return collection.first(where: predicate)!
        }

        /// Retrieves and unwraps first`wrappedValue` that is not `nil`.
        ///
        /// - Returns: An unwrapped element when != nil
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        public func some<T>() async throws -> T where Element == Optional<T> {
            try await first { $0 != nil }!
        }

        /// Retrieves first`wrappedValue` that is not nil and matches the supplied predicate.
        ///
        /// - Parameter predicate: A closure that takes `wrappedValue` as its argument and returns a
        ///   Boolean value indicating whether the element is a match.
        /// - Returns: The `wrappedValue` when it passes the predicate.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        public func some<T>(where predicate: @escaping @Sendable (T) -> Bool) async throws -> T where Element == Optional<T> {
            try await first {
                $0 != nil && predicate($0!)
            }!
        }

        /// Waits until first`wrappedValue` equals the supplied element
        ///
        /// - Parameter element: The element to wait for.
        /// - Returns: The `wrappedValue` that equals the supplied element.
        ///
        /// - Throws: `CancellationError` if the task is cancelled.
        @discardableResult
        public func equals(_ element: Element) async throws -> Element where Element: Equatable {
            try await first { $0 == element }
        }
    }

    @available(*, unavailable, message: "@Awaiting can only be applied to classes")
    public var wrappedValue: Element {
        get { fatalError() }
        set { fatalError() }
    }

    // Classes get and set `wrappedValue` using this subscript.
    public static subscript<T>(_enclosingInstance instance: T,
                               wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Element>,
                               storage storageKeyPath: ReferenceWritableKeyPath<T, Awaiting>) -> Element {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            instance[keyPath: storageKeyPath].storage = newValue
        }
    }

    /// Acquires lock and executes transformation closure on element.
    /// - Parameter transform: Closure is performed when lock is acquired. `element` can be mutated
    /// - Returns: Forwards returned value from transform closure
    @discardableResult
    public func modify<U>(_ transform: (inout Element) throws -> U) rethrows -> U {
        try mutex.withLock { state in
            let result = try transform(&state.storage)
            for waiter in state.waiting {
                waiter.resumeIfPossible(with: state.storage)
            }
            return result
        }
    }

    private let mutex: Mutex<State>

    private struct State {
        var storage: Element
        var waiting: Set<Continuation> = []
    }

    private var storage: Element {
        get {
            modify{ $0 }
        }
        set {
            modify{ $0 = newValue }
        }
    }

    private func firstValue(where predicate: @escaping @Sendable (Element) -> Bool) -> Value {
        mutex.withLock { state in
            if predicate(state.storage) {
                return .element(state.storage)
            } else {
                let continuation = Continuation(predicate: predicate)
                state.waiting.insert(continuation)
                return .continuation(continuation)
            }
        }
    }

    @Sendable
    private func firstElement(where predicate: @escaping @Sendable (Element) -> Bool) async throws -> Element {
        switch firstValue(where: predicate) {
        case let .element(value):
            return value
        case let .continuation(continuation):
            defer {
                mutex.withLock {
                    _ = $0.waiting.remove(continuation)
                }
            }

            return try await withTaskCancellationHandler(
                operation: continuation.getValue,
                onCancel: { continuation.cancel() }
            )
        }
    }

    private enum Value {
        case element(Element)
        case continuation(Continuation)
    }

    private final class Continuation: Hashable, @unchecked Sendable {
        private let predicate: @Sendable (Element) -> Bool
        private let state = Mutex<State?>(nil)

        private enum State {
            case continuation(CheckedContinuation<Element, any Error>)
            case result(Result<Element, any Error>)
        }

        init(predicate: @escaping @Sendable (Element) -> Bool) {
            self.predicate = predicate
        }

        func getValue() async throws -> Element {
            try await withCheckedThrowingContinuation { continuation in
                let result: Result<Element, any Error>? = state.withLock {
                    switch $0 {
                    case .result(let result):
                        return result
                    case .continuation:
                        preconditionFailure("cannot continue multiple times")
                    case .none:
                        $0 = .continuation(continuation)
                    }
                    return nil
                }
                if let result {
                    continuation.resume(with: result)
                }
            }
        }

        func resumeIfPossible(with value: Element) {
            if predicate(value) {
                resume(with: .success(value))
            }
        }

        func cancel() {
            resume(with: .failure(CancellationError()))
        }

        private func resume(with result: Result<Element, any Error>) {
            let continuation: CheckedContinuation<Element, any Error>? = state.withLock {
                switch $0 {
                case .result:
                    // already resumed
                    return nil
                case .continuation(let c):
                    $0 = .result(result)
                    return c
                case .none:
                    $0 = .result(result)
                    return nil
                }
            }
            if let continuation {
                continuation.resume(with: result)
            }
        }

        func hash(into hasher: inout Hasher) {
            ObjectIdentifier(self).hash(into: &hasher)
        }

        static func == (lhs: Awaiting<Element>.Continuation, rhs: Awaiting<Element>.Continuation) -> Bool {
            lhs === rhs
        }
    }
}

extension Awaiting {
    var isWaitingEmpty: Bool {
        mutex.withLock { $0.waiting.isEmpty }
    }
}
