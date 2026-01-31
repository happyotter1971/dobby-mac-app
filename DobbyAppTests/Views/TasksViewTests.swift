import XCTest
import SwiftUI
import SwiftData
@testable import Dobby

/// Tests for TasksView logic and behavior
final class TasksViewTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        do {
            container = try TestModelContainer.create()
            context = container.mainContext
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Task Filtering by Status

    @MainActor
    func testTaskFiltering_BacklogTasks() throws {
        let backlogTask = Task(title: "Backlog Task", status: .backlog)
        let inProgressTask = Task(title: "In Progress Task", status: .inProcess)
        let completedTask = Task(title: "Completed Task", status: .completed)

        context.insert(backlogTask)
        context.insert(inProgressTask)
        context.insert(completedTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())
        let backlogTasks = allTasks.filter { $0.status == .backlog }

        XCTAssertEqual(backlogTasks.count, 1)
        XCTAssertEqual(backlogTasks.first?.title, "Backlog Task")
    }

    @MainActor
    func testTaskFiltering_InProgressTasks() throws {
        let backlogTask = Task(title: "Backlog Task", status: .backlog)
        let inProgressTask = Task(title: "In Progress Task", status: .inProcess)
        let completedTask = Task(title: "Completed Task", status: .completed)

        context.insert(backlogTask)
        context.insert(inProgressTask)
        context.insert(completedTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())
        let inProgressTasks = allTasks.filter { $0.status == .inProcess }

        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(inProgressTasks.first?.title, "In Progress Task")
    }

