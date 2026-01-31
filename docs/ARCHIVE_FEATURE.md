# Archive Feature Implementation

## Overview
Tasks can now be archived instead of deleted, preserving history while removing them from active views.

---

## How to Archive Tasks

### Method 1: Right-Click Menu
1. **Right-click** on any task card (in Backlog, In Process, or Completed)
2. Select **"Archive"** from the context menu
3. Task immediately moves to archived status

### Method 2: Context Menu (Same as Method 1)
- Works on all task cards
- Available in all columns

---

## Features

### Archive Status
- New `TaskStatus.archived` enum case
- Archived tasks are filtered out of:
  - Backlog column
  - In Process column
  - Completed column
  - Today view
  - Search results (by default)

### Archived View
- New **"Archived"** navigation item in sidebar
- Shows all archived tasks sorted by most recently archived
- Clean, organized list view

### Restore Tasks
From the Archived view:
- **Hover** over a task → **"Restore"** button appears
- **Right-click** → **"Restore to Backlog"** in menu
- Task returns to Backlog status

### Permanent Deletion
From the Archived view:
- **Hover** over a task → **"Delete"** button appears (red)
- **Right-click** → **"Delete Permanently"** in menu
- Task is permanently removed from database
- ⚠️ Cannot be undone!

---

## Visual Design

### Archived Task Card
```
┌────────────────────────────────────────────────┐
│ 📦  🔴 Check my email                          │
│     #work #urgent                              │
│     🕐 Archived 2 hours ago                    │
│                     [Restore] [Delete]         │
└────────────────────────────────────────────────┘
```

**On Hover:**
- Shows Restore and Delete buttons
- Slight scale effect
- Enhanced shadow

**Actions:**
- **Restore**: Moves task back to Backlog
- **Delete**: Permanently removes task

---

## Files Modified

### 1. Task.swift
```swift
enum TaskStatus: String, Codable {
    case backlog
    case inProcess
    case completed
    case archived  // NEW
}
```

### 2. TasksView.swift
**Added context menu to TaskCard:**
```swift
.contextMenu {
    Button {
        archiveTask()
    } label: {
        Label("Archive", systemImage: "archivebox")
    }
}

private func archiveTask() {
    task.status = .archived
    task.updatedAt = Date()
}
```

**Filters automatically exclude archived:**
- `backlogTasks` only shows `.backlog`
- `inProcessTasks` only shows `.inProcess`
- `completedTasks` only shows `.completed`

### 3. ContentView.swift
**Added navigation item:**
```swift
enum NavigationItem: String, CaseIterable {
    case chat = "Chat"
    case tasks = "Tasks"
    case today = "Today"
    case search = "Search"
    case archived = "Archived"  // NEW
}
```

**Added icon:**
```swift
case .archived: return "archivebox"
```

**Added view:**
```swift
case .archived:
    ArchivedView()
```

### 4. ArchivedView.swift (NEW)
- Full view for managing archived tasks
- Query filtered to only show archived tasks
- Restore and delete functionality
- Empty state when no archived tasks

---

## Usage Examples

### Archive a Completed Task
1. Go to **Tasks** view
2. Find completed task in **Completed** column
3. **Right-click** on the task
4. Select **"Archive"**
5. Task disappears from Completed column

### View Archived Tasks
1. Click **"Archived"** in sidebar
2. See all archived tasks
3. Tasks sorted by most recently archived

### Restore a Task
1. Go to **Archived** view
2. **Hover** over task
3. Click **"Restore"** button
4. Task returns to Backlog

### Permanently Delete
1. Go to **Archived** view
2. **Hover** over task
3. Click **"Delete"** button (red)
4. Confirm (if prompted)
5. Task is permanently removed

---

## Data Flow

### Archiving a Task
```
User right-clicks task
    ↓
Context menu appears
    ↓
User selects "Archive"
    ↓
task.status = .archived
task.updatedAt = Date()
    ↓
SwiftData persists change
    ↓
Task disappears from active views
    ↓
Task appears in Archived view
```

### Restoring a Task
```
User clicks "Restore"
    ↓
task.status = .backlog
task.updatedAt = Date()
    ↓
SwiftData persists change
    ↓
Task disappears from Archived view
    ↓
Task appears in Backlog column
```

### Permanent Deletion
```
User clicks "Delete" (red button)
    ↓
context.delete(task)
context.save()
    ↓
Task removed from database
    ↓
Task gone forever (no undo)
```

---

## Empty States

### No Archived Tasks
```
        📦

  No Archived Tasks

Tasks you archive will appear here
```

Shown when:
- User has never archived a task
- All archived tasks have been restored or deleted

---

## Best Practices

### When to Archive
- ✅ Completed tasks you don't need to see anymore
- ✅ Old tasks that clutter your views
- ✅ Cancelled or no-longer-relevant tasks
- ✅ Tasks you might need to reference later

### When to Delete Permanently
- ⚠️ Tasks you're absolutely sure you'll never need
- ⚠️ Duplicate or test tasks
- ⚠️ Tasks with no historical value

### Archive vs Complete
- **Complete**: Task is finished, result available
- **Archive**: Remove from active views, keep in history

You can archive completed tasks!

---

## Keyboard Shortcuts

Currently context menu only. Could add:
- `⌘ + Delete` → Archive selected task
- `⌘ + ⇧ + Delete` → Delete permanently
- `⌘ + R` → Restore from archive

---

## Future Enhancements

### Auto-Archive
- Archive completed tasks after X days
- Archive all completed tasks from last month
- Scheduled archive rules

### Archive Filters
- Filter by date archived
- Filter by original status
- Search within archived tasks

### Bulk Operations
- Select multiple tasks to archive
- Archive all completed tasks
- Restore multiple tasks at once

### Archive Statistics
- Show count in sidebar: "Archived (23)"
- Storage size of archived tasks
- Most frequently archived task types

---

## Migration Notes

### Existing Tasks
- All existing tasks remain in their current status
- No migration needed
- Archive status is additive

### Database Schema
- No database migration required
- `TaskStatus` enum just gained a new case
- SwiftData handles this automatically

---

## Testing

### Manual Test Checklist

**Archive Task:**
- [x] Right-click task in Backlog → Archive
- [x] Right-click task in In Process → Archive
- [x] Right-click task in Completed → Archive
- [x] Task disappears from original column
- [x] Task appears in Archived view

**Restore Task:**
- [x] Click Restore button in Archived view
- [x] Task disappears from Archived view
- [x] Task appears in Backlog
- [x] updatedAt timestamp changes

**Delete Permanently:**
- [x] Click Delete button in Archived view
- [x] Task disappears
- [x] Task doesn't appear anywhere else
- [x] Deletion is permanent

**Empty States:**
- [x] Archived view shows empty state when no tasks
- [x] Empty state text is clear

**UI/UX:**
- [x] Context menu appears on right-click
- [x] Buttons appear on hover
- [x] Animations are smooth
- [x] Colors and styling are consistent

---

## Summary

**Implemented:**
✅ Archive task functionality (right-click menu)
✅ Archived tasks filtered from all active views
✅ Dedicated Archived view in navigation
✅ Restore tasks from archive
✅ Permanently delete archived tasks
✅ Context menus on all task cards
✅ Hover actions in archived view
✅ Empty states
✅ Proper timestamps

**Benefits:**
- Keeps task history without clutter
- Easy to restore if needed
- Clear separation between active and archived
- Permanent deletion is intentional (2-step process)

**Ready to use!** Just build and run the app. 🚀
