# Dobby Mac App — Design Document

**Status:** Design phase — not yet built  
**Date:** January 30, 2026  
**Purpose:** Native Mac interface for Clawdbot interaction (complement to Telegram)  
**Technology Decision:** ✅ Swift + SwiftUI (Mac-only for now)

---

## 1. Design Philosophy

### Core Principles
- **Fast access** — Menu bar resident, always one click away
- **Native feel** — Mac-first design (not a web wrapper)
- **Power user focused** — Keyboard shortcuts, quick actions, rich content
- **Seamless** — Shares same backend as Telegram (unified history)

### Why Build This?
Telegram is great for mobile/on-the-go, but when you're at your desk:
- Native Mac experience (drag/drop, keyboard shortcuts, system integration)
- Richer UI (better for long docs, code, tables, visualizations)
- Voice integration (push-to-talk, always listening mode)
- Desktop-specific features (screen capture, file handling, notifications)
- Multi-session/split view for complex work

---

## 2. Interface Design

### A. Main Window Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [≡] Dobby                    [Sessions ▾] [⚙︎] [−] [□] [×]  │ ← Title bar
├─────────────────┬───────────────────────────────────────────┤
│                 │ ┌───────────────────────────────────────┐ │
│  SIDEBAR        │ │ Main  Research  Strategy  [+]        │ │ ← Session tabs
│                 │ └───────────────────────────────────────┘ │
│  💬 Chat        │                                           │
│  ✅ Tasks (3)   │  ┌─────────────────────────────────────┐ │
│  📋 Today       │  │ User message bubble                │ │
│  📅 Calendar    │  └─────────────────────────────────────┘ │
│  📧 Email       │                                           │
│  📊 Dashboard   │  ┌─────────────────────────────────────┐ │
│  🔍 Search      │  │ 🤖 Dobby response                   │ │
│                 │  │ With formatted content:              │ │
│  ─────────────  │  │ • Code blocks                       │ │
│                 │  │ • Tables                            │ │
│  Sessions:      │  │ • Rich markdown                     │ │
│  • Main         │  └─────────────────────────────────────┘ │
│  • Research     │                                           │
│  • Strategy     │  ┌─────────────────────────────────────┐ │
│                 │  │ [🎤] Type or speak...              │ │
│                 │  └─────────────────────────────────────┘ │
└─────────────────┴───────────────────────────────────────────┘
```

### B. Menu Bar Mode

**Menu Bar Icon:** 🤖 (persistent, always visible)

Click → Quick dropdown:
```
┌─────────────────────────────┐
│ 🤖 Dobby                    │
├─────────────────────────────┤
│ 🎤 Ask Dobby...             │  ← Click to type/speak
├─────────────────────────────┤
│ 📧 3 unread emails          │  ← Glanceable info
│ 📅 Next: 2pm - Meeting      │
│ ⏰ Reminder: Call John      │
├─────────────────────────────┤
│ Open Main Window        ⌘D  │
│ Quick Command          ⌘⇧D  │
│ Voice Mode              ⌥D  │
├─────────────────────────────┤
│ Settings...                 │
│ Quit                        │
└─────────────────────────────┘
```

### C. Quick Command Palette (⌘K style)

Press `⌘⇧D` anywhere on Mac:
```
┌───────────────────────────────────────────┐
│  ⌘ Quick Command                          │
├───────────────────────────────────────────┤
│  > check email_                           │
├───────────────────────────────────────────┤
│  💡 Suggestions:                          │
│  📧 Check unread emails                   │
│  📅 What's on my calendar today?          │
│  📊 Show dashboard                        │
│  🔍 Search past conversations             │
│  ⚙️  Open settings                        │
└───────────────────────────────────────────┘
```

### D. Task Tracker View

Click **✅ Tasks** in sidebar → Kanban-style board:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Tasks                                            [+ New Task] [Filter▾] │
├───────────────────┬─────────────────────┬─────────────────────────────┤
│   📝 BACKLOG (5)  │  🚧 IN PROCESS (3)  │   ✅ COMPLETED (12)         │
├───────────────────┼─────────────────────┼─────────────────────────────┤
│                   │                     │                             │
│ ┌───────────────┐ │ ┌───────────────┐   │ ┌───────────────┐           │
│ │🔴 Research IBM│ │ │🟠 Draft Lin...│   │ │ Morning email │           │
│ │ Turbonomic    │ │ │ AI post       │   │ │ scan          │           │
│ │               │ │ │               │   │ │ ✓ Done 9:15am │           │
│ │ 🤖 Created by │ │ │ 🤖 In progress│   │ └───────────────┘           │
│ │    Dobby      │ │ │    45 min ago │   │                             │
│ └───────────────┘ │ └───────────────┘   │ ┌───────────────┐           │
│                   │                     │ │ Calendar prep │           │
│ ┌───────────────┐ │ ┌───────────────┐   │ │ for Friday    │           │
│ │🟢 Find case   │ │ │🔴 Weather wid.│   │ │ ✓ Done 10:05am│           │
│ │ studies for   │ │ │ research      │   │ └───────────────┘           │
│ │ proposal      │ │ │               │   │                             │
│ │               │ │ │ 🤖 Working... │   │ [Show More...]              │
│ │ 👤 You added  │ │ └───────────────┘   │                             │
│ └───────────────┘ │                     │                             │
│                   │ ┌───────────────┐   │                             │
│ [+]               │ │🟠 Update MEM..│   │                             │
│                   │ │ with Dec work │   │                             │
│                   │ │               │   │                             │
│                   │ │ 🤖 Reviewing  │   │                             │
│                   │ └───────────────┘   │                             │
└───────────────────┴─────────────────────┴─────────────────────────────┘

🔴 High Priority  🟠 Medium Priority  🟢 Low Priority
```

