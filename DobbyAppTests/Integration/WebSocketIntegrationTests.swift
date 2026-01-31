import XCTest
import SwiftData
@testable import Dobby

/// Request frame structure for parsing WebSocket requests in tests
private struct RequestFrame: Codable {
    let type: String
    let method: String
    let id: String
    let params: [String: AnyCodable]?
}

/// Integration tests for the complete WebSocket message flow
/// These tests verify the end-to-end behavior of WebSocket communication
final class WebSocketIntegrationTests: XCTestCase {

    var mockWebSocket: MockWebSocketTask!

    override func setUp() {
        super.setUp()
        mockWebSocket = MockWebSocketTask()
    }

    override func tearDown() {
        mockWebSocket.reset()
        mockWebSocket = nil
        super.tearDown()
    }

    // MARK: - Full Handshake Flow Tests

    func testFullConnectionHandshake_Success() {
        // Given: A challenge event followed by success response
        let sequence = WebSocketTestFixtures.connectionHandshakeSequence(nonce: "test-123")

        // Verify challenge event can be parsed
        let challengeData = sequence[0].data(using: .utf8)!
        let challengeFrame = try? JSONDecoder().decode(BaseFrame.self, from: challengeData)

        XCTAssertNotNil(challengeFrame)
        XCTAssertEqual(challengeFrame?.type, "event")

        // Verify success response can be parsed
        let successData = sequence[1].data(using: .utf8)!
        let successFrame = try? JSONDecoder().decode(ResponseFrame.self, from: successData)

        XCTAssertNotNil(successFrame)
        XCTAssertTrue(successFrame?.ok ?? false)
    }

    // MARK: - Chat Message Flow Tests

    func testChatMessageFlow_SendAndReceive() {
        // Given: A user sends a message
        let userMessage = "Hello, Dobby!"
        let sessionKey = "test-session"

        // Simulate sending via mock
        let sendPayload = """
        {"type":"req","method":"chat.send","id":"msg-1","params":{"content":"\(userMessage)","sessionKey":"\(sessionKey)"}}
        """
        mockWebSocket.send(.string(sendPayload)) { _ in }

        // Verify message was sent
        XCTAssertEqual(mockWebSocket.sentMessages.count, 1)

        // Simulate receiving a response
        let responseJson = WebSocketTestFixtures.chatEvent(
            content: "Hello! How can I help you today?",
            state: "final",
            sessionKey: sessionKey
        )

        // Verify response can be parsed
        let responseData = responseJson.data(using: .utf8)!
        let eventFrame = try? JSONDecoder().decode(EventFrame.self, from: responseData)

        XCTAssertNotNil(eventFrame)
        XCTAssertEqual(eventFrame?.event, "chat")
    }

    // MARK: - Task Execution Flow Tests

    func testTaskExecutionFlow_FullLifecycle() {
        let taskId = UUID()
        let taskTitle = "Run tests"
        let taskResult = "All 145 tests passed"

        // Get the full execution sequence
        let sequence = WebSocketTestFixtures.taskExecutionSequence(
            taskId: taskId,
            title: taskTitle,
            result: taskResult
        )

        // Verify sequence has expected events
        XCTAssertEqual(sequence.count, 4)

        // Parse and verify each event
        for (index, json) in sequence.enumerated() {
            let data = json.data(using: .utf8)!
            let frame = try? JSONDecoder().decode(EventFrame.self, from: data)

            XCTAssertNotNil(frame, "Failed to parse event at index \(index)")
            XCTAssertEqual(frame?.type, "event")
            XCTAssertEqual(frame?.event, "agent")
        }
    }

    func testTaskProgressUpdates_IncrementalProgress() {
        let taskId = UUID()

        // Simulate progress updates: 0% -> 25% -> 50% -> 75% -> 100%
        let progressSteps = [0, 25, 50, 75, 100]

        for progress in progressSteps {
            let json = WebSocketTestFixtures.taskProgressEvent(taskId: taskId, progress: progress)
            let data = json.data(using: .utf8)!

            // Verify each progress event parses correctly
            let frame = try? JSONDecoder().decode(EventFrame.self, from: data)
            XCTAssertNotNil(frame)
            XCTAssertEqual(frame?.event, "task.progress")
        }
    }

    // MARK: - Error Handling Flow Tests

    func testErrorResponse_Parsing() {
        let errorJson = WebSocketTestFixtures.errorResponse(
            id: "test-request",
            code: "rate_limited",
            message: "Too many requests. Please try again later."
        )

        let data = errorJson.data(using: .utf8)!
        let frame = try? JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertNotNil(frame)
        XCTAssertFalse(frame?.ok ?? true)
        XCTAssertNotNil(frame?.error)
        XCTAssertEqual(frame?.error?.code, "rate_limited")
    }

