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
                    title: "📝 BACKLOG",
                    count: backlogTasks.count,
                    tasks: backlogTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
                    onDrop: { task in updateTaskStatus(task, to: .backlog) }
                )

                TaskColumn(
                    title: "🚧 IN PROCESS",
                    count: inProcessTasks.count,
                    tasks: inProcessTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
                    onDrop: { task in updateTaskStatus(task, to: .inProcess) }
                )

                TaskColumn(
                    title: "✅ COMPLETED",
                    count: completedTasks.count,
                    tasks: completedTasks,
                    allTasks: tasks,
                    selectedTask: $selectedTask,
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
    let onDrop: (Task) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header
            Text("\(title) (\(count))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(tasks) { task in
                        TaskCard(task: task)
                            .onTapGesture {
                                selectedTask = task
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Execution status badge
            if isExecuting {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                    Text("Executing...")
                        .font(.caption2.bold())
                    if let progress = task.progressPercent, progress > 0 {
                        Text("\(progress)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color.blue.opacity(pulseAnimation ? 0.25 : 0.15)
                )
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                .onAppear {
                    pulseAnimation = true
                }
            }

            // Result available badge
            if task.status == .completed, task.resultSummary != nil {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                    Text("View Result")
                        .font(.caption2.bold())
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
            }
            // Priority + Title
            HStack(alignment: .top, spacing: 8) {
                Text(task.priority.emoji)
                    .font(.system(size: 12))

                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
            }

            // Tags
            if !task.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(task.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if task.tags.count > 3 {
                        Text("+\(task.tags.count - 3)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Due date indicator
            if let dueDate = task.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                        .font(.system(size: 10))
                    Text(dueDate, style: .relative)
                        .font(.caption2)
                }
                .foregroundStyle(dueDateColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(dueDateColor.opacity(0.15))
                .clipShape(Capsule())
            }

            Spacer()
            
            // Source indicator
            HStack(spacing: 4) {
                Image(systemName: task.source == .dobby ? "sparkles" : "person.fill")
                    .font(.system(size: 10))
                Text(task.source == .dobby ? "Created by Dobby" : "You added")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            
            // Timestamp
            Text(task.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Progress bar for executing tasks
            if isExecuting, let progress = task.progressPercent, progress > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 4)

                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(progress) / 100.0, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
        .frame(minHeight: 100)
        .background(
            ZStack {
                Color(.windowBackgroundColor)
                // Subtle glow effect for executing tasks
                if isExecuting {
                    Color.blue.opacity(0.05)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isExecuting ? Color.blue.opacity(0.5) : Color(.separatorColor),
                    lineWidth: isExecuting ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .draggable(task.id.uuidString) {
            // Drag preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.priority.emoji)
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
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
