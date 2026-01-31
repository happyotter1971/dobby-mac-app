# "View Result" Badge Implementation

## Overview
Added a visual badge to completed tasks that have results, making it obvious when a task has output to view.

---

## Visual Design

### Badge Appearance
- **Icon**: 📄 Document icon (`doc.text.fill`)
- **Text**: "View Result"
- **Arrow**: Right chevron indicating clickability
- **Color**: Green (success/completion color)
- **Background**: Light green tint (15% opacity)
- **Shape**: Rounded capsule

### Example
```
┌─────────────────────────────┐
│ 📄 View Result ›            │  ← Green badge
│ 🔴 Check my email           │
│ ✅ Completed 2 minutes ago  │
└─────────────────────────────┘
```

---

## When Badge Appears

### Conditions
The badge is visible when **both** conditions are met:
1. `task.status == .completed` - Task is in Completed column
2. `task.resultSummary != nil` - Task has a result from Clawdbot

### Examples

**✅ Badge Shows:**
- "Check my email" - Completed with email summary
- "Research OpenShift" - Completed with research findings
- "Debug login issue" - Completed with solution description

**❌ Badge Hidden:**
- Tasks in Backlog (not completed yet)
- Tasks In Process (still executing)
- Completed tasks with no result (manual tasks)

---

## User Flow

### 1. Task Completes with Result
```
Gateway sends task.completed event
    ↓
resultSummary = "You have 3 new emails..."
    ↓
Task moves to Completed column
    ↓
Green "View Result" badge appears
```

### 2. User Views Result
```
User sees green badge on task card
    ↓
User clicks anywhere on task card
    ↓
Task Detail Sheet opens
    ↓
Scrolls to "Result" section
    ↓
Sees full resultSummary text
```

---

## Visual States

### Executing Task (Blue Badge)
```
┌─────────────────────────────┐
│ ⚙️ Executing... 75%          │  ← Blue, pulsing
│ 🔴 Check my email           │
│ ████████████████░░░░ 75%    │
└─────────────────────────────┘
```

### Completed Task (Green Badge)
```
┌─────────────────────────────┐
│ 📄 View Result ›            │  ← Green, static
│ 🔴 Check my email           │
│ ✅ Completed 2 minutes ago  │
└─────────────────────────────┘
```

### Completed Task (No Result)
```
┌─────────────────────────────┐
│ 🔴 Update documentation     │  ← No badge
│ ✅ Completed 1 hour ago     │
└─────────────────────────────┘
```

---

## Implementation Details

### Code Location
**File:** `/Users/dobbyott/clawd/dobby-mac-app/DobbyApp/Views/TasksView.swift`
**Lines:** 249-264

### Implementation
```swift
// Result available badge
if task.status == .completed, task.resultSummary != nil {
    HStack(spacing: 6) {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 10))
        Text("View Result")
            .font(.caption2.bold())
        Image(systemName: "chevron.right")
            .font(.system(size: 8))
    }
    .foregroundStyle(.green)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.green.opacity(0.15))
    .clipShape(Capsule())
}
```

### Design Choices

**Green Color:**
- Indicates successful completion
- Differentiates from blue "Executing" badge
- Positive, actionable color

**Document Icon:**
- Clearly represents "content/output available"
- Familiar metaphor for results/reports

**Chevron Arrow:**
- Suggests interactivity
- Visual affordance for "click to view"

**Static (No Animation):**
- Completed state is calm, not urgent
- Contrasts with pulsing execution badge

---

## Badge Hierarchy

### Priority Order (Top to Bottom)
1. **Executing Badge** (Blue) - Most urgent, task is active
2. **View Result Badge** (Green) - Action available, view output
3. **Priority Emoji** - Task importance level
4. **Title** - Task description

### Visual Separation
- 8pt spacing between badges and title
- Badges are smaller (caption2 font)
- Title is larger and bolder for hierarchy

---

## Example Use Cases

### Email Checking
**Task:** "Check my email"
**Result:**
```
You have 3 new emails:

1. From: boss@company.com
   Subject: Q4 Planning Meeting
   Preview: Please review the attached agenda...

2. From: notifications@github.com
   Subject: New PR requires review
   Preview: @coworker opened pull request #123...

3. From: newsletter@tech.com
   Subject: Weekly Tech Digest
   Preview: Top stories this week...
```

**Badge:** ✅ Shows "View Result" badge
**User Action:** Clicks task → sees full email list in Result section

---

