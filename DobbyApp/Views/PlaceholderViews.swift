import SwiftUI
import SwiftData

// Placeholder views for Phase 2/3 features

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [Task]
    @State private var showingNewTask = false

    private var dueTodayTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today) && $0.status != .completed && $0.status != .archived
        }
    }

    private var overdueTasks: [Task] {
        let now = Date()
        return allTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < now && $0.status != .completed && $0.status != .archived
        }
    }

    private var inProgressTasks: [Task] {
        allTasks.filter { $0.status == .inProcess }
    }

    private var completedToday: [Task] {
        let calendar = Calendar.current
        return allTasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }
    }

    private var completionRate: Double {
        let total = allTasks.filter { $0.status != .backlog && $0.status != .archived }.count
        guard total > 0 else { return 0 }
        let completed = allTasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(total)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.largeTitle.bold())
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: { showingNewTask = true }) {
                        Label("New Task", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // Stats Cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total Tasks",
                        value: "\(allTasks.filter { $0.status != .archived }.count)",
                        icon: "list.bullet",
                        color: .blue
                    )

                    StatCard(
                        title: "Completed Today",
                        value: "\(completedToday.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Completion Rate",
                        value: String(format: "%.0f%%", completionRate * 100),
                        icon: "chart.pie.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Overdue Section
                if !overdueTasks.isEmpty {
                    DashboardSection(
                        title: "⚠️ Overdue",
                        count: overdueTasks.count,
                        color: .red,
                        tasks: overdueTasks
                    )
                }

                // Due Today Section
                if !dueTodayTasks.isEmpty {
                    DashboardSection(
                        title: "📅 Due Today",
                        count: dueTodayTasks.count,
                        color: .orange,
                        tasks: dueTodayTasks
                    )
                }

                // In Progress Section
                if !inProgressTasks.isEmpty {
                    DashboardSection(
                        title: "🚧 In Progress",
                        count: inProgressTasks.count,
                        color: .blue,
                        tasks: inProgressTasks
                    )
                }

                // Empty state
                if overdueTasks.isEmpty && dueTodayTasks.isEmpty && inProgressTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("All caught up!")
                            .font(.title2.bold())

                        Text("No tasks due today or in progress")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(60)
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingNewTask) {
            NewTaskSheet(isPresented: $showingNewTask, modelContext: modelContext)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
}

struct DashboardSection: View {
    let title: String
    let count: Int
    let color: Color
    let tasks: [Task]
    @State private var selectedTask: Task?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.bold())

                Text("\(count)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    DashboardTaskRow(task: task, accentColor: color)
                        .onTapGesture {
                            selectedTask = task
                        }
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task)
        }
    }
}

