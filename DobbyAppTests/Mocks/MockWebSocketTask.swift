import Foundation
@testable import Dobby

// MARK: - WebSocket Protocol for Testing

/// Protocol that abstracts WebSocket operations for testing
protocol WebSocketTaskProtocol {
    func resume()
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping @Sendable (Error?) -> Void)
    func receive(completionHandler: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
}

// Make URLSessionWebSocketTask conform to the protocol
extension URLSessionWebSocketTask: WebSocketTaskProtocol {}

// MARK: - Mock WebSocket Task

/// Mock WebSocket task for testing without real network connections
/// Uses composition rather than inheritance since URLSessionWebSocketTask can't be properly subclassed
final class MockWebSocketTask: WebSocketTaskProtocol {
    // MARK: - Call Tracking

    var resumeCalled = false
    var cancelCalled = false
    var cancelCloseCode: URLSessionWebSocketTask.CloseCode?
    var cancelReason: Data?
    var sentMessages: [URLSessionWebSocketTask.Message] = []

    // MARK: - Configurable Behavior

    var sendError: Error?
    var receiveResults: [Result<URLSessionWebSocketTask.Message, Error>] = []
    private var receiveIndex = 0

    // Callback for when receive is called
    private var pendingReceiveHandler: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?

    // MARK: - WebSocketTaskProtocol Implementation

    func resume() {
        resumeCalled = true
    }

    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        cancelCalled = true
        cancelCloseCode = closeCode
        cancelReason = reason
    }

    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping @Sendable (Error?) -> Void) {
        sentMessages.append(message)
        completionHandler(sendError)
    }

    func receive(completionHandler: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        pendingReceiveHandler = completionHandler

        // If we have pre-configured results, deliver them
        if receiveIndex < receiveResults.count {
            let result = receiveResults[receiveIndex]
            receiveIndex += 1
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }

    // MARK: - Test Helpers

    /// Simulate receiving a message from the server
    func simulateReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        if let handler = pendingReceiveHandler {
            pendingReceiveHandler = nil
            DispatchQueue.main.async {
                handler(result)
            }
        }
    }

    /// Simulate receiving a string message
    func simulateReceiveString(_ json: String) {
        simulateReceive(.success(.string(json)))
    }

    /// Simulate receiving binary data
    func simulateReceiveData(_ data: Data) {
        simulateReceive(.success(.data(data)))
    }

    /// Simulate a receive error
    func simulateReceiveError(_ error: Error) {
        simulateReceive(.failure(error))
    }

    /// Get the last sent message as a string
    var lastSentString: String? {
        guard let lastMessage = sentMessages.last else { return nil }
        switch lastMessage {
        case .string(let str):
            return str
        case .data(let data):
            return String(data: data, encoding: .utf8)
        @unknown default:
            return nil
        }
    }

    /// Get the last sent message decoded as JSON
    func lastSentJSON<T: Decodable>(as type: T.Type) -> T? {
        guard let jsonString = lastSentString,
              let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Reset all tracking state
    func reset() {
        resumeCalled = false
        cancelCalled = false
        cancelCloseCode = nil
        cancelReason = nil
        sentMessages.removeAll()
        sendError = nil
        receiveResults.removeAll()
        receiveIndex = 0
        pendingReceiveHandler = nil
    }
}

// MARK: - Test Errors

enum MockWebSocketError: Error, LocalizedError {
    case connectionFailed
    case sendFailed
    case receiveFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Mock connection failed"
        case .sendFailed: return "Mock send failed"
        case .receiveFailed: return "Mock receive failed"
        case .timeout: return "Mock timeout"
        }
    }
}
