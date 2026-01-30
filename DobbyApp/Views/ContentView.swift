import SwiftUI

struct ContentView: View {
    @State private var selectedView: NavigationItem? = .chat
    @State private var selectedSession: String = "Main"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedView: $selectedView)
                .frame(width: 240)
        } detail: {
            // Main content area
            Group {
                switch selectedView {
                case .chat:
                    ChatView(sessionName: selectedSession)
                case .tasks:
                    TasksView()
                case .today:
                    TodayView()
                case .calendar:
                    CalendarView()
                case .email:
                    EmailView()
                case .dashboard:
                    DashboardView()
                case .search:
                    SearchView()
                case .none:
                    ChatView(sessionName: selectedSession)
                }
            }
        }
    }
}

enum NavigationItem: String, CaseIterable {
    case chat = "Chat"
    case tasks = "Tasks"
    case today = "Today"
    case calendar = "Calendar"
    case email = "Email"
    case dashboard = "Dashboard"
    case search = "Search"
    
    var icon: String {
        switch self {
        case .chat: return "bubble.left.fill"
        case .tasks: return "checklist"
        case .today: return "doc.text.fill"
        case .calendar: return "calendar"
        case .email: return "envelope.fill"
        case .dashboard: return "chart.bar.fill"
        case .search: return "magnifyingglass"
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1280, height: 900)
}
