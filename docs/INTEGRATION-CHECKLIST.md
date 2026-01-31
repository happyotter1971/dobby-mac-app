# WebSocket Integration Checklist

## ✅ Completed

### Core Infrastructure
- [x] Created `WebSocketManager.swift` with full connection management
- [x] Implemented **official Clawdbot Gateway RPC protocol**
- [x] Challenge-response handshake (`connect.challenge` → `connect`)
- [x] Request/response pattern with ID tracking
- [x] Event handling (`chat` events for AI responses)
- [x] Added auto-reconnect with exponential backoff
- [x] Connection state tracking (disconnected → connecting → connected → failed)
- [x] Thread-safe message handling (main queue dispatch)

### Chat Integration
- [x] Updated `ChatView` to use WebSocket for sending messages
- [x] Integrated `chat.send` RPC method
- [x] Added handler for `chat` events (AI responses)
- [x] Connection status indicator in chat UI
- [x] Disabled send button when disconnected
- [ ] Load chat history on startup (`chat.history`)
- [ ] Display full conversation history
- [ ] Parse rich message content (markdown, code blocks)

### Task Integration
- [x] Updated `TasksView` for local task management (SwiftData)
- [x] Task creation sends notification via chat
- [x] Task updates tracked locally
- [ ] Gateway-side task RPC methods (future)
- [ ] Incoming task events from gateway (future)
- [ ] Real-time task progress tracking (future)

### App Lifecycle
- [x] Auto-connect on app launch
- [x] Clean disconnect on app quit
- [x] Keep-alive ping every 30 seconds

## 🚧 To Test

### Manual Testing
- [ ] Start Clawdbot Gateway (`clawdbot gateway start`)
- [ ] Launch Mac app and verify connection (green dot)
- [ ] Send chat message "What's 2+2?" and verify response
- [ ] Check console logs for protocol handshake
- [ ] Send multiple messages and verify all responses arrive
- [ ] Create task manually in app (stays local for now)
- [ ] Stop gateway and verify auto-reconnect attempts
- [ ] Restart gateway and verify reconnection succeeds
- [ ] Test with existing Telegram/CLI sessions (multi-client)

### Edge Cases
- [ ] App starts before gateway is running (should retry)
- [ ] Gateway crashes during conversation (should reconnect)
- [ ] Network interruption (should handle gracefully)
- [ ] Multiple message types arriving quickly
- [ ] Large message content (markdown, code blocks)

## 📊 Current Status

**Mac App: Ready for Testing** ✅
- WebSocket client using **official gateway protocol**
- Challenge-response handshake implemented
- `chat.send` RPC integration complete
- `chat` event handling for AI responses
- UI integrated with connection status
- Task management (local SwiftData, chat-based sync)

**Gateway: Already Supports This!** ✅
- Existing WebSocket RPC endpoint at `ws://127.0.0.1:18789`
- `chat.send` method works out of the box
- `chat` events broadcast to all connected clients
- Multi-client support (Telegram, CLI, Control UI, **+ Mac app**)
- Session management (main, research, etc.)

**What's Left:**
- Test with real gateway (should work immediately!)
- Load chat history on startup
- Display full conversation in UI
- (Future) Add dedicated task RPC methods to gateway

## 🎯 Next Phase: Testing & Polish

1. **Test with real gateway** (30 min)
   - Start gateway, launch Mac app
   - Verify handshake and chat.send works
   - Send messages and verify responses
   
2. **Load chat history** (1-2 hours)
   - Call `chat.history` on connect
   - Display existing messages in UI
   - Parse message content properly
   
3. **Polish chat UI** (2-3 hours)
   - Markdown rendering
   - Code block syntax highlighting
   - Auto-scroll to bottom
   - Typing indicators (if desired)

4. **Task enhancements** (future)
   - Gateway-side task persistence
   - Natural language task detection
   - Task event broadcasting
