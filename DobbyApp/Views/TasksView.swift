import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var showingNewTask = false
    @State private var selectedTask: Task?
    @State private var wsManager = WebSocketManager.shared
    
    private var backlogTasks: [Task] {
        tasks.filter { $0.status == .backlog }
    }
    
    private var inProcessTasks: [Task] {
        tasks.filter { $0.status == .inProcess }
    }
    
    private var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: { showingNewTask = true }) {
                    Label("New Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Kanban board
            HStack(alignment: .top, spacing: 16) {
                TaskColumn(
                    title: "Backlog",
                    count: backlogTasks.count,
                    tasks: backlogTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
                    emptyMessage: "No tasks in backlog",
                    onDrop: { task in updateTaskStatus(task, to: .backlog) }
                )

                TaskColumn(
                    title: "In Progress",
                    count: inProcessTasks.count,
                    tasks: inProcessTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
                    emptyMessage: "Drag a task here to start",
                    onDrop: { task in updateTaskStatus(task, to: .inProcess) }
                )

                TaskColumn(
                    title: "Completed",
                    count: completedTasks.count,
                    tasks: completedTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
                    emptyMessage: "No completed tasks yet",
                    onDrop: { task in updateTaskStatus(task, to: .completed) }
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingNewTask) {
            NewTaskSheet(isPresented: $showingNewTask, modelContext: modelContext)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task)
        }
        .onAppear {
            setupTaskUpdateHandler()
        }
    }
    
    private func setupTaskUpdateHandler() {
        // Handle task updates from gateway (Dobby creating/updating tasks)
        wsManager.onTaskUpdate = { [self] update in
            DispatchQueue.main.async {
                handleTaskUpdate(update)
            }
        }
    }
    
    private func handleTaskUpdate(_ update: TaskUpdate) {
        // Find existing task or create new one
        if let existingTask = tasks.first(where: { $0.id == update.taskId }) {
            // Update existing task
            if let status = update.status {
                existingTask.status = status
                if status == .completed {
                    existingTask.completedAt = Date()
                }
            }
            if let progress = update.progress {
                existingTask.progressPercent = progress
            }
            if let resultSummary = update.resultSummary {
                existingTask.resultSummary = resultSummary
            }
            existingTask.updatedAt = Date()
        } else if update.type == "task.created", let title = update.title {
            // Create new task from gateway
            let task = Task(
                id: update.taskId,
                title: title,
                status: update.status ?? .backlog,
                source: .dobby
            )
            modelContext.insert(task)
        }
    }
    
    private func updateTaskStatus(_ task: Task, to status: TaskStatus) {
        // Don't do anything if status hasn't changed
        guard task.status != status else { return }

        task.status = status
        task.updatedAt = Date()
        if status == .completed {
            task.completedAt = Date()
        }

        // Sync to gateway
        wsManager.updateTask(taskId: task.id, status: status)

        // If moving to In Process, execute the task with Clawdbot
        if status == .inProcess {
            wsManager.executeTask(taskId: task.id, title: task.title)
        }
    }
}

struct TaskColumn: View {
    let title: String
    let count: Int
    let tasks: [Task]
    let allTasks: [Task]
    @Binding var selectedTask: Task?
    var emptyMessage: String = "No tasks"
    let onDrop: (Task) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header with count badge
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(count > 0 ? Color.accentColor : Color.gray.opacity(0.5))
                    )
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    if tasks.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                            Text(emptyMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(tasks) { task in
                            TaskCard(task: task)
                                .onTapGesture {
                                    selectedTask = task
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isTargeted ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .dropDestination(for: String.self) { items, location in
            guard let taskIdString = items.first,
                  let taskId = UUID(uuidString: taskIdString),
                  let task = allTasks.first(where: { $0.id == taskId }) else {
                return false
            }
            onDrop(task)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

struct TaskCard: View {
    @Bindable var task: Task
    @State private var isHovered = false
    @State private var pulseAnimation = false

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, task.status != .completed else { return false }
        return dueDate < Date()
    }

    private var dueDateColor: Color {
        guard let dueDate = task.dueDate else { return .secondary }
        if task.status == .completed { return .green }

        let calendar = Calendar.current
        if isOverdue { return .red }
        if calendar.isDateInToday(dueDate) { return .orange }
        return .blue
    }

    private var isExecuting: Bool {
        task.status == .inProcess && (task.progressPercent ?? 0) < 100
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Priority indicator - colored left border
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                // Execution status badge
                if isExecuting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                        Text("Running...")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Result available badge
                if task.status == .completed, task.resultSummary != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("View Result")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Title only (no priority emoji)
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Due date indicator (compact)
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.system(size: 10))
                        Text(dueDate, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundStyle(dueDateColor)
                }

                // Tags count indicator (if any)
                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 10))
                        Text("\(task.tags.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
                .shadow(
                    color: isExecuting ? Color.blue.opacity(pulseAnimation ? 0.3 : 0.15) : .black.opacity(isHovered ? 0.08 : 0.04),
                    radius: isExecuting ? 8 : (isHovered ? 6 : 3)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isExecuting ? Color.blue.opacity(pulseAnimation ? 0.6 : 0.3) : Color(.separatorColor).opacity(0.5),
                    lineWidth: isExecuting ? 2 : 1
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if isExecuting {
                pulseAnimation = true
            }
        }
        .onChange(of: isExecuting) { _, newValue in
            pulseAnimation = newValue
        }
        .draggable(task.id.uuidString) {
            // Drag preview
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(priorityColor)
                    .frame(width: 4, height: 20)
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .padding(12)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 8)
        }
        .contextMenu {
            Button {
                archiveTask()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }

    private func archiveTask() {
        task.status = .archived
        task.updatedAt = Date()
    }
}

struct NewTaskSheet: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var wsManager = WebSocketManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Task")
                .font(.title2.bold())
            
            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            Picker("Priority", selection: $priority) {
                Text("🔴 High").tag(TaskPriority.high)
                Text("🟠 Medium").tag(TaskPriority.medium)
                Text("🟢 Low").tag(TaskPriority.low)
            }
            .pickerStyle(.segmented)
            
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
                    createTask()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
    
    private func createTask() {
        let task = Task(
            title: title,
            priority: priority,
            source: .user,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(task)

        // Send to gateway with the same task ID
        wsManager.createTask(title: title, priority: priority, taskId: task.id)

        isPresented = false
    }
}

#Preview {
    TasksView()
        .frame(width: 1200, height: 800)
        .modelContainer(for: Task.self, inMemory: true)
}
