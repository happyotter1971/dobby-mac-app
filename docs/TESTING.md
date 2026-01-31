# Testing Guide

## Quick Start

### 1. Start the Gateway

```bash
clawdbot gateway start
```

Verify it's running:
```bash
clawdbot gateway status
```

Should show:
```
Runtime: running (pid XXXX, state active)
Listening: 127.0.0.1:18789
```

### 2. Open Xcode

```bash
cd dobby-mac-app
open DobbyApp.xcodeproj
```

### 3. Build & Run

- Press **⌘R** or click the ▶️ Play button
- The app should launch and display the main window
- Check the console for connection logs:

**Expected logs:**
```
🔌 Connecting to Clawdbot Gateway at ws://127.0.0.1:18789
✅ Connected to Clawdbot Gateway
```

### 4. Test Chat

1. Click **Chat** in the sidebar (should be selected by default)
2. Look for the connection status indicator in the top-right:
   - **🟢 Green dot** = Connected
   - **🟡 Yellow dot** = Connecting
   - **🔴 Gray/Red dot** = Disconnected
3. Type a message in the input field: "What's 2+2?"
4. Press **Enter** or click the send button
5. Watch for the response from Dobby

**What to expect:**
- Your message appears immediately in the chat
- After ~2-5 seconds, Dobby's response appears
- Connection status stays green

### 5. Test Task Management

1. Click **Tasks** in the sidebar
2. Click **[+ New Task]** button
3. Fill in:
   - Title: "Test task"
   - Priority: Medium
   - Notes: (optional)
4. Click **Create**
5. Task should appear in the **📝 BACKLOG** column

**Note:** Tasks are stored locally (SwiftData) for now. Syncing with gateway is coming in a future update.

### 6. Test Reconnection

1. Stop the gateway:
   ```bash
   clawdbot gateway stop
   ```
2. Watch the connection status indicator turn **gray** (Disconnected)
3. The app should automatically attempt to reconnect
4. Restart the gateway:
   ```bash
   clawdbot gateway start
   ```
5. Within a few seconds, the app should reconnect (green dot)

## Troubleshooting

### App won't connect

**Check gateway is running:**
```bash
clawdbot gateway status
```

If not running:
```bash
clawdbot gateway start
```

**Check WebSocket endpoint:**
```bash
curl --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Sec-WebSocket-Key: test" \
     --header "Sec-WebSocket-Version: 13" \
     http://127.0.0.1:18789
```

Should return HTTP 101 (Switching Protocols).

**Check Xcode console for errors:**
- Look for "❌" error messages
- Common issues:
  - "Connection refused" = Gateway not running
  - "Protocol mismatch" = Wrong endpoint or format

### Messages not sending

- Verify green connection dot in UI
- Check Xcode console for send errors
- Try restarting the app
- Verify gateway is processing messages:
  ```bash
  clawdbot gateway logs
  ```

### Tasks not appearing

- Tasks are local-only right now
- They're stored in SwiftData (on your Mac)
- Check for SwiftData errors in console
- Try quitting and relaunching the app

## Console Logs

### Good Connection Flow

```
🚀 Connecting to Clawdbot Gateway...
🔌 Connecting to Clawdbot Gateway at ws://127.0.0.1:18789
📨 Event: connect.challenge
✅ Connected to Clawdbot Gateway
✅ Chat message sent
📨 Event: chat
```

### Failed Connection

```
🚀 Connecting to Clawdbot Gateway...
🔌 Connecting to Clawdbot Gateway at ws://127.0.0.1:18789
❌ WebSocket error: Connection refused
❌ Disconnected from gateway
🔄 Reconnecting... (attempt 1/5)
```

### Normal Chat Flow

```
✅ Chat message sent
📨 Event: chat
```

## Gateway Logs

Monitor gateway activity:
```bash
tail -f /tmp/clawdbot/clawdbot-$(date +%Y-%m-%d).log
```

Or use the built-in viewer:
```bash
clawdbot gateway logs
```

Look for:
```
[ws-control] webchat connected conn=...
[chat] chat.send sessionKey=main message=...
[chat] agent run started runId=...
```

## Testing Checklist

- [ ] Gateway starts successfully
- [ ] Mac app connects (green dot)
- [ ] Can send chat messages
- [ ] Receive AI responses
- [ ] Connection survives gateway restart
- [ ] Can create tasks manually
- [ ] Tasks persist after app restart
- [ ] Multiple messages work correctly
- [ ] Long messages display properly

## Known Issues

1. **Chat history not loading** - Need to implement `chat.history` call on startup
2. **Tasks are local-only** - Not syncing with gateway yet (future feature)
3. **No markdown rendering** - Messages display as plain text (future feature)
4. **No message persistence** - App doesn't save/load chat history locally (future feature)

## Next Testing Targets

Once basic chat works:
1. Load chat history on startup
2. Test with parallel sessions (Telegram + Mac app)
3. Test long-running conversations
4. Test file attachments (future)
5. Test voice input (future)

## Success Criteria

✅ **MVP Ready** when:
- App connects to gateway reliably
- Can send messages and receive responses
- Connection auto-recovers from failures
- Tasks can be created and managed locally
- UI is responsive and stable

## Feedback

If you hit issues or have suggestions, add them here:

### Issues Found
- (none yet)

### Improvements Needed
- (TBD after testing)