    func testConnectionFailure_Parsing() {
        let failureJson = WebSocketTestFixtures.connectFailure(
            code: "invalid_token",
            message: "The provided authentication token is invalid or expired"
        )

        let data = failureJson.data(using: .utf8)!
        let frame = try? JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertNotNil(frame)
        XCTAssertFalse(frame?.ok ?? true)
        XCTAssertEqual(frame?.error?.code, "invalid_token")
    }

    // MARK: - History Loading Flow Tests

    func testChatHistoryResponse_MultipleMessages() {
        let historyJson = WebSocketTestFixtures.chatHistoryResponse(
            id: "history-1",
            messages: [
                (role: "user", content: "Hello"),
                (role: "assistant", content: "Hi there!"),
                (role: "user", content: "How are you?"),
                (role: "assistant", content: "I'm doing great, thanks for asking!")
            ]
        )

        let data = historyJson.data(using: .utf8)!
        let frame = try? JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertNotNil(frame)
        XCTAssertTrue(frame?.ok ?? false)
        XCTAssertNotNil(frame?.payload)
    }

    // MARK: - Agent Stream Events Tests

    func testAgentStreamEvents_LifecycleAndOutput() {
        let runId = "agent-run-123"

        // Start event
        let startJson = WebSocketTestFixtures.agentLifecycleEvent(runId: runId, phase: "start")
        let startData = startJson.data(using: .utf8)!
        let startFrame = try? JSONDecoder().decode(EventFrame.self, from: startData)

        XCTAssertNotNil(startFrame)
        XCTAssertEqual(startFrame?.event, "agent")

        // Output events
        let outputTexts = ["Analyzing your request...", "Working on it...", "Almost done..."]
        for text in outputTexts {
            let outputJson = WebSocketTestFixtures.agentAssistantEvent(runId: runId, text: text)
            let outputData = outputJson.data(using: .utf8)!
            let outputFrame = try? JSONDecoder().decode(EventFrame.self, from: outputData)

            XCTAssertNotNil(outputFrame)
            XCTAssertEqual(outputFrame?.event, "agent")
        }

        // End event
        let endJson = WebSocketTestFixtures.agentLifecycleEvent(runId: runId, phase: "end")
        let endData = endJson.data(using: .utf8)!
        let endFrame = try? JSONDecoder().decode(EventFrame.self, from: endData)

        XCTAssertNotNil(endFrame)
        XCTAssertEqual(endFrame?.event, "agent")
    }

    // MARK: - WebSocket Message Simulation Tests

    func testMockWebSocket_SendReceiveCycle() {
        // Send a message
        mockWebSocket.send(.string("test message")) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(mockWebSocket.sentMessages.count, 1)
        XCTAssertEqual(mockWebSocket.lastSentString, "test message")

        // Configure and simulate receive
        mockWebSocket.receiveResults = [.success(.string("response"))]

        let expectation = expectation(description: "Receive message")
        mockWebSocket.receive { result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    XCTAssertEqual(text, "response")
                } else {
                    XCTFail("Expected string message")
                }
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testMockWebSocket_ErrorSimulation() {
        mockWebSocket.sendError = MockWebSocketError.sendFailed

        mockWebSocket.send(.string("test")) { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error is MockWebSocketError)
        }
    }

    // MARK: - Request/Response Correlation Tests

    func testRequestResponseCorrelation_MatchingIds() {
        let requestId = "req-\(UUID().uuidString)"

        // Create a request
        let request = """
        {"type":"req","method":"test.method","id":"\(requestId)","params":{}}
        """

        // Create matching response
        let response = WebSocketTestFixtures.successResponse(id: requestId)

        // Parse both
        let reqData = request.data(using: .utf8)!
        let resData = response.data(using: .utf8)!

        let reqFrame = try? JSONDecoder().decode(RequestFrame.self, from: reqData)
        let resFrame = try? JSONDecoder().decode(ResponseFrame.self, from: resData)

        // Verify IDs match
        XCTAssertEqual(reqFrame?.id, resFrame?.id)
    }

    // MARK: - Concurrent Operations Tests

    func testMultipleConcurrentRequests_IndependentTracking() {
        let requestIds = (1...5).map { "req-\($0)" }

        // Simulate sending multiple requests
        for id in requestIds {
            let request = """
            {"type":"req","method":"test","id":"\(id)","params":{}}
            """
            mockWebSocket.send(.string(request)) { _ in }
        }

        XCTAssertEqual(mockWebSocket.sentMessages.count, 5)

        // Verify each request can be parsed and identified
        for (index, message) in mockWebSocket.sentMessages.enumerated() {
            if case .string(let json) = message {
                let data = json.data(using: .utf8)!
                let frame = try? JSONDecoder().decode(RequestFrame.self, from: data)
                XCTAssertEqual(frame?.id, requestIds[index])
            }
        }
    }
}
