# Gateway Task Execution Integration Guide

## Overview
This guide explains how to implement task execution in your Clawdbot Gateway using the new `task.execute` RPC method.

---

## What Changed

### ❌ Old Approach (Chat Message)
```
App sends: "EXECUTE_TASK: 550e8400-... | check my email"
Gateway: Must parse string, no error handling
```

### ✅ New Approach (RPC Method)
```json
App sends: {
  "type": "req",
  "method": "task.execute",
  "params": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "check my email"
  },
  "id": "exec-abc123"
}

Gateway responds: {
  "type": "res",
  "id": "exec-abc123",
  "ok": true,
  "result": {
    "started": true
  }
}
```

---

## Gateway Implementation

### 1. Add RPC Method Handler

**Python Example:**

```python
async def handle_rpc_request(request: dict, websocket):
    """Handle incoming RPC requests from the app."""
    method = request.get("method")
    params = request.get("params", {})
    request_id = request.get("id")

    if method == "task.execute":
        await handle_task_execute(params, request_id, websocket)
    elif method == "chat.send":
        await handle_chat_send(params, request_id, websocket)
    # ... other methods
    else:
        # Unknown method
        await send_error_response(
            request_id,
            code="unknown_method",
            message=f"Method '{method}' not supported",
            websocket
        )
```

---

### 2. Implement Task Execution Handler

```python
async def handle_task_execute(params: dict, request_id: str, websocket):
    """
    Handle task.execute RPC method.

    Params:
        taskId: UUID string of the task
        title: Human-readable task description
    """
    task_id = params.get("taskId")
    title = params.get("title")

    if not task_id or not title:
        await send_error_response(
            request_id,
            code="invalid_params",
            message="Missing taskId or title",
            websocket
        )
        return

    # Send success response immediately
    await send_response(
        request_id,
        ok=True,
        result={"started": True},
        websocket
    )

    # Start task execution in background
    asyncio.create_task(execute_task_async(task_id, title, websocket))


async def execute_task_async(task_id: str, title: str, websocket):
    """
    Execute the task asynchronously and send progress updates.
    """
    try:
        # Send initial progress (0%)
        await send_task_progress(task_id, progress=0, websocket=websocket)

        # Actually perform the task
        result = await perform_task(title)

        # Send progress updates as work progresses
        await send_task_progress(task_id, progress=50, websocket=websocket)

        # More work...
        await send_task_progress(task_id, progress=75, websocket=websocket)

        # Send completion with result
        await send_task_completed(
            task_id,
            result_summary=result,
            websocket=websocket
        )

    except Exception as e:
        # Send error/failure
        await send_task_completed(
            task_id,
            result_summary=f"Task failed: {str(e)}",
            websocket=websocket
        )
```

---

### 3. Task Execution Logic

```python
async def perform_task(title: str) -> str:
    """
    Perform the actual task based on the title.
    This is where your AI/automation logic goes.
    """

    # Simple keyword matching (you'd use AI/LLM here)
    title_lower = title.lower()

    if "email" in title_lower:
        return await check_email()

    elif "research" in title_lower or "find" in title_lower:
        return await do_research(title)

    elif "bug" in title_lower or "debug" in title_lower:
        return await debug_issue(title)

    elif "write" in title_lower or "create" in title_lower:
        return await create_content(title)

    else:
        # Generic task - use AI to figure it out
        return await ai_agent_execute(title)


async def check_email() -> str:
    """Example: Check email and return summary."""
    # This would integrate with actual email API
    emails = await fetch_emails(limit=10)

    summary = f"You have {len(emails)} new emails:\n\n"

    for i, email in enumerate(emails[:5], 1):
        summary += f"{i}. From: {email['from']}\n"
        summary += f"   Subject: {email['subject']}\n"
        summary += f"   Preview: {email['preview'][:100]}...\n\n"

    if len(emails) > 5:
        summary += f"...and {len(emails) - 5} more emails."

    return summary


async def do_research(topic: str) -> str:
    """Example: Research a topic and return findings."""
    # This would use AI/search APIs
    results = await search_web(topic)

    summary = f"Research findings for '{topic}':\n\n"
    summary += "Key points:\n"

    for point in results['key_points']:
        summary += f"- {point}\n"

    summary += f"\n{results['detailed_summary']}"

    return summary
```

---

### 4. Progress Event Helpers