**Task Card Details:**
- **Priority indicator** — 🔴 High, 🟠 Medium, 🟢 Low
- **Title** — Brief description
- **Status indicator** — 🤖 (Dobby working), 👤 (user created), ⏱️ (waiting)
- **Timestamp** — When created/started/completed
- **Source** — Created from chat, manual, or automated
- **Click to expand** — Show full context, messages, results

**Task Interactions:**
- **Drag & drop** between columns to change status
- **Click task** → See details + related chat messages
- **+ New Task** → Manually add tasks
- **Filter** → By source (me/you), priority, date, type
- **Click priority dot** → Change priority (cycles High → Med → Low)

**Smart Features:**
- **Auto-created from chat:** "Research IBM Turbonomic" → task appears
- **Progress tracking:** Dobby updates status as it works
- **Linked to conversations:** Click task → jump to related messages
- **Completion reports:** "Here's what I found..." + mark complete

---

## 3. Feature Set

### Core Features (MVP)
| Feature | Description | Why Better Than Telegram |
|---------|-------------|--------------------------|
| **Native Chat** | Full conversation interface | Faster, richer formatting |
| **Task Tracker** | Kanban board (Backlog → In Process → Completed) | Visual task management, not just chat |
| **Voice Input** | Wispr Flow integration (external app) | Best-in-class dictation, already installed |
| **File Drag & Drop** | Drop files directly into chat | Easier than Telegram upload |
| **Rich Content** | Code, tables, markdown, images | Better rendering than Telegram |
| **Menu Bar Access** | Always one click away | Faster than opening Telegram |
| **Keyboard Shortcuts** | ⌘K command palette, quick actions | Power user efficiency |
| **Notifications** | Native Mac notifications | More control than Telegram |

### Advanced Features (Phase 2)
| Feature | Description | Value |
|---------|-------------|-------|
| **Smart Task Creation** | Auto-create tasks from conversations ("research X") | Zero-friction task capture |
| **Task Progress Updates** | Real-time status as Dobby works | Transparency into AI work |
| **Task Context Linking** | Click task → see related chat messages | Trace task history |
| **Task Priorities** | High/Medium/Low with color coding | Visual importance ranking |
| **Task Templates** | Pre-defined task types (research, draft, analyze) | Consistency |
| **Multi-Session Tabs** | Multiple AI conversations side-by-side | Compare outputs, parallel work |
| **Task Sync** | Tasks visible in Telegram too (read-only) | Cross-platform visibility |
| **Screen Capture** | Built-in screenshot/recording | "Analyze this screen" |
| **Voice Output** | TTS responses (optional) | Hands-free mode |
| **Quick Notes** | Scratchpad that Dobby can see | Shared context |
| **Calendar/Email View** | Integrated panels | Don't leave the app |
| **Dashboard Widgets** | Glanceable status (emails, calendar, reminders) | Proactive awareness |
| **Search & History** | Full-text search across all conversations | Find past context fast |
| **Custom Commands** | User-defined shortcuts | "morning brief", "eod summary" |

