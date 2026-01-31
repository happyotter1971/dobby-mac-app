import Foundation
import Combine

/// Manages WebSocket connection to Clawdbot Gateway using the official gateway protocol
@Observable
class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    
    // Connection state
    private(set) var isConnected = false
    private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    // WebSocket
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    // Challenge nonce for handshake
    private var connectNonce: String?
    
    // Message handlers
    var onMessageReceived: ((GatewayChatMessage) -> Void)?
    var onTaskUpdate: ((TaskUpdate) -> Void)?
    var onHistoryLoaded: (([HistoryMessage]) -> Void)?
    
    // Gateway URL
    private let gatewayURLString = "ws://127.0.0.1:18789"
    
    // Reconnection
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // Request tracking
    private var pendingRequests: [String: (Bool, Any?, GatewayError?) -> Void] = [:]

    // Offline task sync queue
    private var pendingTaskCreations: [(String, TaskPriority, UUID)] = []
    private var pendingTaskUpdates: [(UUID, TaskStatus)] = []
    
    private override init() {
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard !isConnected, let gatewayURL = URL(string: gatewayURLString) else {
            print("⚠️ Already connected or invalid URL, ignoring connect() call")
            return
        }

        connectionStatus = .connecting
        let timestamp = Date().timeIntervalSince1970
        print("🔌 [\(timestamp)] Connecting to Clawdbot Gateway at \(gatewayURL)")

        var request = URLRequest(url: gatewayURL)
        request.timeoutInterval = 30

        webSocket = urlSession?.webSocketTask(with: request)
        webSocket?.resume()
        
        print("🔌 [\(Date().timeIntervalSince1970)] WebSocket resumed, waiting for challenge...")

        // Start listening for messages
        receiveMessage()
    }
    
    func disconnect() {
        connectionStatus = .disconnected
        isConnected = false
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
        pendingRequests.removeAll()
    }
    
    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnection attempts reached")
            connectionStatus = .failed
            return
        }
        
        reconnectAttempts += 1
        print("🔄 Reconnecting... (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        disconnect()
        
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), 16.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate Methods
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connection opened")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("❌ WebSocket connection closed: \(closeCode)")
        handleDisconnection()
    }

    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening

            case .failure(let error):
                print("❌ WebSocket receive error: \(error.localizedDescription)")
                self?.handleDisconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            print("📥 RECEIVED: \(text)")
            parseAndHandleJSON(text)

        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                print("📥 RECEIVED (data): \(text)")
                parseAndHandleJSON(text)
            }

        @unknown default:
            print("⚠️ Unknown message type")
        }
    }
    
    private func parseAndHandleJSON(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            let baseFrame = try decoder.decode(BaseFrame.self, from: data)
            
            switch baseFrame.type {
            case "event":
                handleEvent(data)
            case "res":
                handleResponse(data)
            default:
                print("⚠️ Unknown frame type: \(baseFrame.type)")
            }
        } catch {
            print("❌ Failed to parse message: \(error)")
        }
    }
    
    private func handleEvent(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let event = try decoder.decode(EventFrame.self, from: data)

            switch event.event {
            case "connect.challenge":
                if let nonce = event.payload?["nonce"] as? String {
                    print("🔑 Received connect challenge with nonce: \(nonce)")
                    connectNonce = nonce
                    sendConnectHandshake()
                }

            case "chat":
                handleChatEvent(event.payload)

            case "task.created", "task.progress", "task.completed":
                handleTaskEvent(event.event, payload: event.payload)

            default:
                print("📨 Event: \(event.event)")
            }
        } catch {
            print("❌ Failed to parse event: \(error)")
        }
    }
    
    private func handleResponse(_ data: Data) {
        do {
            let response = try JSONDecoder().decode(ResponseFrame.self, from: data)
            
            if response.id == "connect" {
                if response.ok {
                    DispatchQueue.main.async {
                        self.isConnected = true
                        self.connectionStatus = .connected
                        self.reconnectAttempts = 0
                        print("✅ Connected to Clawdbot Gateway")
                        self.flushPendingTaskSync()
                    }
                } else {
                    print("❌ Connection failed: \(response.error?.message ?? "unknown")")
                    handleDisconnection()
                }
                return
            }
            
            if let handler = pendingRequests[response.id] {
                handler(response.ok, response.result, response.error)
                pendingRequests.removeValue(forKey: response.id)
            }
        } catch {
            print("❌ Failed to parse response: \(error)")
        }
    }
    
    private func handleChatEvent(_ payload: [String: Any]?) {
        guard let payload = payload,
              let state = payload["state"] as? String,
              state == "final",
              let message = payload["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]],
              let firstPart = content.first,
              let text = firstPart["text"] as? String else {
            return
        }
        
        let sessionKey = payload["sessionKey"] as? String ?? "main"
        let chatMsg = GatewayChatMessage(content: text, isFromUser: false, sessionKey: sessionKey)
        
        DispatchQueue.main.async {
            self.onMessageReceived?(chatMsg)
        }
    }
    
    private func handleTaskEvent(_ eventType: String, payload: [String: Any]?) {
        guard let payload = payload else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let decoder = JSONDecoder()
            var update: TaskUpdate?

            switch eventType {
            case "task.created":
                let p = try decoder.decode(TaskCreatedPayload.self, from: data)
                update = TaskUpdate(type: "task.created", taskId: UUID(uuidString: p.taskId) ?? UUID(), title: p.title, status: .backlog)
            case "task.progress":
                let p = try decoder.decode(TaskProgressPayload.self, from: data)
                update = TaskUpdate(type: "task.progress", taskId: UUID(uuidString: p.taskId) ?? UUID(), status: TaskStatus(rawValue: p.status) ?? .inProcess, progress: p.progress)
            case "task.completed":
                let p = try decoder.decode(TaskCompletedPayload.self, from: data)
                update = TaskUpdate(type: "task.completed", taskId: UUID(uuidString: p.taskId) ?? UUID(), status: .completed, progress: 100, resultSummary: p.resultSummary)
            default:
                print("⚠️ Unknown task event type: \(eventType)")
            }

            if let update = update {
                DispatchQueue.main.async {
                    self.onTaskUpdate?(update)
                }
            }
        } catch {
            print("❌ Failed to parse task event: \(error)")
        }
    }
    
    private func handleDisconnection() {
        if isConnected {
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionStatus = .disconnected
                print("❌ Disconnected from gateway")
                self.reconnect()
            }
        }
    }
    
    // MARK: - Sending Messages
    
    private func sendRequest<T: Encodable>(
        method: String,
        params: T,
        id: String? = nil,
        completion: ((Bool, Any?, GatewayError?) -> Void)? = nil
    ) {
        let requestId = id ?? UUID().uuidString
        let request = RequestFrame(type: "req", method: method, params: params, id: requestId)

        if let completion = completion {
            pendingRequests[requestId] = completion
        }

        do {
            let data = try JSONEncoder().encode(request)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📤 SENDING [\(method)]: \(jsonString)")
                webSocket?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("❌ Failed to send message: \(error.localizedDescription)")
                        completion?(false, nil, GatewayError(code: "send_failed", message: error.localizedDescription))
                    }
                }
            }
        } catch {
            print("❌ Failed to encode request: \(error.localizedDescription)")
            completion?(false, nil, GatewayError(code: "encode_failed", message: error.localizedDescription))
        }
    }
    
    private func sendConnectHandshake() {
        guard let authToken = AppSettings.shared.authToken, !authToken.isEmpty else {
            print("❌ Auth token not set. Cannot connect.")
            // Optionally, update connection status to failed or prompt user
            return
        }

        print("🤝 Initiating connect handshake...")
        let params = ConnectParams(
            minProtocol: 3,
            maxProtocol: 3,
            role: "operator",
            scopes: ["operator.admin", "operator.write", "operator.read"],
            client: ClientInfo(
                id: "clawdbot-macos",
                displayName: "Dobby Mac App",
                version: "0.1.0",
                mode: "ui",
                platform: "macos",
                deviceFamily: "Mac",
                modelIdentifier: "MacOS"
            ),
            auth: AuthInfo(token: authToken)
        )

        sendRequest(method: "connect", params: params, id: "connect")
    }
    
    // MARK: - Public API
    
    func sendChatMessage(content: String, sessionId: String = "main") {
        guard isConnected else {
            print("⚠️ Cannot send message: not connected")
            return
        }
        
        let params = ChatSendParams(
            sessionKey: sessionId,
            message: content,
            idempotencyKey: UUID().uuidString
        )
        
        sendRequest(method: "chat.send", params: params)
    }
    
    func loadChatHistory(sessionId: String = "main", limit: Int = 50) {
        guard isConnected else { return }

        let params = ChatHistoryParams(sessionKey: sessionId, limit: limit)

        sendRequest(method: "chat.history", params: params) { [weak self] ok, result, error in
            guard ok, let resultDict = result as? [String: Any], let messages = resultDict["messages"] as? [[String: Any]] else {
                print("❌ Failed to load history: \(error?.message ?? "unknown")")
                return
            }
            
            print("📚 Loaded chat history: \(messages.count) messages")
            let historyMessages = messages.compactMap { msgDict -> HistoryMessage? in
                guard let role = msgDict["role"] as? String,
                      let contentArray = msgDict["content"] as? [[String: Any]],
                      let textContent = (contentArray.first?["text"] as? String) else {
                    return nil
                }
                let timestamp = (msgDict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                return HistoryMessage(role: role, content: textContent, timestamp: timestamp)
            }
            
            DispatchQueue.main.async {
                self?.onHistoryLoaded?(historyMessages)
            }
        }
    }
    
    func createTask(title: String, priority: TaskPriority = .medium, taskId: UUID = UUID()) {
        if !isConnected {
            pendingTaskCreations.append((title, priority, taskId))
            print("⏳ Queued task creation: \(title)")
            return
        }
        let params = TaskCreateParams(
            taskId: taskId.uuidString,
            title: title,
            priority: priority.rawValue
        )
        sendRequest(method: "task.create", params: params) { ok, _, error in
            if ok {
                print("✅ Task created: \(title)")
            } else {
                print("❌ Task creation failed: \(error?.message ?? "unknown")")
            }
        }
    }

    func updateTask(taskId: UUID, status: TaskStatus) {
        if !isConnected {
            pendingTaskUpdates.append((taskId, status))
            print("⏳ Queued task update: \(taskId)")
            return
        }
        let params = TaskUpdateParams(
            taskId: taskId.uuidString,
            status: status.rawValue
        )
        sendRequest(method: "task.update", params: params) { ok, _, error in
            if ok {
                print("✅ Task updated: \(taskId)")
            } else {
                print("❌ Task update failed: \(error?.message ?? "unknown")")
            }
        }
    }

    func executeTask(taskId: UUID, title: String) {
        guard isConnected else {
            print("⚠️ Cannot execute task: not connected")
            return
        }
        let params = TaskExecuteParams(taskId: taskId.uuidString, title: title)
        sendRequest(method: "task.execute", params: params) { ok, _, error in
            if ok {
                print("✅ Task execution started: \(title)")
            } else {
                print("❌ Task execution failed: \(error?.message ?? "unknown") (\(error?.code ?? "none")) for task: \(title)")
            }
        }
    }

    private func flushPendingTaskSync() {
        print("🔄 Flushing pending task syncs...")
        pendingTaskCreations.forEach { createTask(title: $0, priority: $1, taskId: $2) }
        pendingTaskCreations.removeAll()
        pendingTaskUpdates.forEach { updateTask(taskId: $0, status: $1) }
        pendingTaskUpdates.removeAll()
        print("✅ Flushed all pending task syncs")
    }
}