```python
async def send_task_progress(task_id: str, progress: int, websocket):
    """Send task.progress event to the app."""
    event = {
        "type": "event",
        "event": "task.progress",
        "payload": {
            "taskId": task_id,
            "status": "inProcess",
            "progress": progress
        }
    }
    await websocket.send(json.dumps(event))
    print(f"📊 Task {task_id}: {progress}% complete")


async def send_task_completed(task_id: str, result_summary: str, websocket):
    """Send task.completed event to the app."""
    event = {
        "type": "event",
        "event": "task.completed",
        "payload": {
            "taskId": task_id,
            "resultSummary": result_summary
        }
    }
    await websocket.send(json.dumps(event))
    print(f"✅ Task {task_id}: Completed")
```

---

### 5. Response Helpers

```python
async def send_response(request_id: str, ok: bool, result: dict, websocket):
    """Send RPC response."""
    response = {
        "type": "res",
        "id": request_id,
        "ok": ok,
        "result": result
    }
    await websocket.send(json.dumps(response))


async def send_error_response(request_id: str, code: str, message: str, websocket):
    """Send RPC error response."""
    response = {
        "type": "res",
        "id": request_id,
        "ok": False,
        "error": {
            "code": code,
            "message": message
        }
    }
    await websocket.send(json.dumps(response))
```

---

## Message Flow

### Successful Execution

```
1. App → Gateway (RPC Request)
{
  "type": "req",
  "method": "task.execute",
  "params": {
    "taskId": "550e8400-...",
    "title": "check my email"
  },
  "id": "exec-123"
}

2. Gateway → App (RPC Response - immediate)
{
  "type": "res",
  "id": "exec-123",
  "ok": true,
  "result": {
    "started": true
  }
}

3. Gateway → App (Progress Event)
{
  "type": "event",
  "event": "task.progress",
  "payload": {
    "taskId": "550e8400-...",
    "status": "inProcess",
    "progress": 25
  }
}

4. Gateway → App (More Progress)
{
  "type": "event",
  "event": "task.progress",
  "payload": {
    "taskId": "550e8400-...",
    "progress": 50
  }
}

5. Gateway → App (Completion)
{
  "type": "event",
  "event": "task.completed",
  "payload": {
    "taskId": "550e8400-...",
    "resultSummary": "You have 3 new emails..."
  }
}
```

### Error Handling

```
1. App → Gateway (Invalid Request)
{
  "type": "req",
  "method": "task.execute",
  "params": {
    "taskId": null  // Missing task ID
  },
  "id": "exec-456"
}

2. Gateway → App (Error Response)
{
  "type": "res",
  "id": "exec-456",
  "ok": false,
  "error": {
    "code": "invalid_params",
    "message": "Missing taskId or title"
  }
}
```

---

## Testing

### Manual Test with WebSocket Client

**1. Send task.execute request:**
```json
{
  "type": "req",
  "method": "task.execute",
  "params": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "check my email"
  },
  "id": "test-exec-1"
}
```

**2. Verify response:**
```json
{
  "type": "res",
  "id": "test-exec-1",
  "ok": true,
  "result": {
    "started": true
  }
}
```

**3. Verify progress events:**
```json
{
  "type": "event",
  "event": "task.progress",
  "payload": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "progress": 50
  }
}
```

**4. Verify completion:**
```json
{
  "type": "event",
  "event": "task.completed",
  "payload": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "resultSummary": "You have 3 new emails:\n1. From: boss@company.com\n   Subject: Q4 Planning\n\n2. From: github.com\n   Subject: PR #123 review\n\n3. From: newsletter.com\n   Subject: Weekly digest"
  }
}
```

---

## Node.js Example

