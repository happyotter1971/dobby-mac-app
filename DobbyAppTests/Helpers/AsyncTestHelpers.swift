import XCTest
import Foundation
@testable import Dobby

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
    case timeout
    case unexpectedValue
    case conditionNotMet

    var errorDescription: String? {
        switch self {
        case .timeout: return "Test timeout exceeded"
        case .unexpectedValue: return "Unexpected value encountered"
        case .conditionNotMet: return "Expected condition was not met"
        }
    }
}

// MARK: - Async Waiting Helpers

/// Wait for a condition to become true with timeout
func waitUntil(
    timeout: TimeInterval = 2.0,
    pollInterval: TimeInterval = 0.05,
    file: StaticString = #file,
    line: UInt = #line,
    condition: @escaping () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if condition() {
            return
        }
        try await _Concurrency.Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }

    XCTFail("Timeout waiting for condition", file: file, line: line)
    throw TestError.timeout
}

/// Wait for a value to change from its initial value
func waitForChange<T: Equatable>(
    timeout: TimeInterval = 2.0,
    pollInterval: TimeInterval = 0.05,
    file: StaticString = #file,
    line: UInt = #line,
    getValue: @escaping () -> T
) async throws -> T {
    let initial = getValue()
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        let current = getValue()
        if current != initial {
            return current
        }
        try await _Concurrency.Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }

    XCTFail("Timeout waiting for value change from \(initial)", file: file, line: line)
    throw TestError.timeout
}

/// Wait for a value to equal an expected value
func waitForValue<T: Equatable>(
    _ expected: T,
    timeout: TimeInterval = 2.0,
    pollInterval: TimeInterval = 0.05,
    file: StaticString = #file,
    line: UInt = #line,
    getValue: @escaping () -> T
) async throws {
    let deadline = Date().addingTimeInterval(timeout)

    while Date() < deadline {
        if getValue() == expected {
            return
        }
        try await _Concurrency.Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }

    let actual = getValue()
    XCTFail("Timeout waiting for value. Expected: \(expected), Actual: \(actual)", file: file, line: line)
    throw TestError.timeout
}

// MARK: - XCTest Extension

extension XCTestCase {
    /// Wait for an async expectation with custom timeout
    func waitForAsync(
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: "Async operation")

        _Concurrency.Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)", file: file, line: line)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    /// Create an expectation that fulfills when a callback is invoked
    func expectCallback(
        description: String = "Callback",
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: (@escaping () -> Void) -> Void
    ) {
        let expectation = expectation(description: description)

        operation {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Main Thread Helpers

/// Execute a block on the main thread and wait for completion
func onMainThread<T>(_ block: @escaping () -> T) async -> T {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume(returning: block())
        }
    }
}

/// Execute a block on the main thread after a delay
func onMainThreadAfterDelay(_ delay: TimeInterval, _ block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

// MARK: - Observation Helpers

/// Track calls to a closure
class CallTracker<T> {
    private(set) var calls: [T] = []
    private let lock = NSLock()

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return calls.count
    }

    var lastCall: T? {
        lock.lock()
        defer { lock.unlock() }
        return calls.last
    }

    var wasCalled: Bool {
        callCount > 0
    }

    func track(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        calls.append(value)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        calls.removeAll()
    }
}

/// Void call tracker
typealias VoidCallTracker = CallTracker<Void>

extension CallTracker where T == Void {
    func track() {
        track(())
    }
}