struct DashboardTaskRow: View {
    @Bindable var task: Task
    let accentColor: Color
    @Environment(\.modelContext) private var modelContext
    @State private var wsManager = WebSocketManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                toggleTaskStatus()
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.priority.emoji)
                        .font(.caption)

                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.status == .completed)

                    Spacer()

                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    if !task.tags.isEmpty {
                        ForEach(task.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    if let progress = task.progressPercent {
                        HStack(spacing: 4) {
                            ProgressView(value: Double(progress), total: 100)
                                .frame(width: 60)
                            Text("\(progress)%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        )
    }

    private func toggleTaskStatus() {
        if task.status == .completed {
            task.status = .inProcess
            task.completedAt = nil
        } else {
            task.status = .completed
            task.completedAt = Date()
        }
        task.updatedAt = Date()

        // Sync to gateway
        wsManager.updateTask(taskId: task.id, status: task.status)
    }
}

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSettings
    @Query private var allMessages: [ChatMessage]
    @Query private var allTasks: [Task]
    @Query private var sessions: [ChatSession]

    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var selectedSession: String? = nil
    @State private var selectedTaskStatus: TaskStatus? = nil
    @State private var selectedTask: Task?
    @State private var debounceWorkItem: DispatchWorkItem?

    private var filteredMessages: [ChatMessage] {
        guard !debouncedSearchText.isEmpty else { return [] }

        var filtered = allMessages.filter {
            $0.content.localizedCaseInsensitiveContains(debouncedSearchText)
        }

        if let sessionFilter = selectedSession {
            filtered = filtered.filter { $0.sessionKey.lowercased() == sessionFilter.lowercased() }
        }

        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    private var filteredTasks: [Task] {
        guard !debouncedSearchText.isEmpty else { return [] }

        var filtered = allTasks.filter {
            $0.title.localizedCaseInsensitiveContains(debouncedSearchText) ||
            ($0.notes?.localizedCaseInsensitiveContains(debouncedSearchText) ?? false)
        }

        if let statusFilter = selectedTaskStatus {
            filtered = filtered.filter { $0.status == statusFilter }
        }

        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with search bar
            VStack(spacing: 12) {
                HStack {
                    Text("Search")
                        .font(.title2.bold())
                    Spacer()
                }

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search messages and tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { oldValue, newValue in
                            debounceSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            debouncedSearchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Session filter
                        Menu {
                            Button("All Sessions") {
                                selectedSession = nil
                            }

                            Divider()

                            ForEach(sessions) { session in
                                Button(session.name) {
                                    selectedSession = session.id.uuidString
                                }
                            }
                        } label: {
                            FilterChip(
                                title: selectedSession == nil ? "All Sessions" : sessionName(for: selectedSession!),
                                isActive: selectedSession != nil
                            )
                        }
                        .menuStyle(.borderlessButton)

                        // Task status filter
                        Menu {
                            Button("All Statuses") {
                                selectedTaskStatus = nil
                            }

                            Divider()

                            Button("Backlog") {
                                selectedTaskStatus = .backlog
                            }
                            Button("In Process") {
                                selectedTaskStatus = .inProcess
                            }
                            Button("Completed") {
                                selectedTaskStatus = .completed
                            }
                            Button("Archived") {
                                selectedTaskStatus = .archived
                            }
                        } label: {
                            FilterChip(
                                title: selectedTaskStatus?.rawValue.capitalized ?? "All Statuses",
                                isActive: selectedTaskStatus != nil
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Results
            if debouncedSearchText.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("Search messages and tasks")
                        .font(.title3)

                    Text("Find conversations, task details, and more")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Messages section
                        if !filteredMessages.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Messages (\(filteredMessages.count))")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(filteredMessages.prefix(10)) { message in
                                    SearchMessageRow(
                                        message: message,
                                        searchText: debouncedSearchText,
                                        sessionName: sessionName(for: message.sessionKey)
                                    )
                                }

                                if filteredMessages.count > 10 {
                                    Text("+ \(filteredMessages.count - 10) more messages")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Tasks section
                        if !filteredTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tasks (\(filteredTasks.count))")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(filteredTasks) { task in
                                    SearchTaskRow(
                                        task: task,
                                        searchText: debouncedSearchText
                                    )
                                    .onTapGesture {
                                        selectedTask = task
                                    }
                                }
                            }
                        }

                        // No results
                        if filteredMessages.isEmpty && filteredTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)

                                Text("No results found")
                                    .font(.title3)

                                Text("Try different keywords or filters")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task)
        }
    }

    private func sessionName(for sessionId: String) -> String {
        sessions.first { $0.id.uuidString.lowercased() == sessionId.lowercased() }?.name ?? "Unknown"
    }

    private func debounceSearch() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            debouncedSearchText = searchText
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.2) : Color(.textBackgroundColor))
            .foregroundStyle(isActive ? .primary : .secondary)
            .clipShape(Capsule())
    }
}

