# Task Execution Visual Indicators

## Overview
Added comprehensive visual feedback to show when Clawdbot is actively executing a task.

---

## Visual Indicators

### 1. **Execution Badge** (Top of Card)
**Location:** Top of task card, above title
**Appearance:**
- 🔵 Blue "Executing..." text with spinning progress indicator
- Shows progress percentage if available (e.g., "42%")
- Pulsing animation (opacity fades in/out smoothly)

**Example:**
```
┌─────────────────────────────┐
│ ⚙️ Executing... 42%          │  ← Pulsing blue badge
│ 🔴 Implement authentication │
│ #backend #security          │
└─────────────────────────────┘
```

---

### 2. **Progress Bar** (Bottom of Card)
**Location:** Bottom of task card, after timestamp
**Appearance:**
- Horizontal blue progress bar
- Shows actual percentage from `task.progressPercent`
- Only visible when progress > 0%

**Example:**
```
┌─────────────────────────────┐
│ 🔴 Implement authentication │
│ Created 2 hours ago         │
│ ████████░░░░░░░░░░ 42%      │  ← Progress bar
└─────────────────────────────┘
```

---

### 3. **Border Highlight**
**Location:** Card border/outline
**Appearance:**
- Border changes from gray to **blue** when executing
- Border thickness increases from 1pt to 2pt
- Blue has 50% opacity for subtle effect

**Before (Not Executing):**
```
┌─────────────────────────────┐  ← Thin gray border
│ 🔴 Task in backlog          │
└─────────────────────────────┘
```

**After (Executing):**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ← Thicker blue border
┃ ⚙️ Executing... 42%          ┃
┃ 🔴 Implement authentication ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

### 4. **Background Glow**
**Location:** Card background
**Appearance:**
- Subtle blue tint overlay (5% opacity)
- Creates a gentle "active" glow effect
- Combines with existing card background

**Visual Effect:**
- Non-executing: Standard window background color
- Executing: Window background + subtle blue glow

---

### 5. **Animated Pulsing**
**Animation Details:**
- Badge background opacity pulses: 15% ↔ 25%
- Duration: 1 second cycle
- Smooth ease-in-out animation
- Repeats continuously while executing

---

## Implementation Logic

### Execution Detection
A task is considered "executing" when:
```swift
task.status == .inProcess && (task.progressPercent ?? 0) < 100
```

**Conditions:**
1. Task status must be `inProcess` (in the "In Process" column)
2. Progress must be less than 100% (or nil)

**Not executing when:**
- Task is in Backlog (status = `.backlog`)
- Task is Completed (status = `.completed`)
- Task progress = 100% (execution finished, awaiting completion)

---

## State Flow

### When Task Starts Executing
```
User drags task to "In Process"
    ↓
Task status → .inProcess
    ↓
Gateway sends EXECUTE_TASK command
    ↓
Gateway responds with task.progress events
    ↓
task.progressPercent updates (e.g., 0%, 15%, 42%, 75%)
    ↓
Visual indicators appear on card
```

### When Task Finishes
```
Gateway sends task.completed event
    ↓
task.status → .completed
task.progressPercent → 100
    ↓
Visual indicators disappear
    ↓
Card moves to "Completed" column
```

---

## Visual States Comparison

### State 1: Backlog (Not Started)
```
┌─────────────────────────────┐
│ 🔴 Implement authentication │  ← No indicators
│ #backend #security          │
│ Created 2 hours ago         │
└─────────────────────────────┘
```

### State 2: Executing (0% Progress)
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ⚙️ Executing...              ┃  ← Badge, no % yet
┃ 🔴 Implement authentication ┃  ← Blue border + glow
┃ #backend #security          ┃
┃ Created 2 hours ago         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### State 3: Executing (42% Progress)
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ⚙️ Executing... 42%          ┃  ← Badge with %
┃ 🔴 Implement authentication ┃  ← Blue border + glow
┃ #backend #security          ┃
┃ Created 2 hours ago         ┃
┃ ████████░░░░░░░░░░ 42%      ┃  ← Progress bar
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### State 4: Completed
```
┌─────────────────────────────┐
│ 🔴 Implement authentication │  ← No indicators
│ ✅ Completed 5 minutes ago  │
└─────────────────────────────┘
```

---

## Code Structure

### Key Components

**1. Execution Detection:**
```swift
private var isExecuting: Bool {
    task.status == .inProcess && (task.progressPercent ?? 0) < 100
}
```

**2. Execution Badge:**
```swift
if isExecuting {
    HStack(spacing: 6) {
        ProgressView()           // Spinning indicator
        Text("Executing...")
        if let progress = task.progressPercent {
            Text("\(progress)%")
        }
    }
    .background(Color.blue.opacity(pulseAnimation ? 0.25 : 0.15))
    .animation(.easeInOut(duration: 1.0).repeatForever())
}
```

**3. Progress Bar:**
```swift
if isExecuting, let progress = task.progressPercent, progress > 0 {
    GeometryReader { geometry in
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue.opacity(0.2))  // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)               // Progress
                .frame(width: geometry.size.width * CGFloat(progress) / 100.0)
        }
    }
    .frame(height: 4)
}
```

**4. Border & Glow:**
```swift
.background(
    ZStack {
        Color(.windowBackgroundColor)
        if isExecuting {
            Color.blue.opacity(0.05)  // Glow effect
        }
    }
)
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(
            isExecuting ? Color.blue.opacity(0.5) : Color(.separatorColor),
            lineWidth: isExecuting ? 2 : 1
        )
)
```