```javascript
// Handle RPC requests
async function handleRpcRequest(request, ws) {
  const { method, params, id } = request;

  if (method === 'task.execute') {
    await handleTaskExecute(params, id, ws);
  } else if (method === 'chat.send') {
    await handleChatSend(params, id, ws);
  } else {
    sendErrorResponse(id, 'unknown_method', `Unknown method: ${method}`, ws);
  }
}

// Task execution handler
async function handleTaskExecute(params, requestId, ws) {
  const { taskId, title } = params;

  if (!taskId || !title) {
    sendErrorResponse(requestId, 'invalid_params', 'Missing taskId or title', ws);
    return;
  }

  // Send success response
  sendResponse(requestId, true, { started: true }, ws);

  // Execute task in background
  executeTaskAsync(taskId, title, ws);
}

// Async task execution
async function executeTaskAsync(taskId, title, ws) {
  try {
    // Initial progress
    sendTaskProgress(taskId, 0, ws);

    // Perform work
    const result = await performTask(title);

    // Progress updates
    sendTaskProgress(taskId, 50, ws);

    // Complete
    sendTaskCompleted(taskId, result, ws);

  } catch (error) {
    sendTaskCompleted(taskId, `Task failed: ${error.message}`, ws);
  }
}

// Progress helper
function sendTaskProgress(taskId, progress, ws) {
  ws.send(JSON.stringify({
    type: 'event',
    event: 'task.progress',
    payload: {
      taskId,
      status: 'inProcess',
      progress
    }
  }));
}

// Completion helper
function sendTaskCompleted(taskId, resultSummary, ws) {
  ws.send(JSON.stringify({
    type: 'event',
    event: 'task.completed',
    payload: {
      taskId,
      resultSummary
    }
  }));
}
```

---

## Debugging

### App Side (macOS Console)

Look for these logs:

**✅ Success:**
```
🚀 Executing task: check my email
📤 SENDING [task.execute]: {"type":"req","method":"task.execute",...}
✅ Message sent successfully: task.execute
✅ Task execution started: check my email
📬 Received result...
📥 RECEIVED: {"type":"res","id":"...","ok":true,...}
```

**❌ Failure:**
```
🚀 Executing task: check my email
📤 SENDING [task.execute]: ...
❌ Task execution failed: Method not supported
   Task: check my email
   Error code: unknown_method
```

### Gateway Side

Add logging:
```python
@websocket_route
async def handle_websocket(websocket):
    async for message in websocket:
        print(f"📥 RECEIVED: {message}")

        data = json.loads(message)

        if data.get("type") == "req":
            print(f"🔧 RPC Request: {data.get('method')}")
            await handle_rpc_request(data, websocket)
```

---

## AI Integration

For advanced task execution using LLMs:

```python
async def ai_agent_execute(task_title: str) -> str:
    """Use AI to execute arbitrary tasks."""

    # Use Claude, GPT, or your preferred LLM
    response = await ai_client.complete(
        prompt=f"""You are an autonomous AI agent. Execute this task:

Task: {task_title}

Provide a detailed summary of what you did and the results.""",
        max_tokens=2000
    )

    return response.content
```

---

## Summary

### What You Need to Implement

1. ✅ **RPC method handler** for `task.execute`
2. ✅ **Response** with `ok: true` when execution starts
3. ✅ **Progress events** as task executes (optional but recommended)
4. ✅ **Completion event** with `resultSummary`
5. ✅ **Error handling** for invalid requests

### Benefits of This Approach

- **Type-safe**: Structured JSON parameters
- **Error handling**: Know if execution failed to start
- **Asynchronous**: Response immediate, execution in background
- **Extensible**: Easy to add more parameters later
- **Standard**: Follows existing Gateway protocol

### Next Steps

1. Implement the RPC handler in your Gateway
2. Test with the example messages above
3. Move "check my email" task to In Process
4. Verify progress updates appear in the app
5. See the result in the completed task

---

## Quick Start Script

**Minimal Python Gateway (for testing):**

```python
import asyncio
import websockets
import json

async def handle_connection(websocket):
    async for message in websocket:
        data = json.loads(message)

        if data.get("type") == "req" and data.get("method") == "task.execute":
            request_id = data.get("id")
            params = data.get("params", {})
            task_id = params.get("taskId")
            title = params.get("title")

            # Send success response
            await websocket.send(json.dumps({
                "type": "res",
                "id": request_id,
                "ok": True,
                "result": {"started": True}
            }))

            # Simulate work
            await asyncio.sleep(2)

            # Send progress
            await websocket.send(json.dumps({
                "type": "event",
                "event": "task.progress",
                "payload": {"taskId": task_id, "progress": 50}
            }))

            await asyncio.sleep(2)

            # Send completion
            await websocket.send(json.dumps({
                "type": "event",
                "event": "task.completed",
                "payload": {
                    "taskId": task_id,
                    "resultSummary": f"Completed: {title}\n\nThis is a test result."
                }
            }))

async def main():
    async with websockets.serve(handle_connection, "127.0.0.1", 18789):
        print("🚀 Test Gateway running on ws://127.0.0.1:18789")
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
```

Save as `test_gateway.py` and run:
```bash
python test_gateway.py
```

Then drag tasks to In Process in the app!
