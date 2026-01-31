import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedView: NavigationItem? = .chat
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedView: $selectedView)
                .frame(minWidth: 220, idealWidth: 250)
        } detail: {
            Group {
                switch selectedView {
                case .chat:
                    ChatView()
                case .tasks:
                    TasksView()
                case .today:
                    TodayView()
                case .search:
                    SearchView()
                case .archived:
                    ArchivedView()
                case .none: // Default view
                    ChatView()
                }
            }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }
}

enum NavigationItem: String, CaseIterable, Hashable {
    case chat = "Chat"
    case tasks = "Tasks"
    case today = "Today"
    case search = "Search"
    case archived = "Archived"

    var icon: String {
        switch self {
        case .chat: "bubble.left.fill"
        case .tasks: "checklist"
        case .today: "calendar"
        case .search: "magnifyingglass"
        case .archived: "archivebox.fill"
        }
    }
}

// ... (rest of the file is the same)


// MARK: - Archived View

struct ArchivedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.updatedAt, order: .reverse) var allTasks: [Task]

    @State private var selectedTask: Task?

    var archivedTasks: [Task] {
        allTasks.filter { $0.status == .archived }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Archived Tasks")
                    .font(.title2.bold())

                Spacer()

                if !archivedTasks.isEmpty {
                    Text("\(archivedTasks.count) archived")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            // Archived tasks list
            if archivedTasks.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("No Archived Tasks")
                        .font(.title3.bold())

                    Text("Tasks you archive will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(archivedTasks) { task in
                            ArchivedTaskCard(task: task)
                                .onTapGesture {
                                    selectedTask = task
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task)
        }
    }
}

struct ArchivedTaskCard: View {
    @Bindable var task: Task
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Archive icon
            Image(systemName: "archivebox.fill")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                // Priority + Title
                HStack(spacing: 8) {
                    Text(task.priority.emoji)
                        .font(.system(size: 12))

                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                }

                // Tags
                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        if task.tags.count > 3 {
                            Text("+\(task.tags.count - 3)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Archived date
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("Archived \(task.updatedAt, style: .relative)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    // Restore button
                    Button(action: {
                        restoreTask()
                    }) {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    // Delete permanently button
                    Button(action: {
                        deleteTask()
                    }) {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                restoreTask()
            } label: {
                Label("Restore to Backlog", systemImage: "arrow.uturn.backward")
            }

            Divider()

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Label("Delete Permanently", systemImage: "trash")
            }
        }
    }

    private func restoreTask() {
        task.status = .backlog
        task.updatedAt = Date()
    }

    private func deleteTask() {
        guard let context = task.modelContext else { return }
        context.delete(task)
        try? context.save()
    }
}

#Preview {
    ContentView()
        .frame(width: 1280, height: 900)
}