    @MainActor
    func testTaskFiltering_CompletedTasks() throws {
        let backlogTask = Task(title: "Backlog Task", status: .backlog)
        let inProgressTask = Task(title: "In Progress Task", status: .inProcess)
        let completedTask = Task(title: "Completed Task", status: .completed)

        context.insert(backlogTask)
        context.insert(inProgressTask)
        context.insert(completedTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())
        let completedTasks = allTasks.filter { $0.status == .completed }

        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "Completed Task")
    }

    @MainActor
    func testTaskFiltering_ExcludesArchivedTasks() throws {
        let activeTask = Task(title: "Active Task", status: .backlog)
        let archivedTask = Task(title: "Archived Task", status: .archived)

        context.insert(activeTask)
        context.insert(archivedTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())

        // Kanban board should exclude archived tasks
        let kanbanTasks = allTasks.filter { $0.status != .archived }

        XCTAssertEqual(kanbanTasks.count, 1)
        XCTAssertEqual(kanbanTasks.first?.title, "Active Task")
    }

    // MARK: - Task Status Transitions

    @MainActor
    func testTaskStatusTransition_BacklogToInProgress() throws {
        let task = Task(title: "Task", status: .backlog)
        context.insert(task)
        try context.save()

        task.status = .inProcess
        task.updatedAt = Date()
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.first?.status, .inProcess)
    }

    @MainActor
    func testTaskStatusTransition_InProgressToCompleted() throws {
        let task = Task(title: "Task", status: .inProcess)
        context.insert(task)
        try context.save()

        task.status = .completed
        task.completedAt = Date()
        task.updatedAt = Date()
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.first?.status, .completed)
        XCTAssertNotNil(tasks.first?.completedAt)
    }

    @MainActor
    func testTaskStatusTransition_CompletedToArchived() throws {
        let task = Task(title: "Task", status: .completed)
        task.completedAt = Date()
        context.insert(task)
        try context.save()

        task.status = .archived
        task.updatedAt = Date()
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.first?.status, .archived)
    }

    // MARK: - Task Priority Display

    func testTaskPriority_ColorMapping() {
        // High priority should be red
        XCTAssertEqual(TaskPriority.high.emoji, "🔴")

        // Medium priority should be orange
        XCTAssertEqual(TaskPriority.medium.emoji, "🟠")

        // Low priority should be green
        XCTAssertEqual(TaskPriority.low.emoji, "🟢")
    }

    // MARK: - Task Execution State

    @MainActor
    func testTaskExecution_ProgressTracking() throws {
        let task = Task(title: "Executing Task", status: .inProcess)
        task.progressPercent = 0
        context.insert(task)
        try context.save()

        // Simulate progress updates
        task.progressPercent = 25
        try context.save()

        task.progressPercent = 50
        try context.save()

        task.progressPercent = 100
        task.status = .completed
        task.completedAt = Date()
        task.resultSummary = "Task completed successfully"
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.first?.status, .completed)
        XCTAssertEqual(tasks.first?.progressPercent, 100)
        XCTAssertNotNil(tasks.first?.resultSummary)
    }

    @MainActor
    func testTask_HasResult() throws {
        let taskWithResult = Task(title: "Task with result", status: .completed)
        taskWithResult.resultSummary = "Completed with output"
        taskWithResult.completedAt = Date()

        let taskWithoutResult = Task(title: "Task without result", status: .completed)
        taskWithoutResult.completedAt = Date()

        context.insert(taskWithResult)
        context.insert(taskWithoutResult)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        let tasksWithResult = tasks.filter { $0.resultSummary != nil && !$0.resultSummary!.isEmpty }

        XCTAssertEqual(tasksWithResult.count, 1)
        XCTAssertEqual(tasksWithResult.first?.title, "Task with result")
    }

    // MARK: - Task Sorting

    @MainActor
    func testTaskSorting_ByUpdatedAt() throws {
        let oldTask = Task(title: "Old Task", status: .backlog)
        oldTask.updatedAt = Date(timeIntervalSince1970: 1000)

        let newTask = Task(title: "New Task", status: .backlog)
        newTask.updatedAt = Date(timeIntervalSince1970: 2000)

        context.insert(oldTask)
        context.insert(newTask)
        try context.save()

        var descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let sortedTasks = try context.fetch(descriptor)

        XCTAssertEqual(sortedTasks.first?.title, "New Task")
        XCTAssertEqual(sortedTasks.last?.title, "Old Task")
    }

    @MainActor
    func testTaskSorting_ByPriority() throws {
        let lowTask = Task(title: "Low", priority: .low)
        let highTask = Task(title: "High", priority: .high)
        let mediumTask = Task(title: "Medium", priority: .medium)

        context.insert(lowTask)
        context.insert(highTask)
        context.insert(mediumTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())

        // Sort by priority (high first)
        let priorityOrder: [TaskPriority] = [.high, .medium, .low]
        let sortedByPriority = allTasks.sorted { task1, task2 in
            (priorityOrder.firstIndex(of: task1.priority) ?? 0) <
            (priorityOrder.firstIndex(of: task2.priority) ?? 0)
        }

        XCTAssertEqual(sortedByPriority[0].title, "High")
        XCTAssertEqual(sortedByPriority[1].title, "Medium")
        XCTAssertEqual(sortedByPriority[2].title, "Low")
    }

    // MARK: - Column Count Tests

    @MainActor
    func testColumnCounts_AccurateForEachStatus() throws {
        // Create tasks with different statuses
        context.insert(Task(title: "B1", status: .backlog))
        context.insert(Task(title: "B2", status: .backlog))
        context.insert(Task(title: "IP1", status: .inProcess))
        context.insert(Task(title: "C1", status: .completed))
        context.insert(Task(title: "C2", status: .completed))
        context.insert(Task(title: "C3", status: .completed))
        context.insert(Task(title: "A1", status: .archived))  // Should not count
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())

        let backlogCount = allTasks.filter { $0.status == .backlog }.count
        let inProgressCount = allTasks.filter { $0.status == .inProcess }.count
        let completedCount = allTasks.filter { $0.status == .completed }.count

        XCTAssertEqual(backlogCount, 2)
        XCTAssertEqual(inProgressCount, 1)
        XCTAssertEqual(completedCount, 3)
    }
}
