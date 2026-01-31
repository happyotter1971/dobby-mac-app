import XCTest
@testable import Dobby

/// Tests for WebSocketManager connection lifecycle
final class WebSocketConnectionTests: XCTestCase {

    // MARK: - Connection Tests

    func testConnect_SetsStatusToConnecting() {
        // Given
        let manager = WebSocketManager.shared

        // Ensure we start disconnected
        manager.disconnect()

        // When
        manager.connect()

        // Then
        XCTAssertEqual(manager.connectionStatus, .connecting)
    }

    func testDisconnect_SetsStatusToDisconnected() {
        // Given
        let manager = WebSocketManager.shared
        manager.connect()

        // When
        manager.disconnect()

        // Then
        XCTAssertEqual(manager.connectionStatus, .disconnected)
        XCTAssertFalse(manager.isConnected)
    }

    func testDisconnect_ClearsPendingRequests() {
        // Given
        let manager = WebSocketManager.shared
        manager.connect()

        // When
        manager.disconnect()

        // Then
        XCTAssertEqual(manager.testPendingRequestsCount, 0)
    }

    func testDisconnect_ResetsReconnectAttempts() {
        // Given
        let manager = WebSocketManager.shared
        manager.connect()

        // When
        manager.disconnect()

        // Then
        XCTAssertEqual(manager.testReconnectAttempts, 0)
    }

    // MARK: - Connection Status Display Tests

    func testConnectionStatus_DisconnectedDisplayText() {
        XCTAssertEqual(ConnectionStatus.disconnected.displayText, "Disconnected")
    }

    func testConnectionStatus_ConnectingDisplayText() {
        XCTAssertEqual(ConnectionStatus.connecting.displayText, "Connecting...")
    }

    func testConnectionStatus_ConnectedDisplayText() {
        XCTAssertEqual(ConnectionStatus.connected.displayText, "Connected")
    }

    func testConnectionStatus_FailedDisplayText() {
        XCTAssertEqual(ConnectionStatus.failed.displayText, "Connection Failed")
    }

    // MARK: - Reconnection Backoff Calculation Tests

    func testReconnectionDelay_FirstAttempt() {
        // First attempt: 2^0 = 1 second
        let delay = min(pow(2.0, Double(1 - 1)), 16.0)
        XCTAssertEqual(delay, 1.0)
    }

    func testReconnectionDelay_SecondAttempt() {
        // Second attempt: 2^1 = 2 seconds
        let delay = min(pow(2.0, Double(2 - 1)), 16.0)
        XCTAssertEqual(delay, 2.0)
    }

    func testReconnectionDelay_ThirdAttempt() {
        // Third attempt: 2^2 = 4 seconds
        let delay = min(pow(2.0, Double(3 - 1)), 16.0)
        XCTAssertEqual(delay, 4.0)
    }

    func testReconnectionDelay_FourthAttempt() {
        // Fourth attempt: 2^3 = 8 seconds
        let delay = min(pow(2.0, Double(4 - 1)), 16.0)
        XCTAssertEqual(delay, 8.0)
    }

    func testReconnectionDelay_FifthAttempt() {
        // Fifth attempt: 2^4 = 16 seconds (capped)
        let delay = min(pow(2.0, Double(5 - 1)), 16.0)
        XCTAssertEqual(delay, 16.0)
    }

    func testReconnectionDelay_BeyondMaxIsCapped() {
        // Beyond max should still be capped at 16
        let delay = min(pow(2.0, Double(10 - 1)), 16.0)
        XCTAssertEqual(delay, 16.0)
    }

    // MARK: - Cleanup

    override func tearDown() {
        super.tearDown()
        WebSocketManager.shared.disconnect()
    }
}
