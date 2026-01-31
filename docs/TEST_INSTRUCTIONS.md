# Test Instructions - Task Execution

## Quick Test (5 Minutes)

### Step 1: Install Dependencies

```bash
cd /Users/dobbyott/clawd/dobby-mac-app
pip3 install websockets
```

### Step 2: Start Test Gateway

```bash
python3 test_gateway.py
```

You should see:
```
╔════════════════════════════════════════════════════════════╗
║          Dobby Mac App - Test Gateway                      ║
╚════════════════════════════════════════════════════════════╝

🚀 Starting test gateway on ws://127.0.0.1:18789
⏰ Started at 2026-01-30 15:30:00

============================================================
READY TO TEST!
============================================================

✅ Gateway is running and waiting for connections...
   Press Ctrl+C to stop
```

### Step 3: Test in the App

1. **Open Dobby Mac App** (build and run from Xcode)

2. **Create a test task** or use your existing "check my email" task

3. **Drag the task to "In Process"** column

4. **Watch what happens:**
   - ⚙️ Blue "Executing..." badge appears immediately
   - 📊 Progress shows: 0% → 25% → 50% → 75%
   - 📊 Progress bar fills up smoothly
   - ✅ After ~4 seconds, task completes
   - 📄 Green "View Result" badge appears
   - 📋 Task moves to "Completed" column

5. **Click on the completed task**
   - Task Detail Sheet opens
   - Scroll to "Result" section
   - See the mock email summary (or other result based on task title)

### Step 4: Verify in Logs

**Gateway Console:**
```
📱 [15:30:15] App connected from 127.0.0.1:52847

📥 [15:30:20] RECEIVED:
   Type: req
   Method: task.execute

************************************************************
🚀 [15:30:20] TASK EXECUTION STARTED
   Task ID: 550e8400-e29b-41d4-a716-446655440000
   Title: check my email
************************************************************

✅ [15:30:20] Sent success response to app

📊 [15:30:20] Starting task execution...
📤 [15:30:20] Sent progress: 0%
📊 [15:30:21] Task progress: 25%
📤 [15:30:21] Sent progress: 25%
📊 [15:30:22] Task progress: 50%
📤 [15:30:22] Sent progress: 50%
📊 [15:30:23] Task progress: 75%
📤 [15:30:23] Sent progress: 75%

============================================================
✅ [15:30:24] TASK COMPLETED
   Task: check my email
   Result length: 687 characters
============================================================

📤 [15:30:24] Sent completion event
```

**App Console (Xcode):**
```
🚀 Executing task: check my email
📤 SENDING [task.execute]: {"type":"req","method":"task.execute"...}
✅ Message sent successfully: task.execute
✅ Task execution started: check my email
📥 RECEIVED: {"type":"event","event":"task.progress"...}
📥 RECEIVED: {"type":"event","event":"task.completed"...}
```

---

## Mock Results by Task Type

The test gateway generates different mock results based on task title:

### Email Tasks
**Trigger:** Task title contains "email"
**Result:** Mock email summary with 3 emails

### Research Tasks
**Trigger:** Task title contains "research" or "openshift"
**Result:** Mock research summary about OpenShift

### Bug Fix Tasks
**Trigger:** Task title contains "bug", "debug", or "fix"
**Result:** Mock bug investigation report

### Other Tasks
**Result:** Generic completion summary

---

## Troubleshooting

### Gateway won't start
**Error:** `ModuleNotFoundError: No module named 'websockets'`
**Fix:**
```bash
pip3 install websockets
```

### App won't connect
**Check:**
1. Gateway is running on port 18789
2. No other service using that port
3. App is running and connection status shows "Connected"

**Verify port is available:**
```bash
lsof -i :18789
```

### No execution happens
**Check:**
1. Gateway console shows "App connected"
2. Dragging task triggers RECEIVED message in gateway
3. Check Xcode console for errors

### Progress not updating
**Check:**
1. Gateway shows "Sent progress: X%" messages
2. App receives events (📥 RECEIVED in console)
3. Task status is "inProcess"

---

## Testing Different Scenarios

### Test 1: Email Task
```
Task Title: "check my email"
Expected Result: Email summary with 3 mock emails
```

### Test 2: Research Task
```
Task Title: "research Red Hat OpenShift"
Expected Result: Detailed OpenShift research summary
```

### Test 3: Bug Fix Task
```
Task Title: "debug login timeout issue"
Expected Result: Bug investigation report
```

### Test 4: Generic Task
```
Task Title: "analyze quarterly sales data"
Expected Result: Generic completion message
```

---

## What Success Looks Like

✅ **Gateway starts without errors**
✅ **App connects to gateway** ("App connected" in gateway log)
✅ **Dragging task triggers execution** (gateway receives task.execute)
✅ **Progress updates appear** (0% → 25% → 50% → 75%)
✅ **Progress bar fills** in the app UI
✅ **Task completes** and moves to Completed column
✅ **Green "View Result" badge appears**
✅ **Clicking task shows result** in detail sheet

---

## Next Steps After Successful Test

Once the test works:

1. ✅ You've verified the app → gateway integration works
2. ✅ You've seen the full execution flow
3. ✅ You understand the message protocol

Now implement in your real Gateway:
- Add `task.execute` RPC handler
- Implement actual task execution logic (AI, automation, etc.)
- Send real progress updates
- Return actual results

See **GATEWAY_TASK_EXECUTION.md** for production implementation guide.

---

## Stop the Test Gateway

Press **Ctrl+C** in the terminal:

```
^C

============================================================
🛑 Gateway stopped by user
============================================================
```

---

## Clean Up

The test gateway doesn't create any files or persist any data. Simply stop it when done testing.

To run again:
```bash
python3 test_gateway.py
```
