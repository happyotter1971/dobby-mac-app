import XCTest
import SwiftData
@testable import Dobby

/// Tests for the Task model
final class TaskTests: XCTestCase {

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

    // MARK: - Initialization Tests

    @MainActor
    func testTask_DefaultValues() {
        let task = Task(title: "Test Task")

        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.status, .backlog)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.source, .user)
        XCTAssertNil(task.completedAt)
        XCTAssertNil(task.notes)
        XCTAssertNil(task.resultSummary)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.reminder)
        XCTAssertNil(task.progressPercent)
        XCTAssertTrue(task.tags.isEmpty)
        XCTAssertTrue(task.linkedMessageIds.isEmpty)
    }

    @MainActor
    func testTask_CustomValues() {
        let task = Task(
            title: "Custom Task",
            status: .inProcess,
            priority: .high,
            source: .dobby,
            notes: "Some notes",
            progressPercent: 50
        )

        XCTAssertEqual(task.title, "Custom Task")
        XCTAssertEqual(task.status, .inProcess)
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.source, .dobby)
        XCTAssertEqual(task.notes, "Some notes")
        XCTAssertEqual(task.progressPercent, 50)
    }

    // MARK: - TaskStatus Enum Tests

    func testTaskStatus_RawValues() {
        XCTAssertEqual(TaskStatus.backlog.rawValue, "backlog")
        XCTAssertEqual(TaskStatus.inProcess.rawValue, "inProcess")
        XCTAssertEqual(TaskStatus.completed.rawValue, "completed")
        XCTAssertEqual(TaskStatus.archived.rawValue, "archived")
    }

    func testTaskStatus_AllCases() {
        let allCases = TaskStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.backlog))
        XCTAssertTrue(allCases.contains(.inProcess))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.archived))
    }

    // MARK: - TaskPriority Enum Tests

    func testTaskPriority_RawValues() {
        XCTAssertEqual(TaskPriority.high.rawValue, "high")
        XCTAssertEqual(TaskPriority.medium.rawValue, "medium")
        XCTAssertEqual(TaskPriority.low.rawValue, "low")
    }

    func testTaskPriority_Emoji() {
        XCTAssertEqual(TaskPriority.high.emoji, "🔴")
        XCTAssertEqual(TaskPriority.medium.emoji, "🟠")
        XCTAssertEqual(TaskPriority.low.emoji, "🟢")
    }

    func testTaskPriority_AllCases() {
        let allCases = TaskPriority.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.low))
    }

    // MARK: - TaskSource Enum Tests

    func testTaskSource_RawValues() {
        XCTAssertEqual(TaskSource.dobby.rawValue, "dobby")
        XCTAssertEqual(TaskSource.user.rawValue, "user")
        XCTAssertEqual(TaskSource.automated.rawValue, "automated")
    }

    func testTaskSource_AllCases() {
        let allCases = TaskSource.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.dobby))
        XCTAssertTrue(allCases.contains(.user))
        XCTAssertTrue(allCases.contains(.automated))
    }

    // MARK: - SwiftData Persistence Tests

    @MainActor
    func testTask_InsertAndFetch() throws {
        let task = Task(title: "Persistent Task")
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Persistent Task")
    }

    @MainActor
    func testTask_Update() throws {
        let task = Task(title: "Original Title")
        context.insert(task)
        try context.save()

        task.title = "Updated Title"
        task.status = .completed
        task.completedAt = Date()
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Updated Title")
        XCTAssertEqual(tasks.first?.status, .completed)
        XCTAssertNotNil(tasks.first?.completedAt)
    }

    @MainActor
    func testTask_Delete() throws {
        let task = Task(title: "To Be Deleted")
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.count, 0)
    }

    @MainActor
    func testTask_FilterByStatus() throws {
        let backlogTask = Task(title: "Backlog", status: .backlog)
        let inProgressTask = Task(title: "In Progress", status: .inProcess)
        let completedTask = Task(title: "Completed", status: .completed)

        context.insert(backlogTask)
        context.insert(inProgressTask)
        context.insert(completedTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(allTasks.count, 3)

        let backlogTasks = allTasks.filter { $0.status == .backlog }
        XCTAssertEqual(backlogTasks.count, 1)
        XCTAssertEqual(backlogTasks.first?.title, "Backlog")

        let inProgressTasks = allTasks.filter { $0.status == .inProcess }
        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(inProgressTasks.first?.title, "In Progress")
    }

    @MainActor
    func testTask_SortByPriority() throws {
        let lowTask = Task(title: "Low", priority: .low)
        let highTask = Task(title: "High", priority: .high)
        let mediumTask = Task(title: "Medium", priority: .medium)

        context.insert(lowTask)
        context.insert(highTask)
        context.insert(mediumTask)
        try context.save()

        let allTasks = try context.fetch(FetchDescriptor<Task>())

        // Sort by priority (high first)
        let sortedTasks = allTasks.sorted { task1, task2 in
            let order: [TaskPriority] = [.high, .medium, .low]
            return order.firstIndex(of: task1.priority)! < order.firstIndex(of: task2.priority)!
        }

        XCTAssertEqual(sortedTasks[0].priority, .high)
        XCTAssertEqual(sortedTasks[1].priority, .medium)
        XCTAssertEqual(sortedTasks[2].priority, .low)
    }

    // MARK: - Tags and Linked Messages

    @MainActor
    func testTask_Tags() throws {
        let task = Task(title: "Tagged Task")
        task.tags = ["urgent", "feature", "backend"]
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.first?.tags.count, 3)
        XCTAssertTrue(tasks.first?.tags.contains("urgent") ?? false)
        XCTAssertTrue(tasks.first?.tags.contains("feature") ?? false)
        XCTAssertTrue(tasks.first?.tags.contains("backend") ?? false)
    }

    @MainActor
    func testTask_LinkedMessageIds() throws {
        let task = Task(title: "Linked Task")
        task.linkedMessageIds = ["msg-1", "msg-2", "msg-3"]
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.first?.linkedMessageIds.count, 3)
        XCTAssertTrue(tasks.first?.linkedMessageIds.contains("msg-1") ?? false)
    }

    // MARK: - Result Summary

    @MainActor
    func testTask_ResultSummary() throws {
        let task = Task(title: "Executed Task", status: .completed)
        task.resultSummary = "Task completed successfully with output: 42"
        task.completedAt = Date()
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)

        XCTAssertEqual(tasks.first?.resultSummary, "Task completed successfully with output: 42")
        XCTAssertNotNil(tasks.first?.completedAt)
    }
}
