import SwiftUI

// Placeholder views for Phase 2/3 features

struct TodayView: View {
    var body: some View {
        PlaceholderView(icon: "doc.text.fill", title: "Today Dashboard", subtitle: "Coming in Phase 2")
    }
}

struct CalendarView: View {
    var body: some View {
        PlaceholderView(icon: "calendar", title: "Calendar Integration", subtitle: "Coming in Phase 3")
    }
}

struct EmailView: View {
    var body: some View {
        PlaceholderView(icon: "envelope.fill", title: "Email Integration", subtitle: "Coming in Phase 3")
    }
}

struct DashboardView: View {
    var body: some View {
        PlaceholderView(icon: "chart.bar.fill", title: "Dashboard Widgets", subtitle: "Coming in Phase 3")
    }
}

struct SearchView: View {
    var body: some View {
        PlaceholderView(icon: "magnifyingglass", title: "Search & History", subtitle: "Coming in Phase 3")
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Use dark mode", isOn: .constant(true))
            }
            
            Section("Notifications") {
                Toggle("Important only", isOn: .constant(true))
            }
            
            Section("Tasks") {
                Toggle("Auto-create from chat", isOn: .constant(true))
                Toggle("Sync to Telegram", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
    }
}

struct MenuBarView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Text("🤖 Dobby")
                .font(.headline)
                .padding()
            
            Divider()
            
            // Quick input
            TextField("Ask Dobby...", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Divider()
            
            // Info cards
            VStack(alignment: .leading, spacing: 8) {
                InfoCard(icon: "envelope.fill", text: "3 unread emails")
                InfoCard(icon: "calendar", text: "Next: 2pm - Meeting")
                InfoCard(icon: "bell.fill", text: "Reminder: Call John")
            }
            .padding(.horizontal)
            
            Divider()
            
            // Actions
            VStack(spacing: 4) {
                MenuBarButton(title: "Open Main Window", shortcut: "⌘D", action: {})
                MenuBarButton(title: "Quick Command", shortcut: "⌘⇧D", action: {})
                MenuBarButton(title: "Voice Mode", shortcut: "⌥D", action: {})
            }
            
            Divider()
            
            MenuBarButton(title: "Settings...", shortcut: "", action: {})
            MenuBarButton(title: "Quit", shortcut: "", action: { NSApplication.shared.terminate(nil) })
        }
        .frame(width: 340)
        .padding(.vertical, 8)
    }
}

struct InfoCard: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct MenuBarButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if !shortcut.isEmpty {
                    Text(shortcut)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

struct PlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2.bold())
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
