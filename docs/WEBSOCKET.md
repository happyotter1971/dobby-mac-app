# WebSocket Integration

## Overview

The Dobby Mac app connects to the Clawdbot Gateway via WebSocket at `ws://127.0.0.1:18790` using the **official Clawdbot Gateway RPC protocol**. This is the same protocol used by the Control UI, CLI, and other gateway clients.

## Architecture

```
┌─────────────────┐                    ┌─────────────────────┐
│   Mac App       │    WebSocket       │  Clawdbot Gateway   │
│   (SwiftUI)     │ ←──────────────→  │   (Node.js)         │
│                 │                    │                     │
│  ChatView       │  chat.send         │  Process message    │
│  TasksView      │  task.create       │  Execute tools      │
│                 │  task.update       │  Update state       │
│                 │                    │                     │
│                 │  ←─ chat.message   │  Send response      │
│                 │  ←─ task.created   │  Broadcast events   │
│                 │  ←─ task.progress  │                     │
│                 │  ←─ task.completed │                     │
└─────────────────┘                    └─────────────────────┘
```

## Message Protocol

The gateway uses an RPC-style protocol with:
- **Requests:** `type: "req"`, `method: "..."`, `params: {...}`, `id: "..."`
- **Responses:** `type: "res"`, `id: "..."`, `ok: true/false`, `result: {...}` or `error: {...}`
- **Events:** `type: "event"`, `event: "..."`, `payload: {...}`

### Connection Handshake

**Server → Client** (challenge on connect):
```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": {
    "nonce": "random-uuid",
    "ts": 1706634000000
  }
}
```

**Client → Server** (respond with connect):
```json
{
  "type": "req",
  "method": "connect",
  "id": "connect",
  "params": {
    "minProtocol": 1,
    "maxProtocol": 1,
    "role": "operator",
    "scopes": ["operator.write", "operator.read"],
    "client": {
      "id": "dobby-mac-app",
      "displayName": "Dobby Mac App",
      "version": "0.1.0",
      "mode": "app"
    }
  }
}
```

**Server → Client** (connection result):
```json
{
  "type": "res",
  "id": "connect",
  "ok": true,
  "result": {
    "protocol": 1,
    "serverVersion": "1.0.0"
  }
}
```

### Chat Messages

**Client → Server** (send message):
```json
{
  "type": "req",
  "method": "chat.send",
  "id": "req-uuid",
  "params": {
    "sessionKey": "main",
    "message": "What's on my calendar today?",
    "idempotencyKey": "unique-uuid"
  }
}
```

**Server → Client** (acknowledgment):
```json
{
  "type": "res",
  "id": "req-uuid",
  "ok": true,
  "result": {
    "runId": "unique-uuid",
    "status": "started"
  }
}
```

**Server → Client** (response via event):
```json
{
  "type": "event",
  "event": "chat",
  "payload": {
    "runId": "unique-uuid",
    "sessionKey": "main",
    "seq": 1,
    "state": "final",
    "message": {
      "role": "assistant",
      "content": [{"type": "text", "text": "You have 3 meetings today..."}],
      "timestamp": 1706634000000,
      "stopReason": "end_turn",
      "usage": {"input": 50, "output": 100, "totalTokens": 150}
    }
  }
}
```

**Get chat history:**
```json
{
  "type": "req",
  "method": "chat.history",
  "id": "req-uuid",
  "params": {
    "sessionKey": "main",
    "limit": 50
  }
}
```

**Response:**
```json
{
  "type": "res",
  "id": "req-uuid",
  "ok": true,
  "result": {
    "sessionKey": "main",
    "sessionId": "session-uuid",
    "messages": [...],
    "thinkingLevel": "low"
  }
}
```

### Task Management

**Current Implementation:** Tasks are managed locally in the Mac app (SwiftData). Task creation/updates are sent via chat messages for Dobby to acknowledge.

**Future:** Dedicated task RPC methods will be added to the gateway:
- `task.create` - Create task
- `task.update` - Update task status
- `task.list` - Get all tasks
- Events: `task.created`, `task.progress`, `task.completed`

**Example chat-based task creation:**
```json
{
  "type": "req",
  "method": "chat.send",
  "id": "req-uuid",
  "params": {
    "sessionKey": "main",
    "message": "Create task: Research IBM Turbonomic pricing",
    "idempotencyKey": "unique-uuid"
  }
}
```

### Keep-Alive

The gateway doesn't require client-side pings — the connection is kept alive automatically. The server will close idle connections after a timeout (configurable via gateway settings).

## Connection Management

### Auto-Reconnect

