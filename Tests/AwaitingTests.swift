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
import XCTest

final class AwaitingTests: XCTestCase {

  func testWrappedValueUpdates() {
    let mock = Mock("")
    mock.property = "Shrimp"
    XCTAssertEqual(mock.property, "Shrimp")
  }

  func testInitializesWithValue() async throws {
    // given
    let mock = Mock<Int?>(10)

    // when
    let value = try await mock.$property.some()

    // then
    XCTAssertEqual(value, 10)
  }

  func testLateTask_ReceivesTheWrappedValue() async throws  {
    // given
    let mock = Mock<String?>("Fish")
    mock.property = "Chips"

    // when
    let value = try await mock.$property.some()

    // then
    XCTAssertEqual(value, "Chips")
  }

  func testMultipleTasks_ReceiveTheWrappedValue() async throws {
    // given
    let mock = Mock<String?>(nil)

    async let value1 = mock.$property.some()
    async let value2 = mock.$property.some()
    async let value3 = mock.$property.some()

    // when
    Task { mock.property = "Chips" }

    // then
    let v1 = try await value1
    XCTAssertEqual(v1, "Chips")

    let v2 = try await value2
    XCTAssertEqual(v2, "Chips")

    let v3 = try await value3
    XCTAssertEqual(v3, "Chips")
  }

  func testWaitersAreRemoved_WhenComplete() async throws  {
    // given
    let mock = Mock<String?>(nil)
    async let value1 = mock.$property.some()

    // when
    mock.property = "Chips"
    _ = try await value1

    // then
    XCTAssertTrue(mock.isWaitingEmpty)
  }

  func testNil_MakesTaskWait() async throws {
    // given
    let mock = Mock<String?>("Fish")
    mock.property = "Fish"
    mock.property = nil
    async let value1 = mock.$property.some()

    // when
    mock.property = "Chips"

    // then
    let v1 = try await value1
    XCTAssertEqual(v1, "Chips")
  }

  func testCancellingTask_ThrowsCancellationError() async {
    // given
    let mock = Mock<String?>(nil)
    let task = Task<String, Error> {
      try await mock.$property.some()
    }

    // when
    task.cancel()

    // then
    do {
      _ = try await task.value
      XCTFail("Expected Error")
    } catch {
      XCTAssertTrue(error is CancellationError)
    }
  }

  func testCollectionWaiter_WaitsForMinimumElements() async throws  {
    let mock = Mock("")
    async let value = mock.$property.first(withAtLeast: 5)

    // when
    Task {
      mock.property = "Fish"
      mock.property = "Kracken"
      mock.property = "Chips"
    }

    // then
    let v1 = try await value
    XCTAssertEqual(v1, "Kracken")
  }

  func testOptionalWaiter_WaitsForPredicate() async throws  {
      let mock = Mock<Int?>(nil)
      async let value = mock.$property.some(where: { $0 > 5 })

      // when
      Task {
        mock.property = 3
        mock.property = nil
        mock.property = 10
      }

      // then
      let v1 = try await value
      XCTAssertEqual(v1, 10)
  }
}

final class Mock<T>: @unchecked Sendable {
  @Awaiting var property: T

  init(_ initial: T) {
    self.property = initial
  }

  var isWaitingEmpty: Bool {
    _property.isWaitingEmpty
  }
}
