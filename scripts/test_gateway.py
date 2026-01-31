#!/usr/bin/env python3
"""
Minimal Test Gateway for Dobby Mac App
Tests task.execute RPC method with mock responses
"""

import asyncio
import websockets
import json
from datetime import datetime

print("""
╔════════════════════════════════════════════════════════════╗
║          Dobby Mac App - Test Gateway                      ║
║                                                             ║
║  This gateway simulates task execution for testing         ║
╚════════════════════════════════════════════════════════════╝
""")

# Track connected clients
connected_clients = set()

async def handle_connection(websocket, path):
    """Handle WebSocket connection from Dobby Mac App."""
    client_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
    connected_clients.add(websocket)

    print(f"\n{'='*60}")
    print(f"📱 [{timestamp()}] App connected from {client_id}")
    print(f"{'='*60}\n")

    try:
        async for message in websocket:
            await handle_message(message, websocket)
    except websockets.exceptions.ConnectionClosed:
        print(f"\n📴 [{timestamp()}] App disconnected: {client_id}")
    finally:
        connected_clients.remove(websocket)


async def handle_message(message, websocket):
    """Handle incoming message from the app."""
    try:
        data = json.loads(message)
        msg_type = data.get("type")

        # Log received message
        print(f"\n📥 [{timestamp()}] RECEIVED:")
        print(f"   Type: {msg_type}")

        if msg_type == "req":
            method = data.get("method")
            print(f"   Method: {method}")
            await handle_rpc_request(data, websocket)
        else:
            print(f"   Data: {json.dumps(data, indent=2)[:200]}...")

    except json.JSONDecodeError as e:
        print(f"❌ [{timestamp()}] Invalid JSON: {e}")
    except Exception as e:
        print(f"❌ [{timestamp()}] Error handling message: {e}")


async def handle_rpc_request(request, websocket):
    """Handle RPC requests from the app."""
    method = request.get("method")
    params = request.get("params", {})
    request_id = request.get("id")

    if method == "connect":
        await handle_connect(request_id, params, websocket)

    elif method == "task.execute":
        await handle_task_execute(request_id, params, websocket)

    elif method == "chat.send":
        await handle_chat_send(request_id, params, websocket)

    elif method == "chat.history":
        await handle_chat_history(request_id, params, websocket)

    else:
        print(f"⚠️  [{timestamp()}] Unknown method: {method}")
        await send_error_response(
            request_id,
            "unknown_method",
            f"Method '{method}' not supported",
            websocket
        )


async def handle_connect(request_id, params, websocket):
    """Handle connect handshake."""
    print(f"🤝 [{timestamp()}] Connection handshake")
    print(f"   Client: {params.get('client', {}).get('displayName', 'Unknown')}")

    # First send challenge (if needed)
    # For this test, we'll just accept the connection

    response = {
        "type": "res",
        "id": request_id,
        "ok": True,
        "result": {
            "protocol": 3,
            "serverVersion": "test-1.0.0"
        }
    }

    await websocket.send(json.dumps(response))
    print(f"✅ [{timestamp()}] Connection accepted")


async def handle_task_execute(request_id, params, websocket):
    """Handle task.execute RPC method - THE MAIN TEST!"""
    task_id = params.get("taskId")
    title = params.get("title", "Unknown task")

    print(f"\n{'*'*60}")
    print(f"🚀 [{timestamp()}] TASK EXECUTION STARTED")
    print(f"   Task ID: {task_id}")
    print(f"   Title: {title}")
    print(f"{'*'*60}")

    # 1. Send immediate success response
    response = {
        "type": "res",
        "id": request_id,
        "ok": True,
        "result": {
            "started": True,
            "timestamp": datetime.now().isoformat()
        }
    }

    await websocket.send(json.dumps(response))
    print(f"✅ [{timestamp()}] Sent success response to app")

    # 2. Start background execution
    asyncio.create_task(execute_task_async(task_id, title, websocket))


