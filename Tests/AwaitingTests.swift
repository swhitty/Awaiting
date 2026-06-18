//
//  AwaitingTests.swift
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

@testable import Awaiting
import Testing

struct AwaitingTests {

    @Test
    func wrappedValueUpdates() {
        let mock = Mock("")
        mock.property = "Shrimp"
        #expect(mock.property == "Shrimp")
    }

    @Test
    func initializesWithValue() async throws {
        // given
        let mock = Mock<Int?>(10)

        // when
        let value = try await mock.$property.some()

        // then
        #expect(value == 10)
    }

    @Test
    func lateTask_ReceivesTheWrappedValue() async throws  {
        // given
        let mock = Mock<String?>("Fish")
        mock.property = "Chips"

        // when
        let value = try await mock.$property.some()

        // then
        #expect(value == "Chips")
    }

    @Test
    func multipleTasks_ReceiveTheWrappedValue() async throws {
        // given
        let mock = Mock<String?>(nil)

        async let value1 = mock.$property.some()
        async let value2 = mock.$property.some()
        async let value3 = mock.$property.some()
        await mock.waitUntilWaiting(count: 3)

        // when
        Task { mock.property = "Chips" }

        // then
        #expect(try await value1 == "Chips")
        #expect(try await value2 == "Chips")
        #expect(try await value3 == "Chips")
    }

    @Test
    func waitersAreRemoved_WhenComplete() async throws  {
        // given
        let mock = Mock<String?>(nil)
        async let value1 = mock.$property.some()
        await mock.waitUntilWaiting()

        // when
        mock.property = "Chips"
        _ = try await value1

        // then
        #expect(mock.isWaitingEmpty)
    }

    @Test
    func nil_MakesTaskWait() async throws {
        // given
        let mock = Mock<String?>("Fish")
        mock.property = "Fish"
        mock.property = nil
        async let value1 = mock.$property.some()
        await mock.waitUntilWaiting()

        // when
        mock.property = "Chips"

        // then
        #expect(try await value1 == "Chips")
    }

    @Test
    func cancellingTask_ThrowsCancellationError() async {
        // given
        let mock = Mock<String?>(nil)
        let task = Task<String, any Error> {
            try await mock.$property.some()
        }
        await mock.waitUntilWaiting()

        // when
        task.cancel()

        // then
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }

    @Test
    func collectionWaiter_WaitsForMinimumElements() async throws  {
        let mock = Mock("")
        async let value = mock.$property.first(withAtLeast: 5)
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property = "Fish"
            mock.property = "Kracken"
            mock.property = "Chips"
        }

        // then
        #expect(try await value == "Kracken")
    }

    @Test
    func optionalWaiter_WaitsForPredicate() async throws  {
        let mock = Mock<Int?>(nil)
        async let value = mock.$property.some(where: { $0 > 5 })
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property = 3
            mock.property = nil
            mock.property = 10
        }

        // then
        #expect(try await value == 10)
    }

    @Test
    func firstWhere_AllowsPredicateToReenterWrappedValue() async throws {
        let mock = Mock(0)
        async let value = mock.$property.first { value in
            _ = mock.property
            return value == 1
        }
        await mock.waitUntilWaiting()

        // when
        Task { mock.property = 1 }

        // then
        #expect(try await value == 1)
    }

    @Test
    func collectionWaiter_WaitsForValueAtIndex() async throws  {
        let mock = Mock(Array<Int>())
        async let value = mock.$property.value(at: 2)
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property.append(10)
            mock.property.append(20)
            mock.property.append(30)
        }

        // then
        #expect(try await value == 30)
    }

    @Test
    func collectionWaiter_WaitsForElementAtIndex() async throws  {
        let mock = Mock(Array<Int>())
        async let value = mock.$property.element(at: 2)
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property.append(10)
            mock.property.append(20)
            mock.property.append(30)
        }

        // then
        #expect(try await value == 30)
    }

    @Test
    func collectionWaiter_WaitsForElementThatMatchesPredicate() async throws  {
        let mock = Mock(Array<Int>())
        async let value = mock.$property.element(where: { $0.isMultiple(of: 7) })
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property.append(10)
            mock.property.append(20)
            mock.property.append(21)
        }

        // then
        #expect(try await value == 21)
    }

    @Test
    func equatableWaiter_WaitsForElement() async throws  {
        let mock = Mock(0)
        async let value = mock.$property.equals(30)
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property = 10
            mock.property = 20
            mock.property = 30
        }

        // then
        #expect(try await value == 30)
    }

    @Test
    func equatableWaiter_WaitsForOptionalElement() async throws  {
        let mock = Mock(Optional<String>.none)
        async let value = mock.$property.equals("Fish")
        await mock.waitUntilWaiting()

        // when
        Task {
            mock.property = "chips"
            mock.property = "fish"
            mock.property = "Fish"
        }

        // then
        #expect(try await value == "Fish")
    }

    @Test
    func modify_TriggersWaiter() async throws {
        // given
        let mock = Mock<Int?>(nil)
        async let value = mock.$property.some()
        await mock.waitUntilWaiting()

        // when
        mock.modify { $0 = 200 }

        // then
        #expect(try await value == 200)
    }
}

final class Mock<T: Sendable>: @unchecked Sendable {
    @Awaiting var property: T

    init(_ initial: T) {
        self.property = initial
    }

    var isWaitingEmpty: Bool {
        _property.isWaitingEmpty
    }

    var waitingCount: Int {
        _property.waitingCount
    }

    func waitUntilWaiting(count: Int = 1) async {
        while waitingCount < count {
            await Task.yield()
        }
    }

    @discardableResult
    func modify<U>(_ transform: (inout T) throws -> U) rethrows -> U {
        try _property.modify(transform)
    }
}
