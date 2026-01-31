import Foundation
@testable import Dobby

/// Mock URLSession for testing WebSocketManager
/// Note: This mock tracks calls but doesn't actually create WebSocket connections
final class MockURLSession {
    // MARK: - Properties

    var mockWebSocketTask: MockWebSocketTask?
    var webSocketTaskCreatedWithRequest: URLRequest?
    var webSocketTaskCreatedWithURL: URL?

    // MARK: - Initialization

    init(mockTask: MockWebSocketTask? = nil) {
        self.mockWebSocketTask = mockTask ?? MockWebSocketTask()
    }

    // MARK: - Mock Methods

    /// Mock version of webSocketTask(with:) that returns our mock task
    func webSocketTask(with request: URLRequest) -> MockWebSocketTask {
        webSocketTaskCreatedWithRequest = request
        webSocketTaskCreatedWithURL = request.url
        return mockWebSocketTask ?? MockWebSocketTask()
    }

    /// Mock version of webSocketTask(with:) for URL
    func webSocketTask(with url: URL) -> MockWebSocketTask {
        webSocketTaskCreatedWithURL = url
        return mockWebSocketTask ?? MockWebSocketTask()
    }

    // MARK: - Test Helpers

    /// Reset all tracking state
    func reset() {
        webSocketTaskCreatedWithRequest = nil
        webSocketTaskCreatedWithURL = nil
        mockWebSocketTask?.reset()
    }
}

// MARK: - Mock URLSession Configuration

extension MockURLSession {
    /// Create a mock session with a pre-configured task
    static func configured(with task: MockWebSocketTask = MockWebSocketTask()) -> MockURLSession {
        return MockURLSession(mockTask: task)
    }
}
