import Foundation
import SwiftUI
import AppKit

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isDarkMode: Bool {
        didSet {
            print("🌓 isDarkMode changed to: \(isDarkMode)")
            defaults.set(isDarkMode, forKey: "isDarkMode")
            applyAppearance()
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var autoCreateTasks: Bool {
        didSet {
            defaults.set(autoCreateTasks, forKey: "autoCreateTasks")
        }
    }

    @Published var syncToTelegram: Bool {
        didSet {
            defaults.set(syncToTelegram, forKey: "syncToTelegram")
        }
    }

    @Published var activeSessionId: String {
        didSet {
            defaults.set(activeSessionId, forKey: "activeSessionId")
        }
    }

    @Published var authToken: String {
        didSet {
            defaults.set(authToken, forKey: "authToken")
        }
    }

    @Published var taskArchiveDays: Int {
        didSet {
            defaults.set(taskArchiveDays, forKey: "taskArchiveDays")
        }
    }

    // UserDefaults instance used for persistence (injectable for testing)
    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults.standard
        // Load saved values from UserDefaults
        self.isDarkMode = defaults.bool(forKey: "isDarkMode")
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.autoCreateTasks = defaults.object(forKey: "autoCreateTasks") as? Bool ?? true
        self.syncToTelegram = defaults.bool(forKey: "syncToTelegram")
        self.activeSessionId = defaults.string(forKey: "activeSessionId") ?? ""
        self.authToken = defaults.string(forKey: "authToken") ?? ""
        self.taskArchiveDays = defaults.object(forKey: "taskArchiveDays") as? Int ?? 30

        // Apply appearance on init
        applyAppearance()
    }

    #if DEBUG
    /// Test initializer that accepts a custom UserDefaults instance
    init(defaults: UserDefaults, skipAppearance: Bool = true) {
        self.defaults = defaults
        self.isDarkMode = defaults.bool(forKey: "isDarkMode")
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.autoCreateTasks = defaults.object(forKey: "autoCreateTasks") as? Bool ?? true
        self.syncToTelegram = defaults.bool(forKey: "syncToTelegram")
        self.activeSessionId = defaults.string(forKey: "activeSessionId") ?? ""
        self.authToken = defaults.string(forKey: "authToken") ?? ""
        self.taskArchiveDays = defaults.object(forKey: "taskArchiveDays") as? Int ?? 30

        if !skipAppearance {
            applyAppearance()
        }
    }
    #endif

    private func applyAppearance() {
        DispatchQueue.main.async {
            if self.isDarkMode {
                NSApp.appearance = NSAppearance(named: .darkAqua)
                print("🌙 Applied dark mode appearance")
            } else {
                NSApp.appearance = NSAppearance(named: .aqua)
                print("☀️ Applied light mode appearance")
            }
        }
    }
}