---

## Gateway Integration

### Expected Gateway Behavior

**Progress Updates:**
The Gateway should send `task.progress` events with increasing percentages:

```json
{
  "type": "event",
  "event": "task.progress",
  "payload": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "inProcess",
    "progress": 42
  }
}
```

**Completion:**
When task finishes, send `task.completed` event:

```json
{
  "type": "event",
  "event": "task.completed",
  "payload": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "resultSummary": "Successfully implemented authentication system"
  }
}
```

---

## Testing

### Manual Testing Steps

1. **Create a test task** in Backlog
   - Verify: No execution indicators visible

2. **Drag task to "In Process"**
   - Verify: "Executing..." badge appears immediately
   - Verify: Blue border appears
   - Verify: Background has subtle blue glow
   - Verify: Badge pulses (opacity animation)

3. **Simulate progress updates** (from Gateway)
   - Send `task.progress` event with `progress: 25`
   - Verify: Badge shows "Executing... 25%"
   - Verify: Progress bar appears showing 25%

4. **Simulate more progress**
   - Send `task.progress` event with `progress: 75`
   - Verify: Badge shows "Executing... 75%"
   - Verify: Progress bar fills to 75%

5. **Complete the task** (from Gateway)
   - Send `task.completed` event
   - Verify: All indicators disappear
   - Verify: Task moves to "Completed" column

### Automated Testing Scenarios

**Scenario 1: No Progress Updates**
- Task moved to In Process
- Gateway doesn't send progress events
- Expected: Badge shows "Executing..." without percentage
- Expected: No progress bar (since progress = nil or 0)

**Scenario 2: Rapid Progress Updates**
- Gateway sends progress: 0%, 20%, 40%, 60%, 80%, 100%
- Expected: Progress bar smoothly animates between values
- Expected: Percentage updates in badge

**Scenario 3: Task Stuck at 99%**
- Task progress reaches 99% but doesn't complete
- Expected: Indicators remain visible
- Expected: Task stays in "In Process" column

**Scenario 4: Manual Status Change**
- User manually drags executing task back to Backlog
- Expected: Indicators immediately disappear
- Expected: Execution continues on Gateway (status sync)

---

## Edge Cases Handled

1. **Nil Progress**
   - Badge shows "Executing..." without percentage
   - No progress bar displayed

2. **Zero Progress**
   - Badge shows "Executing..." without percentage
   - No progress bar displayed (progress > 0 check)

3. **100% Progress**
   - Considered "not executing" (awaiting completion event)
   - Indicators disappear

4. **Status Changed Externally**
   - If task.status changes to `.completed` or `.backlog`
   - Indicators automatically hide (reactive to state)

5. **Multiple Tasks Executing**
   - Each task independently shows its own indicators
   - No interference between tasks

---

## Performance Considerations

### Animation Performance
- Pulsing animation uses `.repeatForever(autoreverses: true)`
- Lightweight opacity animation (GPU-accelerated)
- No performance impact with multiple executing tasks

### Reactive Updates
- All indicators react to `@Bindable var task: Task`
- SwiftUI automatically updates when `progressPercent` changes
- No manual refresh needed

### Memory Usage
- Minimal overhead: one `@State var pulseAnimation` per card
- Animation automatically stops when card removed from view

---

## Accessibility

### VoiceOver Support
Consider adding accessibility labels:

```swift
.accessibilityLabel(isExecuting ? "Task executing at \(task.progressPercent ?? 0) percent" : task.title)
```

### Reduced Motion
For users with reduced motion preferences, disable pulsing:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// In animation:
.animation(reduceMotion ? .none : .easeInOut(duration: 1.0).repeatForever())
```

---

## Future Enhancements

### Potential Improvements

1. **Estimated Time Remaining**
   - Show "~5 min remaining" based on progress rate
   - Requires tracking progress velocity

2. **Execution Phase Labels**
   - "Analyzing...", "Building...", "Testing...", "Deploying..."
   - Gateway would send current phase in progress events

3. **Error State Indicators**
   - Red border and error icon if task fails
   - Retry button overlay

4. **Pause/Resume Controls**
   - Pause button overlay on executing tasks
   - Send pause command to Gateway

5. **Execution Log Preview**
   - Expandable section showing recent logs
   - Click badge to show/hide logs

6. **Multi-Step Progress**
   - Segmented progress bar for multi-phase tasks
   - Show which steps are complete/in-progress/pending

7. **Execution History**
   - Track all execution attempts
   - Show previous failures/successes

8. **Sound Effects**
   - Completion sound when task finishes
   - Optional sound for progress milestones (25%, 50%, 75%)

---

## Summary

**Visual Indicators Added:**
✅ Pulsing "Executing..." badge with spinner
✅ Progress percentage display
✅ Animated progress bar
✅ Blue border highlight
✅ Subtle background glow
✅ All indicators reactive to task state
✅ Smooth animations and transitions

**User Benefits:**
- Immediate feedback when execution starts
- Clear progress visibility
- Easy to distinguish executing tasks from idle tasks
- Professional, polished appearance
- Non-intrusive visual design

**Developer Benefits:**
- Simple boolean check (`isExecuting`)
- Automatic state management via SwiftUI reactivity
- No manual UI updates needed
- Easy to extend with additional indicators
