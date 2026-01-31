# Xcode Setup Instructions

## Phase 1 MVP - Code Ready!

All Swift files are created in the `DobbyApp/` folder. Now you need to create an Xcode project to build and run the app.

---

## Option 1: Create New Xcode Project (Recommended)

### Step 1: Open Xcode
1. Launch **Xcode**
2. Click **Create New Project**

### Step 2: Configure Project
1. Choose template: **macOS → App**
2. Click **Next**
3. Fill in details:
   - **Product Name:** Dobby
   - **Team:** (select your team)
   - **Organization Identifier:** com.billott
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData
   - Uncheck "Include Tests"
4. Click **Next**
5. Save location: `/Users/dobbyott/clawd/dobby-mac-app/`
6. Click **Create**

### Step 3: Replace Default Files
1. In Xcode, **delete** the default `DobbyApp.swift` and `ContentView.swift` files
2. In Finder, **drag** the entire `DobbyApp` folder into the Xcode project navigator
3. When prompted, choose:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to target: Dobby

### Step 4: Project Settings
1. Select the project in the navigator
2. Go to **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your team

### Step 5: Add Required Capabilities
1. Click **+ Capability**
2. Add **App Sandbox**
3. Under **App Sandbox**, enable:
   - ✅ Outgoing Connections (Client) — for WebSocket
   - ✅ Incoming Connections (Server) — if needed

### Step 6: Build & Run
1. Select **My Mac** as the target
2. Click **Run** (⌘R) or Product → Run
3. The app should launch!

---

## Option 2: Use Claude Code (Faster)

If you have Claude Code (Windsurf) installed:

1. Open Claude Code
2. Open folder: `/Users/dobbyott/clawd/dobby-mac-app/`
3. Ask it: "Create an Xcode project for these Swift files and configure it to build"
4. It will automatically create the `.xcodeproj` file

---

## What You'll See

### Phase 1 MVP Features Working:
- ✅ Menu bar icon (🤖 in top menu bar)
- ✅ Main window with sidebar
- ✅ Chat view (with placeholder messages)
- ✅ Tasks Kanban board (3 columns)
- ✅ Create new tasks
- ✅ Drag tasks between columns
- ✅ Task priorities (🔴🟠🟢)
- ✅ Session tabs (placeholder)
- ✅ Settings window

### Not Yet Working (Phase 2/3):
- WebSocket connection to Clawdbot gateway
- Smart task auto-creation from chat
- Task-message linking
- Real chat with Dobby (currently placeholder)
- Calendar/Email/Dashboard integration

---

## Troubleshooting

### Build Error: "Cannot find type 'Task' in scope"
- Make sure all files in `DobbyApp/` are added to the Xcode project
- Check that `Models/Task.swift` is in the project navigator

### Menu Bar Icon Doesn't Appear
- Check system preferences → Control Center → Menu Bar
- The icon is a sparkles symbol (⭐)

### App Crashes on Launch
- Check the console for errors
- Make sure macOS version is 14.0+ (Sonoma or later)
- SwiftData requires macOS 14.0+

---

## File Structure

```
DobbyApp/
├── DobbyApp.swift              # Main app + menu bar
├── Models/
│   └── Task.swift              # Task data model
├── Views/
│   ├── ContentView.swift       # Main window layout
│   ├── SidebarView.swift       # Sidebar navigation
│   ├── ChatView.swift          # Chat interface
│   ├── TasksView.swift         # Kanban board
│   └── PlaceholderViews.swift  # Future features
└── Resources/                  # (future: icons, assets)
```

---

## Next Steps After Build

1. **Test the UI** — Click around, create tasks, drag them
2. **Phase 2 prep** — Install WebSocket library (Starscream)
3. **Connect to Gateway** — Point to `ws://127.0.0.1:18789`
4. **Smart task creation** — Add NLP triggers
5. **Real chat** — Connect to Clawdbot backend

---

**Questions?** Let me know what issues you hit and I'll help debug!