async def execute_task_async(task_id, title, websocket):
    """Execute the task asynchronously with progress updates."""

    try:
        # Simulate task execution with progress updates
        print(f"\n📊 [{timestamp()}] Starting task execution...")

        # Initial progress (0%)
        await send_task_progress(task_id, 0, websocket)
        await asyncio.sleep(1)

        # Progress 25%
        print(f"📊 [{timestamp()}] Task progress: 25%")
        await send_task_progress(task_id, 25, websocket)
        await asyncio.sleep(1)

        # Progress 50%
        print(f"📊 [{timestamp()}] Task progress: 50%")
        await send_task_progress(task_id, 50, websocket)
        await asyncio.sleep(1)

        # Progress 75%
        print(f"📊 [{timestamp()}] Task progress: 75%")
        await send_task_progress(task_id, 75, websocket)
        await asyncio.sleep(1)

        # Generate mock result based on task title
        result = generate_mock_result(title)

        # Send completion
        print(f"\n{'='*60}")
        print(f"✅ [{timestamp()}] TASK COMPLETED")
        print(f"   Task: {title}")
        print(f"   Result length: {len(result)} characters")
        print(f"{'='*60}\n")

        await send_task_completed(task_id, result, websocket)

    except Exception as e:
        print(f"❌ [{timestamp()}] Task execution failed: {e}")
        await send_task_completed(
            task_id,
            f"Task failed: {str(e)}",
            websocket
        )


def generate_mock_result(title):
    """Generate mock result based on task title."""
    title_lower = title.lower()

    if "email" in title_lower:
        return """You have 3 new emails:

1. From: boss@company.com
   Subject: Q4 Planning Meeting Tomorrow
   Preview: Hi team, please review the attached agenda for our quarterly planning session. We'll be discussing budget allocations and strategic initiatives...

2. From: notifications@github.com
   Subject: [dobby-mac-app] New pull request #42
   Preview: @coworker opened a new pull request: "Add drag-and-drop task execution". This PR implements the task execution flow with visual indicators...

3. From: newsletter@techdigest.com
   Subject: Weekly Tech Digest - AI Agents Edition
   Preview: Top stories this week: Apple announces new AI features, Claude releases Sonnet 4.5, breakthrough in autonomous agents...

All emails have been marked as read. Would you like me to summarize any specific email in detail?"""

    elif "research" in title_lower or "openshift" in title_lower:
        return """Red Hat OpenShift Research Summary
=====================================

**Overview:**
Red Hat OpenShift is an enterprise Kubernetes container platform that provides a complete container application platform for deploying and managing containerized applications.

**Key Features:**
• Enterprise-grade Kubernetes with additional tooling
• Built-in CI/CD with Jenkins and Tekton pipelines
• Integrated container registry
• Developer-friendly workflows and CLI
• Multi-cloud and hybrid cloud support
• Advanced security and compliance features

**Pricing:**
• OpenShift Online: Free tier available, paid plans from $50/month
• OpenShift Dedicated: Starting at $48,000/year
• OpenShift Container Platform: Custom enterprise pricing

**Use Cases:**
• Microservices architecture
• Cloud-native application development
• Hybrid cloud deployments
• DevOps automation

**Recommendation:**
Excellent choice for enterprises requiring production-grade container orchestration with support and compliance guarantees. Overkill for small projects or startups."""

    elif "bug" in title_lower or "debug" in title_lower or "fix" in title_lower:
        return """Bug Investigation Complete
=========================

**Issue Identified:**
Login timeout occurring after 5 seconds on slow networks.

**Root Cause:**
The Redis session store timeout was set too aggressively at 5 seconds, causing sessions to expire before authentication could complete on slower connections.

**Solution Applied:**
1. Updated config/redis.js timeout from 5s to 30s
2. Added exponential backoff retry logic (3 attempts)
3. Implemented connection health monitoring
4. Added detailed logging for timeout events

**Files Modified:**
• config/redis.js (timeout configuration)
• middleware/session.js (retry logic)
• utils/logger.js (timeout logging)

**Testing:**
✅ Verified fix with simulated slow network (500ms latency)
✅ Confirmed sessions persist through authentication flow
✅ Checked logs show retry attempts working correctly

**Status:** Bug fixed and deployed to staging. Ready for production."""

    elif "create" in title_lower or "write" in title_lower:
        return f"""Task Completed: {title}
{'='*50}

I've completed the requested work. Here's a summary:

**What was created:**
• Implemented core functionality as requested
• Added comprehensive error handling
• Included unit tests (95% coverage)
• Updated documentation

**Files created/modified:**
• src/main.js (new feature implementation)
• tests/main.test.js (test coverage)
• docs/README.md (usage documentation)

**Next steps:**
• Review the implementation
• Run the test suite
• Deploy to staging for QA

Let me know if you need any adjustments or have questions!"""

    else:
        # Generic task result
        return f"""Task Completed: {title}
{'='*50}

I've successfully completed the task. Here's what was done:

**Summary:**
The requested work has been completed according to specifications.

**Details:**
• Analyzed the requirements
• Implemented the solution
• Tested functionality
• Verified results

**Outcome:**
✅ Task completed successfully
✅ All tests passing
✅ Ready for review

**Notes:**
This is a mock result from the test gateway. In production, this would contain actual work output from your AI agent.

If you have any questions or need modifications, let me know!"""


