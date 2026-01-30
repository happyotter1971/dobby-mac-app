import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var showingNewTask = false
    
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
                    onDrop: { task in updateTaskStatus(task, to: .backlog) }
                )
                
                TaskColumn(
                    title: "🚧 IN PROCESS",
                    count: inProcessTasks.count,
                    tasks: inProcessTasks,
                    onDrop: { task in updateTaskStatus(task, to: .inProcess) }
                )
                
                TaskColumn(
                    title: "✅ COMPLETED",
                    count: completedTasks.count,
                    tasks: completedTasks,
                    onDrop: { task in updateTaskStatus(task, to: .completed) }
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingNewTask) {
            NewTaskSheet(isPresented: $showingNewTask)
        }
    }
    
    private func updateTaskStatus(_ task: Task, to status: TaskStatus) {
        task.status = status
        task.updatedAt = Date()
        if status == .completed {
            task.completedAt = Date()
        }
    }
}

struct TaskColumn: View {
    let title: String
    let count: Int
    let tasks: [Task]
    let onDrop: (Task) -> Void
    
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
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TaskCard: View {
    @Bindable var task: Task
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Priority + Title
            HStack(alignment: .top, spacing: 8) {
                Text(task.priority.emoji)
                    .font(.system(size: 12))
                
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
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
        }
        .padding()
        .frame(minHeight: 100)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct NewTaskSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    
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
        isPresented = false
    }
}

#Preview {
    TasksView()
        .frame(width: 1200, height: 800)
        .modelContainer(for: Task.self, inMemory: true)
}
