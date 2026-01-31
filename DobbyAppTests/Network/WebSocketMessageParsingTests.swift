import XCTest
@testable import Dobby

/// Tests for WebSocket message parsing (JSON frames)
final class WebSocketMessageParsingTests: XCTestCase {

    // MARK: - BaseFrame Type Detection

    func testBaseFrame_EventType() throws {
        let json = """
        {"type":"event","event":"chat","payload":{}}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(BaseFrame.self, from: data)

        XCTAssertEqual(frame.type, "event")
    }

    func testBaseFrame_ResponseType() throws {
        let json = """
        {"type":"res","id":"test-id","ok":true}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(BaseFrame.self, from: data)

        XCTAssertEqual(frame.type, "res")
    }

    func testBaseFrame_RequestType() throws {
        let json = """
        {"type":"req","method":"chat.send","id":"req-123"}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(BaseFrame.self, from: data)

        XCTAssertEqual(frame.type, "req")
    }

    // MARK: - EventFrame Parsing

    func testEventFrame_ConnectChallenge() throws {
        let json = WebSocketTestFixtures.connectChallenge
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.type, "event")
        XCTAssertEqual(frame.event, "connect.challenge")
        XCTAssertNotNil(frame.payload)

        if let payload = frame.payload,
           let nonce = payload["nonce"]?.value as? String {
            XCTAssertEqual(nonce, "test-nonce-12345")
        } else {
            XCTFail("Expected nonce in payload")
        }
    }

    func testEventFrame_ChatMessage() throws {
        let json = WebSocketTestFixtures.chatEvent(content: "Hello, world!", sessionKey: "main")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "chat")
        XCTAssertNotNil(frame.payload)

        if let payload = frame.payload,
           let state = payload["state"]?.value as? String {
            XCTAssertEqual(state, "final")
        } else {
            XCTFail("Expected state in payload")
        }
    }

    func testEventFrame_TaskCreated() throws {
        let taskId = UUID()
        let json = WebSocketTestFixtures.taskCreatedEvent(taskId: taskId, title: "Test Task")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "task.created")
        XCTAssertNotNil(frame.payload)

        if let payload = frame.payload,
           let title = payload["title"]?.value as? String {
            XCTAssertEqual(title, "Test Task")
        } else {
            XCTFail("Expected title in payload")
        }
    }

    func testEventFrame_AgentLifecycle() throws {
        let json = WebSocketTestFixtures.agentLifecycleEvent(runId: "run-123", phase: "start")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "agent")
        XCTAssertNotNil(frame.payload)

        if let payload = frame.payload,
           let runId = payload["runId"]?.value as? String,
           let stream = payload["stream"]?.value as? String {
            XCTAssertEqual(runId, "run-123")
            XCTAssertEqual(stream, "lifecycle")
        } else {
            XCTFail("Expected runId and stream in payload")
        }
    }

    // MARK: - ResponseFrame Parsing

    func testResponseFrame_Success() throws {
        let json = WebSocketTestFixtures.connectSuccess
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertEqual(frame.type, "res")
        XCTAssertEqual(frame.id, "connect")
        XCTAssertTrue(frame.ok)
        XCTAssertNil(frame.error)
    }

    func testResponseFrame_Failure() throws {
        let json = WebSocketTestFixtures.connectFailure(code: "auth_failed", message: "Invalid token")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertEqual(frame.type, "res")
        XCTAssertEqual(frame.id, "connect")
        XCTAssertFalse(frame.ok)
        XCTAssertNotNil(frame.error)
        XCTAssertEqual(frame.error?.code, "auth_failed")
        XCTAssertEqual(frame.error?.message, "Invalid token")
    }

    func testResponseFrame_WithPayload() throws {
        let json = """
        {"type":"res","id":"chat.history","ok":true,"payload":{"messages":[]}}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertTrue(frame.ok)
        XCTAssertNotNil(frame.payload)
    }

    // MARK: - GatewayError Parsing

    func testGatewayError_FullParsing() throws {
        let json = """
        {"code":"rate_limited","message":"Too many requests","details":{"retryAfter":60}}
        """
        let data = json.data(using: .utf8)!

        let error = try JSONDecoder().decode(GatewayError.self, from: data)

        XCTAssertEqual(error.code, "rate_limited")
        XCTAssertEqual(error.message, "Too many requests")
    }

    // MARK: - Edge Cases

    func testEventFrame_EmptyPayload() throws {
        let json = """
        {"type":"event","event":"ping","payload":{}}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "ping")
        XCTAssertNotNil(frame.payload)
        XCTAssertTrue(frame.payload?.isEmpty ?? false)
    }

    func testEventFrame_NullPayload() throws {
        let json = """
        {"type":"event","event":"ping"}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "ping")
        XCTAssertNil(frame.payload)
    }

    func testResponseFrame_BothResultAndPayload() throws {
        // Gateway sometimes uses "payload" instead of "result"
        let json = """
        {"type":"res","id":"test","ok":true,"result":{"key":"result_value"},"payload":{"key":"payload_value"}}
        """
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertTrue(frame.ok)
        // Both should be accessible
        XCTAssertNotNil(frame.result)
        XCTAssertNotNil(frame.payload)
    }
}