async def send_task_progress(task_id, progress, websocket):
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
    print(f"📤 [{timestamp()}] Sent progress: {progress}%")


async def send_task_completed(task_id, result_summary, websocket):
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
    print(f"📤 [{timestamp()}] Sent completion event")


async def handle_chat_send(request_id, params, websocket):
    """Handle chat.send method."""
    message = params.get("message", "")
    session_key = params.get("sessionKey", "main")

    print(f"💬 [{timestamp()}] Chat message: {message[:100]}...")

    # Send success response
    response = {
        "type": "res",
        "id": request_id,
        "ok": True,
        "result": {
            "messageId": f"msg-{datetime.now().timestamp()}"
        }
    }

    await websocket.send(json.dumps(response))

    # Send mock chat response
    await asyncio.sleep(0.5)

    chat_event = {
        "type": "event",
        "event": "chat",
        "payload": {
            "state": "final",
            "sessionKey": session_key,
            "message": {
                "role": "assistant",
                "content": [
                    {
                        "type": "text",
                        "text": f"Hello! I received your message: '{message}'. This is a test response from the mock gateway."
                    }
                ]
            }
        }
    }

    await websocket.send(json.dumps(chat_event))
    print(f"📤 [{timestamp()}] Sent chat response")


async def handle_chat_history(request_id, params, websocket):
    """Handle chat.history method."""
    session_key = params.get("sessionKey", "main")
    limit = params.get("limit", 50)

    print(f"📚 [{timestamp()}] Loading chat history (session: {session_key}, limit: {limit})")

    response = {
        "type": "res",
        "id": request_id,
        "ok": True,
        "result": {
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": "Hello"}],
                    "timestamp": (datetime.now().timestamp() - 3600)
                },
                {
                    "role": "assistant",
                    "content": [{"type": "text", "text": "Hi! How can I help you today?"}],
                    "timestamp": (datetime.now().timestamp() - 3590)
                }
            ]
        }
    }

    await websocket.send(json.dumps(response))
    print(f"📤 [{timestamp()}] Sent chat history")


async def send_error_response(request_id, code, message, websocket):
    """Send error response."""
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
    print(f"❌ [{timestamp()}] Sent error: {code} - {message}")


def timestamp():
    """Get formatted timestamp."""
    return datetime.now().strftime("%H:%M:%S")


async def main():
    """Start the test gateway server."""
    host = "127.0.0.1"
    port = 18790  # Using 18790 to avoid conflict with real gateway

    print(f"🚀 Starting test gateway on ws://{host}:{port}")
    print(f"⏰ Started at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    print("=" * 60)
    print("READY TO TEST!")
    print("=" * 60)
    print("\n👉 Instructions:")
    print("   1. Open Dobby Mac App")
    print("   2. Create a task (e.g., 'check my email')")
    print("   3. Drag the task to 'In Process' column")
    print("   4. Watch the magic happen!\n")
    print("📊 You should see:")
    print("   • Blue 'Executing...' badge with progress")
    print("   • Progress bar filling up (0% → 25% → 50% → 75%)")
    print("   • Task completing and moving to 'Completed'")
    print("   • Green 'View Result' badge appearing")
    print("   • Click task to see the result summary\n")
    print("=" * 60)

    async with websockets.serve(handle_connection, host, port):
        print(f"\n✅ Gateway is running and waiting for connections...")
        print(f"   Press Ctrl+C to stop\n")
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 60)
        print("🛑 Gateway stopped by user")
        print("=" * 60)
