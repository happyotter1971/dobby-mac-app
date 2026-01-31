# Dobby Mac App

Native macOS application for the Dobby AI assistant, built with Swift + SwiftUI.

## Features

- 💬 **Native Chat Interface** — Rich markdown, code blocks, better than Telegram
- ✅ **Task Tracker** — Kanban board (Backlog → In Process → Completed)
- 🎤 **Voice Input** — Wispr Flow integration
- 🔔 **Menu Bar Access** — Always one click away
- ⌨️ **Keyboard Shortcuts** — Power user efficiency
- 🔗 **Task Linking** — Auto-create tasks from conversations, see related messages

## Status

🚧 **Phase 1 (MVP) — In Progress**

### ✅ Completed
- App structure with sidebar navigation
- Task Kanban board (Backlog → In Process → Completed)
- Task creation UI with priority levels
- Chat interface with message bubbles
- **WebSocket integration** (full bidirectional communication)
- Connection status indicator
- Auto-reconnect with exponential backoff
- Task sync with gateway (create, update, progress tracking)

### 🚧 Next Up
- **Test with live gateway** (protocol is ready!)
- Load & display chat history
- Drag & drop for task columns
- Menu bar quick access
- Keyboard shortcuts (⌘D, ⌘K)

## Project Structure

```
dobby-mac-app/
├── DobbyApp/                  # Swift source code
│   ├── DobbyApp.swift         # App entry point
│   ├── Models/                # SwiftData models
│   ├── Views/                 # SwiftUI views
│   ├── Network/               # WebSocket manager
│   └── Resources/             # Assets
├── docs/                      # Documentation
│   ├── DESIGN.md              # Full design specifications
│   ├── UI-DESIGN.md           # Visual guidelines
│   ├── WEBSOCKET.md           # WebSocket protocol
│   └── ...                    # Other docs
├── scripts/                   # Test scripts
│   ├── test_gateway.py        # Gateway test server
│   └── run_test_gateway.sh    # Test runner
└── DobbyApp.xcodeproj/        # Xcode project
```

### 📚 Documentation
- [docs/DESIGN.md](docs/DESIGN.md) — Full design specifications
- [docs/UI-DESIGN.md](docs/UI-DESIGN.md) — Visual guidelines
- [docs/WEBSOCKET.md](docs/WEBSOCKET.md) — WebSocket protocol & implementation
- [docs/XCODE-SETUP.md](docs/XCODE-SETUP.md) — Xcode setup instructions

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Backend:** WebSocket to Clawdbot Gateway
- **Voice:** Wispr Flow (external app)

## Timeline

- **Phase 1 (MVP):** Chat + Basic Kanban — 2-3 weeks
- **Phase 2 (Enhanced):** Smart tasks + linking — 1-2 weeks
- **Phase 3 (Power Features):** Real-time sync + integrations — 2-3 weeks
- **Phase 4 (Polish):** Branding + distribution — 1 week

**Total:** 6-9 weeks, 120-160 hours

## Development

Coming soon — Xcode project setup and build instructions.

## License

Private — Bill Ott (@happyotter1971)
