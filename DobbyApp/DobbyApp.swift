import SwiftUI
import SwiftData

@main
struct DobbyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(AppSettings.shared)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .modelContainer(for: [Task.self, ChatMessage.self, ChatSession.self])

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
        }
    }
}

// App delegate for menu bar
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var wsManager = WebSocketManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Connect to Clawdbot Gateway
        print("🚀 Connecting to Clawdbot Gateway...")
        wsManager.connect()
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Dobby")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
        popover?.behavior = .transient
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean disconnect
        print("👋 Disconnecting from gateway...")
        wsManager.disconnect()
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
