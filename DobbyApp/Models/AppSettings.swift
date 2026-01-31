import Foundation
import SwiftUI
import AppKit

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isDarkMode: Bool {
        didSet {
            print("🌓 isDarkMode changed to: \(isDarkMode)")
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            applyAppearance()
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var autoCreateTasks: Bool {
        didSet {
            UserDefaults.standard.set(autoCreateTasks, forKey: "autoCreateTasks")
        }
    }

    @Published var syncToTelegram: Bool {
        didSet {
            UserDefaults.standard.set(syncToTelegram, forKey: "syncToTelegram")
        }
    }

    @Published var activeSessionId: String {
        didSet {
            UserDefaults.standard.set(activeSessionId, forKey: "activeSessionId")
        }
    }

    @Published var authToken: String {
        didSet {
            UserDefaults.standard.set(authToken, forKey: "authToken")
        }
    }

    @Published var taskArchiveDays: Int {
        didSet {
            UserDefaults.standard.set(taskArchiveDays, forKey: "taskArchiveDays")
        }
    }

    private init() {
        // Load saved values from UserDefaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.autoCreateTasks = UserDefaults.standard.object(forKey: "autoCreateTasks") as? Bool ?? true
        self.syncToTelegram = UserDefaults.standard.bool(forKey: "syncToTelegram")
        self.activeSessionId = UserDefaults.standard.string(forKey: "activeSessionId") ?? ""
        self.authToken = UserDefaults.standard.string(forKey: "authToken") ?? ""
        self.taskArchiveDays = UserDefaults.standard.object(forKey: "taskArchiveDays") as? Int ?? 30

        // Apply appearance on init
        applyAppearance()
    }

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
