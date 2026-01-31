import Foundation
@testable import Dobby

/// JSON message fixtures for WebSocket testing
enum WebSocketTestFixtures {

    // MARK: - Event Frames

    /// Challenge event from gateway during connection
    static let connectChallenge = """
    {"type":"event","event":"connect.challenge","payload":{"nonce":"test-nonce-12345"}}
    """

    /// Create a challenge event with custom nonce
    static func connectChallenge(nonce: String) -> String {
        """
        {"type":"event","event":"connect.challenge","payload":{"nonce":"\(nonce)"}}
        """
    }

    /// Chat message event
    static func chatEvent(
        content: String,
        state: String = "final",
        sessionKey: String = "main"
    ) -> String {
        """
        {"type":"event","event":"chat","payload":{"state":"\(state)","sessionKey":"\(sessionKey)","message":{"content":[{"text":"\(content)"}]}}}
        """
    }

    /// Task created event
    static func taskCreatedEvent(
        taskId: UUID = UUID(),
        title: String = "New Task",
        status: String = "backlog",
        priority: String = "medium"
    ) -> String {
        """
        {"type":"event","event":"task.created","payload":{"taskId":"\(taskId.uuidString)","title":"\(title)","status":"\(status)","priority":"\(priority)"}}
        """
    }

    /// Task progress event
    static func taskProgressEvent(
        taskId: UUID,
        progress: Int = 50,
        status: String = "inProcess"
    ) -> String {
        """
        {"type":"event","event":"task.progress","payload":{"taskId":"\(taskId.uuidString)","progress":\(progress),"status":"\(status)"}}
        """
    }

    /// Task completed event
    static func taskCompletedEvent(
        taskId: UUID,
        result: String = "Task completed successfully"
    ) -> String {
        """
        {"type":"event","event":"task.completed","payload":{"taskId":"\(taskId.uuidString)","status":"completed","resultSummary":"\(result)"}}
        """
    }

    /// Agent lifecycle event (start/end)
    static func agentLifecycleEvent(
        runId: String,
        phase: String  // "start" or "end"
    ) -> String {
        """
        {"type":"event","event":"agent","payload":{"runId":"\(runId)","stream":"lifecycle","data":{"phase":"\(phase)"}}}
        """
    }

    /// Agent assistant stream event (text output)
    static func agentAssistantEvent(
        runId: String,
        text: String
    ) -> String {
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        {"type":"event","event":"agent","payload":{"runId":"\(runId)","stream":"assistant","data":{"text":"\(escapedText)"}}}
        """
    }

    // MARK: - Response Frames

    /// Successful connect response
    static let connectSuccess = """
    {"type":"res","id":"connect","ok":true}
    """

    /// Failed connect response
    static func connectFailure(
        code: String = "auth_failed",
        message: String = "Invalid token"
    ) -> String {
        """
        {"type":"res","id":"connect","ok":false,"error":{"code":"\(code)","message":"\(message)"}}
        """
    }

    /// Generic successful response
    static func successResponse(id: String, payload: String? = nil) -> String {
        if let payload = payload {
            return """
            {"type":"res","id":"\(id)","ok":true,"payload":\(payload)}
            """
        }
        return """
        {"type":"res","id":"\(id)","ok":true}
        """
    }

    /// Generic error response
    static func errorResponse(
        id: String,
        code: String,
        message: String
    ) -> String {
        """
        {"type":"res","id":"\(id)","ok":false,"error":{"code":"\(code)","message":"\(message)"}}
        """
    }

    /// Chat history response
    static func chatHistoryResponse(
        id: String = "chat.history",
        messages: [(role: String, content: String)]
    ) -> String {
        let messagesJson = messages.map { msg in
            """
            {"role":"\(msg.role)","content":"\(msg.content)","timestamp":"\(ISO8601DateFormatter().string(from: Date()))"}
            """
        }.joined(separator: ",")

        return """
        {"type":"res","id":"\(id)","ok":true,"payload":{"messages":[\(messagesJson)]}}
        """
    }

    // MARK: - Request Frame Helpers

    /// Expected connect request structure for verification
    struct ExpectedConnectRequest: Codable {
        let type: String
        let method: String
        let id: String
        let params: ConnectParams

        struct ConnectParams: Codable {
            let minProtocol: Int
            let maxProtocol: Int
            let role: String
            let scopes: [String]
        }
    }

    /// Expected chat.send request structure
    struct ExpectedChatSendRequest: Codable {
        let type: String
        let method: String
        let id: String
        let params: ChatParams

        struct ChatParams: Codable {
            let content: String
            let sessionKey: String?
        }
    }
}

// MARK: - Test Data Generators

extension WebSocketTestFixtures {
    /// Generate a sequence of events simulating a full task execution
    static func taskExecutionSequence(
        taskId: UUID,
        title: String,
        result: String
    ) -> [String] {
        let runId = "task-\(taskId.uuidString)"
        return [
            agentLifecycleEvent(runId: runId, phase: "start"),
            agentAssistantEvent(runId: runId, text: "Working on: \(title)"),
            agentAssistantEvent(runId: runId, text: "\n\(result)"),
            agentLifecycleEvent(runId: runId, phase: "end")
        ]
    }

    /// Generate a full connection handshake sequence
    static func connectionHandshakeSequence(nonce: String = "test-nonce") -> [String] {
        return [
            connectChallenge(nonce: nonce),
            connectSuccess
        ]
    }
}