### Research Task
**Task:** "Research Red Hat OpenShift"
**Result:**
```
Red Hat OpenShift is an enterprise Kubernetes platform.

Key Features:
- Enterprise-grade container orchestration
- Built-in CI/CD pipelines
- Multi-cloud support
- Developer-friendly workflows

Pricing: Starts at $50/month per cluster

Recommendation: Good fit for enterprise deployments
requiring compliance and support.
```

**Badge:** ✅ Shows "View Result" badge
**User Action:** Clicks task → sees research summary

---

### Bug Fix Task
**Task:** "Debug login timeout issue"
**Result:**
```
Issue identified: Redis session store timeout set to 5 seconds.

Root Cause: Default timeout too aggressive for slow networks.

Solution Applied:
- Increased timeout to 30 seconds in config/redis.js
- Added retry logic with exponential backoff
- Added logging for timeout events

Testing: Verified fix works with simulated slow network.
```

**Badge:** ✅ Shows "View Result" badge
**User Action:** Clicks task → sees debugging report

---

## Accessibility

### Screen Reader Support
Current: Badge reads "View Result chevron right"

**Potential Improvement:**
```swift
.accessibilityLabel("View task result. Tap to open details.")
.accessibilityHint("Opens task details showing the execution result")
```

### Keyboard Navigation
- Task cards are already tappable
- Badge inherits card tap gesture
- No separate interaction needed

---

## Testing

### Manual Test Steps

1. **Create task** "Check my email" in Backlog
   - Verify: No badge visible

2. **Drag to In Process**
   - Verify: Blue "Executing..." badge appears
   - Verify: Green "View Result" badge NOT visible

3. **Simulate completion** (Gateway sends task.completed)
   ```json
   {
     "type": "event",
     "event": "task.completed",
     "payload": {
       "taskId": "550e8400-...",
       "resultSummary": "You have 3 new emails..."
     }
   }
   ```
   - Verify: Blue "Executing..." badge disappears
   - Verify: Green "View Result" badge appears
   - Verify: Task moves to Completed column

4. **Click the task**
   - Verify: Task Detail Sheet opens
   - Verify: "Result" section visible with summary
   - Verify: Full resultSummary text displayed

5. **Create manual task** and mark complete (no result)
   - Verify: No "View Result" badge appears
   - Verify: Task shows completion status only

---

## Edge Cases

### 1. Empty Result Summary
If `resultSummary = ""` (empty string):
- Badge still appears (string is not nil)
- **Potential Fix:** Check for non-empty string
  ```swift
  if task.status == .completed,
     let result = task.resultSummary,
     !result.trimmingCharacters(in: .whitespaces).isEmpty {
      // Show badge
  }
  ```

### 2. Very Long Results
- Badge doesn't show result length
- Detail sheet handles scrolling automatically
- Consider: Show preview length ("View Result (2,340 chars)")

### 3. Result Updates
If Gateway sends updated result after completion:
- Badge remains visible
- Detail sheet shows latest result
- No notification of update (consider toast)

### 4. Manual Status Change
If user manually changes status to Completed:
- Badge only appears if resultSummary exists
- Usually won't exist for manual completions

---

## Future Enhancements

### 1. Result Preview Tooltip
Hover over badge to see first 100 characters:
```swift
.help(String(task.resultSummary?.prefix(100) ?? ""))
```

### 2. Badge Click Handler
Make badge directly open to Result section:
```swift
.onTapGesture {
    selectedTask = task
    // Scroll to Result section
}
```

### 3. Result Type Icons
Different icons for different result types:
- 📧 Email results
- 📊 Data/Reports
- 🐛 Bug fixes
- 📝 Research

### 4. Quick View Popover
Click badge to show popover with result preview:
```swift
.popover(isPresented: $showResultPreview) {
    ScrollView {
        Text(task.resultSummary ?? "")
            .padding()
    }
    .frame(width: 400, height: 300)
}
```

### 5. Copy Result Button
Quick copy button on badge:
```swift
Button(action: { copyToClipboard(task.resultSummary) }) {
    Image(systemName: "doc.on.doc")
}
```

---

## Summary

**Implemented:**
✅ Green "View Result" badge on completed tasks
✅ Shows only when resultSummary exists
✅ Clear visual indicator with icon and text
✅ Matches existing badge design system
✅ No additional clicks required (card tap works)

**User Benefits:**
- Immediate visibility of available results
- Clear call-to-action ("View Result")
- Distinguishes completed tasks with/without output
- Consistent with execution badge design

**Next Steps:**
- Test with real Gateway completion events
- Consider adding tooltip preview
- Monitor user interaction patterns
- Iterate based on feedback