struct SearchMessageRow: View {
    let message: ChatMessage
    let searchText: String
    let sessionName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: message.isFromUser ? "person.fill" : "sparkles")
                    .font(.caption)
                    .foregroundStyle(message.isFromUser ? .blue : .purple)

                Text(message.isFromUser ? "You" : "Dobby")
                    .font(.caption.bold())

                Text("•")
                    .foregroundStyle(.secondary)

                Text(sessionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.secondary)

                Text(message.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Text(highlightedText(message.content, searchText: searchText))
                .font(.body)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func highlightedText(_ text: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(text)

        if let range = text.range(of: searchText, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            if let attributedRange = Range(nsRange, in: attributedString) {
                attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                attributedString[attributedRange].font = .body.bold()
            }
        }

        return attributedString
    }
}

struct SearchTaskRow: View {
    @Bindable var task: Task
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.status == .completed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.priority.emoji)
                        .font(.caption)

                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.status == .completed)

                    Spacer()

                    Text(task.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                if let notes = task.notes, notes.localizedCaseInsensitiveContains(searchText) {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if !task.tags.isEmpty {
                        ForEach(task.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var statusColor: Color {
        switch task.status {
        case .backlog: return .gray
        case .inProcess: return .blue
        case .completed: return .green
        case .archived: return .orange
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Gateway Connection") {
                SecureField("Auth Token", text: $settings.authToken)
                    .textFieldStyle(.roundedBorder)
                Text("Required for WebSocket connection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Appearance") {
                Toggle("Use dark mode", isOn: $settings.isDarkMode)
            }

            Section("Notifications") {
                Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
            }

            Section("Tasks") {
                Toggle("Auto-create from chat", isOn: $settings.autoCreateTasks)
                Toggle("Sync to Telegram", isOn: $settings.syncToTelegram)
                Stepper("Auto-archive after \(settings.taskArchiveDays) days",
                        value: $settings.taskArchiveDays, in: 7...90, step: 7)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("Phase 1 MVP")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 500)
    }
}

struct MenuBarView: View {
    @State private var quickInput: String = ""
    @State private var wsManager = WebSocketManager.shared
    @Query(sort: \Task.updatedAt, order: .reverse) private var tasks: [Task]

    private var activeTasks: Int {
        tasks.filter { $0.status == .inProcess }.count
    }

    private var pendingTasks: Int {
        tasks.filter { $0.status == .backlog }.count
    }

    private var completedToday: Int {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard task.status == .completed, let completedAt = task.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with connection status
            HStack {
                Text("🤖 Dobby")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(wsManager.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
            }
            .padding()

            Divider()

            // Quick input
            HStack {
                TextField("Ask Dobby...", text: $quickInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !quickInput.isEmpty && wsManager.isConnected {
                            wsManager.sendChatMessage(content: quickInput)
                            quickInput = ""
                        }
                    }

                Button(action: {
                    if !quickInput.isEmpty && wsManager.isConnected {
                        wsManager.sendChatMessage(content: quickInput)
                        quickInput = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(quickInput.isEmpty || !wsManager.isConnected ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(quickInput.isEmpty || !wsManager.isConnected)
            }
            .padding(.horizontal)

            Divider()

            // Dynamic task stats
            VStack(alignment: .leading, spacing: 8) {
                InfoCard(icon: "play.circle.fill", text: "\(activeTasks) task\(activeTasks == 1 ? "" : "s") in progress")
                InfoCard(icon: "tray.full.fill", text: "\(pendingTasks) task\(pendingTasks == 1 ? "" : "s") in backlog")
                InfoCard(icon: "checkmark.circle.fill", text: "\(completedToday) completed today")
            }
            .padding(.horizontal)

            Divider()

            // Actions
            VStack(spacing: 4) {
                MenuBarButton(title: "Open Main Window", shortcut: "⌘D") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title == "Dobby" || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }

            Divider()

            MenuBarButton(title: "Quit", shortcut: "") {
                NSApplication.shared.terminate(nil)
            }
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