### Desktop-Specific Advantages
- **System Integration:** Access Mac services (calendar, contacts, files)
- **Clipboard Integration:** Paste images, code, formatted text
- **Drag & Drop:** Files, URLs, screenshots directly into chat
- **Global Shortcuts:** Trigger from any app (⌘⇧D)
- **Native Notifications:** Better control, actionable alerts
- **Multi-Monitor:** Persistent on second screen
- **Screen Sharing:** Share screen context with Dobby
- **Local File Access:** Work with local files directly

---

## 4. Technology Stack

### ✅ **Swift + SwiftUI** (Chosen)

**Why:**
- True native Mac app (fast, lightweight, Mac-like)
- Access to all macOS APIs (notifications, shortcuts, screen capture)
- Best performance and battery life
- Beautiful native UI components
- Small binary size (~5-10MB)
- Professional, polished result

**Stack:**
- **Frontend:** SwiftUI (native Mac UI)
- **Backend API:** WebSocket to Clawdbot gateway (ws://127.0.0.1:18789)
- **Data persistence:** SwiftData (for tasks, settings, cache)
- **Voice:** Integration with Wispr Flow (external app, already installed)
- **Notifications:** UserNotifications framework
- **File handling:** NSDocument, drag & drop APIs
- **Networking:** URLSession + Starscream (WebSocket)

**Task Management:**
- **Storage:** Local SwiftData database (synced to gateway)
- **Real-time sync:** WebSocket events for task updates
- **Data model:**
  ```swift
  @Model
  class Task {
      var id: UUID
      var title: String
      var status: TaskStatus // .backlog, .inProcess, .completed
      var createdAt: Date
      var updatedAt: Date
      var source: TaskSource // .dobby, .user, .auto
      var linkedMessageIds: [String]
      var notes: String?
  }
  ```

---

## 5. Implementation Plan

### Phase 0: Design Validation (Now)
- Review this document with Bill
- Decide on tech stack
- Prioritize features (MVP vs nice-to-have)
- Sketch wireframes if needed

### Phase 1: MVP (2-3 weeks)
**Core functionality:**
1. Native Swift app setup (Xcode project, basic structure)
2. Menu bar icon + quick dropdown
3. Main window with sidebar navigation
4. Chat interface (text only, basic markdown)
5. WebSocket connection to Clawdbot gateway
6. **Task tracker UI** (Kanban board with 3 columns)
7. **Task CRUD** (create, read, update, delete tasks)
8. **Manual task management** (drag & drop between columns)
9. Basic notifications
10. Keyboard shortcuts (⌘D open, ⌘K command palette)

**Deliverable:** Working app with chat + basic task management

### Phase 2: Enhanced UX (1-2 weeks)
11. **Task priorities** (High/Medium/Low with color indicators)
12. **Smart task creation** (auto-create from conversations with trigger detection)
13. **Task-message linking** (click task → see related chat)
14. **Multi-session tabs** (parallel conversations, easy switching)
15. **Wispr Flow integration** (focus text field → Wispr Flow works automatically)
16. File drag & drop
17. Rich markdown/code rendering (syntax highlighting)
18. Settings panel (preferences, task filters, notification rules)

**Deliverable:** Intelligent task tracking + enhanced chat

### Phase 3: Power Features (2-3 weeks)
19. **Task sync to Telegram** (WebSocket events, read-only view on mobile)
20. **Task progress updates** (real-time Dobby status with %)
21. **Task templates** (pre-defined task types)
22. Screen capture integration
23. Calendar/email panels
24. Dashboard widgets
25. Custom commands ("morning brief", "eod summary")
26. Search & history (chat + tasks, full-text)
27. Voice output (TTS for responses, optional)

**Deliverable:** Full productivity powerhouse

### Phase 4: Polish & Distribution (1 week)
18. App icon, branding
19. Onboarding flow
20. Auto-updates
21. Notarization (Mac App Store or direct download)

**Deliverable:** Shippable product

---

## 6. User Flows

### Flow A: Quick Question (Menu Bar)
1. Click 🤖 in menu bar
2. Type question (or click 🎤 for voice)
3. Get response inline (or "Open full window")
4. Done — menu closes

**Time:** 5 seconds

---

### Flow B: Deep Work Session (Main Window)
1. Open app (⌘D or Dock)
2. Start conversation
3. Drag files into chat for analysis
4. Split screen: email panel + chat
5. Ask followup questions
6. Save important context to notes

**Time:** 30+ minutes of flow state

---

### Flow C: Proactive Alert
1. Dobby notices important email
2. Mac notification appears: "🤖 Urgent from John - contract deadline"
3. Click → opens app with email summary
4. Ask Dobby to draft response
5. Review, approve, send

**Time:** 2 minutes vs 10 minutes manual

---

### Flow D: Task Management
1. **In chat:** "Research IBM Turbonomic pricing"
2. Dobby responds: "Starting research..." + task auto-created in Backlog
3. Click **✅ Tasks** in sidebar → see task in "In Process" column
4. Task shows: 🤖 Working... with live progress
5. 10 minutes later: Task moves to "Completed" with results
6. Click task → see full research report + linked messages

**Time:** Zero overhead — tasks tracked automatically

---

### Flow E: Manual Task Tracking
1. Open Tasks view
2. Click **[+ New Task]**
3. Add: "Prepare Q1 strategy deck"
4. Drag to "In Process" when you start
5. Ask Dobby: "Help me with the Q1 deck" → task auto-links
6. Mark complete when done

**Time:** 10 seconds to create, always visible status

---

## 7. Architecture

```
┌──────────────────────────────────────────────────────┐
│           Dobby Mac App (Swift + SwiftUI)            │
│                                                      │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌────────┐ │
│  │   UI    │  │  Voice   │  │  Files │  │ Tasks  │ │
│  │(SwiftUI)│  │(Speech)  │  │ (Drag) │  │ (Data) │ │
│  └────┬────┘  └────┬─────┘  └───┬────┘  └───┬────┘ │
│       │            │            │           │      │
│       └────────────┴────────────┴───────────┘      │
│                         │                          │
│                   ┌─────▼──────┐                   │
│                   │ WebSocket  │                   │
│                   │   Client   │                   │
│                   └─────┬──────┘                   │
│                         │                          │
│                   ┌─────▼──────┐                   │
│                   │ SwiftData  │                   │
│                   │   (Local   │                   │
│                   │   Storage) │                   │
│                   └────────────┘                   │
└──────────────────────┼───────────────────────────────┘
                       │
                       │ ws://127.0.0.1:18789
                       │
┌──────────────────────▼───────────────────────────────┐
│          Clawdbot Gateway (Existing)                 │
│                                                      │
│  • Session management                                │
│  • Model routing (Claude/Gemini/OpenRouter)          │
│  • Tool execution (email, calendar, etc.)            │
│  • Memory & history                                  │
│  • Task event broadcasting (NEW)                     │
│  • Telegram channel (parallel interface)             │
└──────────────────────────────────────────────────────┘
```

**Key points:**
- Mac app is a **client** — backend stays the same
- Both Telegram and Mac app talk to same gateway
- **Tasks stored locally** in SwiftData, synced via WebSocket events
- Unified history across all interfaces
- Gateway broadcasts task events (created, updated, completed)
- No duplication of business logic

---

## 8. Design Decisions

1. ~~**Voice:** Always-on ("Hey Dobby") or push-to-talk only?~~ ✅ **Using Wispr Flow** (external)
2. ~~**Notifications:** How aggressive?~~ ✅ **Important only** (urgent emails, deadlines, errors)
3. ~~**Multi-session:** Parallel conversations?~~ ✅ **YES** - tabs for different contexts
4. **Sync:** Should Mac app work if gateway is down? (offline mode for tasks?) — TBD
5. **Distribution:** Mac App Store or direct download? — TBD
6. **Branding:** Keep "Dobby" name or something else for the app? — TBD
7. ~~**Task auto-creation:** Which phrases?~~ ✅ **Conservative triggers** (research, draft, find, analyze, summarize, compare, create)
8. ~~**Task visibility:** Sync to Telegram?~~ ✅ **YES** - sync tasks across all interfaces
9. **Task archiving:** Auto-archive completed tasks after X days? — TBD (suggest 30 days)
10. ~~**Task priorities:** Add levels?~~ ✅ **YES** - High/Medium/Low priority

---

## 9. Estimated Effort

| Phase | Effort | Timeline | Key Deliverables |
|-------|--------|----------|------------------|
| Phase 1 (MVP) | 50-70 hours | 2-3 weeks | Chat + Basic task Kanban |
| Phase 2 (Enhanced) | 30-40 hours | 1-2 weeks | Smart tasks + linking |
| Phase 3 (Power features) | 35-45 hours | 2-3 weeks | Real-time sync + integrations |
| Phase 4 (Polish) | 15-20 hours | 1 week | Branding + distribution |
| **Total** | **130-175 hours** | **6-9 weeks** | Full-featured productivity app |

*Assumes Swift + SwiftUI, part-time development*

**Breakdown by component:**
- **Chat interface:** 25-30 hours
- **Task tracker:** 40-50 hours (Kanban UI, SwiftData, auto-creation, linking)
- **WebSocket integration:** 15-20 hours
- ~~**Voice input:** 10-15 hours~~ ✅ **Removed** (using Wispr Flow)
- **Menu bar + shortcuts:** 10-12 hours
- **Rich content rendering:** 8-10 hours
- **Integrations (calendar/email):** 15-20 hours
- **Polish + testing:** 15-20 hours

**Time saved by using Wispr Flow:** 10-15 hours (no need to build voice input)

---

## 10. Next Steps

**Before building:**
1. ✅ Review this design doc
2. ✅ Decide: Swift + SwiftUI (Mac-only for now)
3. ✅ Add task tracker feature
4. ⬜ Answer open questions (voice, task triggers, etc.)
5. ⬜ Final approval to build

**When ready to build:**
1. Set up Xcode project (Swift + SwiftUI)
2. Build basic app structure:
   - Menu bar icon + dropdown
   - Main window + sidebar navigation
   - WebSocket connection test
3. Prototype Phase 1a: Chat interface (2-3 days)
4. Prototype Phase 1b: Task Kanban board (3-4 days)
5. Show you the working prototype
6. Iterate based on feedback
7. Continue through phases 2-4

**First milestone:** Working chat + manual task management (Week 1-2)

---

## 11. Task Tracker Deep Dive

### A. Data Model

```swift
enum TaskStatus: String, Codable {
    case backlog
    case inProcess
    case completed
}

enum TaskSource: String, Codable {
    case dobby      // Auto-created by AI
    case user       // Manually added
    case automated  // System-generated (e.g., scheduled)
}

enum TaskPriority: String, Codable {
    case high
    case medium
    case low
}

@Model
class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var status: TaskStatus
    var source: TaskSource
    var priority: TaskPriority
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var notes: String?
    var linkedMessageIds: [String]  // Chat messages related to this task
    var progressPercent: Int?       // Optional progress indicator
    var resultSummary: String?      // Completion summary from Dobby
}
```

### B. Task Lifecycle

**1. Creation**
- **From chat:** Natural language detection
  - "Research IBM Turbonomic pricing" → Task created
  - "Draft a LinkedIn post about AI" → Task created
  - "Find 3 case studies for proposal" → Task created
- **Manual:** User clicks [+ New Task]
- **Automated:** Scheduled tasks (morning brief, etc.)

**2. In Progress**
- Dobby updates task with progress messages
- Real-time status via WebSocket
- User can see: "🤖 Analyzing... 45% complete"

**3. Completion**
- Dobby marks complete + adds result summary
- Notification: "✅ Task complete: Research IBM Turbonomic"
- Click to see full results

**4. Archiving**
- Completed tasks visible for X days (configurable)
- Auto-archive or manual archive
- Searchable even when archived

### C. Smart Detection Rules

**Trigger phrases for auto-task creation (conservative start):**
- **Research:** "research [topic]", "look into [topic]", "investigate [topic]"
- **Draft:** "draft [document]", "write [document]", "create draft of [thing]"
- **Find:** "find [X number of] [things]", "get me [X] examples of [thing]"
- **Analyze:** "analyze [thing]", "break down [thing]", "review [thing]"
- **Summarize:** "summarize [document/URL]", "give me the key points from [thing]"
- **Compare:** "compare [A] vs [B]", "what's the difference between [A] and [B]"
- **Create:** "create [deliverable]", "build [thing]", "make [thing]"

**Confidence threshold:** Only create task if >80% confidence it's a work request, not a question.

**Examples that should NOT create tasks:**
- "How do I research X?" (asking for advice, not requesting work)
- "What's the weather?" (simple lookup, not a task)
- "Did you find anything about X?" (follow-up question)

**Priority assignment (auto-created tasks):**
- Default: Medium (🟠)
- User can adjust after creation
- Learn from patterns over time (future enhancement)

### D. UI States

**Task Card States:**
```
┌───────────────┐
│ 🟢 Ready      │ ← Backlog (no active work)
│ 🔵 Working    │ ← In Process (Dobby actively working)
│ 🟡 Waiting    │ ← In Process (waiting for input/dependency)
│ ✅ Done       │ ← Completed
│ ⏸️  Paused    │ ← In Process (user paused)
└───────────────┘
```

### E. WebSocket Events

**From Gateway → Mac App:**
```json
{
  "type": "task.created",
  "taskId": "uuid",
  "title": "Research IBM Turbonomic",
  "source": "dobby",
  "linkedMessages": ["msg123"]
}

{
  "type": "task.progress",
  "taskId": "uuid",
  "status": "inProcess",
  "progress": 45,
  "message": "Found 3 pricing tiers, analyzing..."
}

{
  "type": "task.completed",
  "taskId": "uuid",
  "resultSummary": "Found 3 pricing tiers: Standard ($X), Pro ($Y), Enterprise (custom)...",
  "linkedMessages": ["msg123", "msg124", "msg125"]
}
```

**From Mac App → Gateway:**
```json
{
  "type": "task.create",
  "title": "Prepare Q1 strategy deck",
  "source": "user"
}

{
  "type": "task.update",
  "taskId": "uuid",
  "status": "inProcess"
}
```

### F. Keyboard Shortcuts

- **⌘T** — Open Tasks view
- **⌘N** — New task
- **⌘1/2/3** — Jump to Backlog/In Process/Completed
- **Space** — Quick preview of selected task
- **Enter** — Open task details
- **Delete** — Archive completed task

---

## 12. Why This Is Worth Building

**Problem:** Telegram is mobile-first. You spend most of your day at your desk.

**Solution:** Native Mac app optimized for desktop productivity.

**ROI:**
- **Time saved:** 15-30 min/day (faster access, richer interactions)
- **Better UX:** Native feel, keyboard-first, glanceable info
- **Task visibility:** Always know what I'm working on (no more "what are you doing?")
- **Zero overhead tracking:** Tasks auto-created from conversations
- **New capabilities:** Screen sharing, multi-session, voice, integrations
- **Professionalism:** Feels like a real tool, not just a chat bot

**Task Tracker Value:**
- **Transparency:** See what Dobby is working on in real-time
- **Accountability:** Clear record of requested work vs completed
- **Context:** Jump from task to related conversations instantly
- **Planning:** Backlog shows what's queued up
- **Reporting:** Weekly view of what got done

**Bottom line:** If you use me daily, a native app pays for itself in weeks. The task tracker alone is worth it — finally see what your AI assistant is actually doing.

---

**Ready to discuss?** Let me know what you think and what to adjust before we build.