// MARK: - Connection Status

enum ConnectionStatus {
    case disconnected, connecting, connected, failed
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .failed: return "Connection Failed"
        }
    }
    
    var color: String {
        switch self {
        case .disconnected: "gray"
        case .connecting: "yellow"
        case .connected: "green"
        case .failed: "red"
        }
    }
}

// MARK: - Protocol Types

// Codable helpers for dictionary and any values
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal }
        else if let doubleVal = try? container.decode(Double.self) { value = doubleVal }
        else if let boolVal = try? container.decode(Bool.self) { value = boolVal }
        else if let stringVal = try? container.decode(String.self) { value = stringVal }
        else if let arrayVal = try? container.decode([AnyCodable].self) { value = arrayVal.map { $0.value } }
        else if let dictVal = try? container.decode([String: AnyCodable].self) { value = dictVal.mapValues { $0.value } }
        else { throw DecodingError.typeMismatch(AnyCodable.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported type")) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int: try container.encode(intVal)
        case let doubleVal as Double: try container.encode(doubleVal)
        case let boolVal as Bool: try container.encode(boolVal)
        case let stringVal as String: try container.encode(stringVal)
        case let arrayVal as [Any]: try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]: try container.encode(dictVal.mapValues { AnyCodable($0) })
        default: throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

struct BaseFrame: Codable {
    let type: String
}

struct EventFrame: Codable {
    let type: String
    let event: String
    let payload: [String: AnyCodable]?
}

struct ResponseFrame: Codable {
    let type: String
    let id: String
    let ok: Bool
    let result: [String: AnyCodable]?
    let error: GatewayError?
}

struct RequestFrame<T: Encodable>: Encodable {
    let type: String
    let method: String
    let params: T
    let id: String
}

// MARK: - RPC Parameter Types

struct ConnectParams: Encodable {
    let minProtocol: Int, maxProtocol: Int, role: String, scopes: [String]
    let client: ClientInfo
    let auth: AuthInfo?
}

struct AuthInfo: Encodable {
    let token: String
}

struct ClientInfo: Encodable {
    let id: String, displayName: String, version: String, mode: String
    let platform: String, deviceFamily: String, modelIdentifier: String
}

struct ChatSendParams: Encodable {
    let sessionKey: String, message: String, idempotencyKey: String
}

struct ChatHistoryParams: Encodable {
    let sessionKey: String, limit: Int
}

struct TaskExecuteParams: Encodable {
    let taskId: String, title: String
}

struct TaskCreateParams: Encodable {
    let taskId: String, title: String, priority: String
}

struct TaskUpdateParams: Encodable {
    let taskId: String, status: String
}

struct GatewayError: Codable {
    let code: String, message: String
}

// MARK: - Message Types

struct GatewayChatMessage {
    let content: String, isFromUser: Bool, sessionKey: String
}

struct TaskUpdate {
    let type: String
    let taskId: UUID
    var title: String? = nil
    var status: TaskStatus? = nil
    var progress: Int? = nil
    var resultSummary: String? = nil
}

struct HistoryMessage {
    let role: String, content: String, timestamp: Date
}

struct TaskCreatedPayload: Codable {
    let taskId: String, title: String, priority: String?
}

struct TaskProgressPayload: Codable {
    let taskId: String, status: String, progress: Int?
}

struct TaskCompletedPayload: Codable {
    let taskId: String, resultSummary: String?
}
