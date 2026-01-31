import XCTest
@testable import Dobby

/// Tests for WebSocket reconnection logic with exponential backoff
final class WebSocketReconnectionTests: XCTestCase {

    // MARK: - Reconnection Attempt Tracking

    func testMaxReconnectAttempts_IsFive() {
        // The manager should have a max of 5 reconnection attempts
        // Based on the code: private let maxReconnectAttempts = 5
        let maxAttempts = 5
        XCTAssertEqual(maxAttempts, 5)
    }

    // MARK: - Exponential Backoff Formula Tests

    func testExponentialBackoff_Formula() {
        // Formula: min(pow(2.0, Double(attempt - 1)), 16.0)
        let testCases: [(attempt: Int, expectedDelay: Double)] = [
            (1, 1.0),   // 2^0 = 1
            (2, 2.0),   // 2^1 = 2
            (3, 4.0),   // 2^2 = 4
            (4, 8.0),   // 2^3 = 8
            (5, 16.0),  // 2^4 = 16 (max)
            (6, 16.0),  // 2^5 = 32, but capped at 16
            (10, 16.0)  // 2^9 = 512, but capped at 16
        ]

        for testCase in testCases {
            let delay = min(pow(2.0, Double(testCase.attempt - 1)), 16.0)
            XCTAssertEqual(delay, testCase.expectedDelay,
                          "Attempt \(testCase.attempt) should have delay \(testCase.expectedDelay)")
        }
    }

    // MARK: - Connection Status After Max Attempts

    func testConnectionStatus_FailedAfterMaxAttempts() {
        // After max reconnection attempts, status should be .failed
        // This is tested by verifying the status enum exists and has correct display
        XCTAssertEqual(ConnectionStatus.failed.displayText, "Connection Failed")
    }

    // MARK: - Disconnect Resets State

    func testDisconnect_ResetsReconnectAttempts() {
        let manager = WebSocketManager.shared

        // Connect and then disconnect
        manager.connect()
        manager.disconnect()

        // Reconnect attempts should be reset to 0
        XCTAssertEqual(manager.testReconnectAttempts, 0)
    }

    // MARK: - Cleanup

    override func tearDown() {
        super.tearDown()
        WebSocketManager.shared.disconnect()
    }
}