The `WebSocketManager` automatically reconnects on disconnection using exponential backoff:
- Attempt 1: 1 second delay
- Attempt 2: 2 seconds delay
- Attempt 3: 4 seconds delay
- Attempt 4: 8 seconds delay
- Attempt 5: 16 seconds delay (max)

Maximum reconnection attempts: 5

### Connection States

| State | Description | UI Indicator |
|-------|-------------|--------------|
| `disconnected` | No active connection | 🔴 Gray dot |
| `connecting` | Attempting to connect | 🟡 Yellow dot |
| `connected` | Active WebSocket connection | 🟢 Green dot |
| `failed` | Max reconnect attempts reached | 🔴 Red dot |

## Usage

### Singleton Instance

```swift
let wsManager = WebSocketManager.shared
```

### Connect/Disconnect

```swift
// Connect (automatically called on app launch)
wsManager.connect()

// Disconnect (automatically called on app quit)
wsManager.disconnect()
```

### Send Chat Message

```swift
wsManager.sendChatMessage(
    content: "What's the weather today?",
    sessionId: "main"
)
```

### Load Chat History

```swift
wsManager.loadChatHistory(
    sessionId: "main",
    limit: 50
)
```

### Create Task (via chat)

```swift
// Tasks are created via chat messages for now
wsManager.createTask(
    title: "Research competitors",
    priority: .high
)
// Sends: "Create task: Research competitors (priority: high)"
```

### Handle Incoming Messages

```swift
wsManager.onMessageReceived = { message in
    // Handle chat message
    print("Received: \(message.payload?.content ?? "")")
}

wsManager.onTaskUpdate = { taskUpdate in
    // Handle task update
    print("Task \(taskUpdate.type): \(taskUpdate.taskId)")
}
```

## Error Handling

### Connection Errors

The WebSocket manager automatically handles:
- Network interruptions (auto-reconnect)
- Timeout errors (retry with backoff)
- Gateway restarts (reconnect when available)

### Message Errors

- Invalid JSON → Logged and ignored
- Unknown message types → Logged for debugging
- Missing required fields → Graceful degradation

## Implementation Details

### URLSession WebSocket

Using native `URLSessionWebSocketTask` (no external dependencies):
- Lightweight, built into Foundation
- Automatic connection management
- Binary and text message support

### Gateway Protocol Compliance

The Mac app implements the official Clawdbot Gateway RPC protocol:
- Challenge-response handshake (`connect.challenge` → `connect`)
- Request/response pattern with unique IDs
- Event subscriptions (`chat`, `task.*`, etc.)
- Protocol version negotiation (currently v1)

### Thread Safety

All UI updates are dispatched to the main queue:
```swift
DispatchQueue.main.async {
    // Update SwiftUI state
}
```

### Observable State

The `WebSocketManager` uses Swift's `@Observable` macro:
- Views automatically update when connection state changes
- No manual Combine publishers needed

### Request Tracking

Pending requests are tracked by ID:
```swift
private var pendingRequests: [String: (Bool, Any?, GatewayError?) -> Void] = [:]
```

Responses are matched to requests via the `id` field.

## Testing

### Manual Testing

1. Start Clawdbot Gateway: `clawdbot gateway start`
2. Launch Mac app
3. Check connection status indicator (should show green dot)
4. Send a chat message → should receive response
5. Create a task → should appear in Kanban board

### Connection Loss Testing

1. Stop gateway: `clawdbot gateway stop`
2. App should show "Disconnected" and attempt reconnect
3. Restart gateway: `clawdbot gateway start`
4. App should reconnect automatically and show "Connected"

## Next Steps

### Mac App
- [x] Implement gateway protocol handshake
- [x] Integrate `chat.send` RPC method
- [x] Handle `chat` events for responses
- [ ] Load chat history on startup (`chat.history`)
- [ ] Parse and display full message history
- [ ] Handle multi-session switching (tabs)
- [ ] Implement file attachments (`attachments` param)
- [ ] Add offline queue (send when reconnected)

### Gateway (Future)
- [ ] Add dedicated task RPC methods (`task.create`, `task.update`, `task.list`)
- [ ] Broadcast task events (`task.created`, `task.progress`, `task.completed`)
- [ ] Natural language task detection ("research X" → auto-create task)
- [ ] Task-to-message linking
- [ ] Multi-client task sync (Mac app ↔ Telegram ↔ CLI)

## Debugging

Enable verbose logging:
```swift
// In WebSocketManager.swift, uncomment debug logs:
print("📨 Sent: \(jsonString)")
print("📬 Received: \(text)")
```

Check gateway logs:
```bash
clawdbot gateway logs
```

Verify WebSocket endpoint is running:
```bash
curl --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     --header "Sec-WebSocket-Version: 13" \
     http://127.0.0.1:18790
```
