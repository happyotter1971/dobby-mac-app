import XCTest
import SwiftUI
import SwiftData
import AppKit
import SnapshotTesting
@testable import Dobby

/// Snapshot tests for TasksView visual regression
/// Note: Run with isRecording = true first to generate reference snapshots
final class TasksViewSnapshotTests: XCTestCase {

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
        // Set to true to record new snapshots
        isRecording = false
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Task Priority Unit Tests

    func testTaskPriority_Emoji() {
        XCTAssertEqual(TaskPriority.high.emoji, "🔴")
        XCTAssertEqual(TaskPriority.medium.emoji, "🟠")
        XCTAssertEqual(TaskPriority.low.emoji, "🟢")
    }

    func testTaskPriority_Color() {
        XCTAssertEqual(TaskPriority.high.color, "red")
        XCTAssertEqual(TaskPriority.medium.color, "orange")
        XCTAssertEqual(TaskPriority.low.color, "green")
    }

    // MARK: - Task Status Unit Tests

    func testTaskStatus_RawValues() {
        XCTAssertEqual(TaskStatus.backlog.rawValue, "backlog")
        XCTAssertEqual(TaskStatus.inProcess.rawValue, "inProcess")
        XCTAssertEqual(TaskStatus.completed.rawValue, "completed")
        XCTAssertEqual(TaskStatus.archived.rawValue, "archived")
    }

    // MARK: - Task Source Unit Tests

    func testTaskSource_RawValues() {
        XCTAssertEqual(TaskSource.dobby.rawValue, "dobby")
        XCTAssertEqual(TaskSource.user.rawValue, "user")
        XCTAssertEqual(TaskSource.automated.rawValue, "automated")
    }

    // MARK: - Task Creation Tests

    @MainActor
    func testCreateTask_HighPriority() {
        let task = Dobby.Task(title: "High Priority Task", status: .backlog, priority: .high)

        XCTAssertEqual(task.title, "High Priority Task")
        XCTAssertEqual(task.status, .backlog)
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.priority.emoji, "🔴")
    }

    @MainActor
    func testCreateTask_WithProgress() {
        let task = Dobby.Task(title: "In Progress Task", status: .inProcess, priority: .medium)
        task.progressPercent = 50

        XCTAssertEqual(task.status, .inProcess)
        XCTAssertEqual(task.progressPercent, 50)
    }

    @MainActor
    func testCreateTask_Completed() {
        let task = Dobby.Task(title: "Completed Task", status: .completed, priority: .low)
        task.completedAt = Date()
        task.resultSummary = "Task completed successfully"

        XCTAssertEqual(task.status, .completed)
        XCTAssertNotNil(task.completedAt)
        XCTAssertNotNil(task.resultSummary)
    }

    // MARK: - CaseIterable Tests

    func testTaskPriority_AllCases() {
        let allCases = TaskPriority.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.low))
    }

    func testTaskStatus_AllCases() {
        let allCases = TaskStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.backlog))
        XCTAssertTrue(allCases.contains(.inProcess))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.archived))
    }

    func testTaskSource_AllCases() {
        let allCases = TaskSource.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.dobby))
        XCTAssertTrue(allCases.contains(.user))
        XCTAssertTrue(allCases.contains(.automated))
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testTaskCard_HighPriority_Snapshot() {
        let task = Dobby.Task(title: "High Priority Task", status: .backlog, priority: .high)

        let view = TaskCardTestView(task: task)
            .frame(width: 280)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 280, height: 100))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testTaskCard_InProgress_Snapshot() {
        let task = Dobby.Task(title: "In Progress Task", status: .inProcess, priority: .medium)
        task.progressPercent = 65

        let view = TaskCardTestView(task: task)
            .frame(width: 280)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 280, height: 120))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testTaskCard_Completed_Snapshot() {
        let task = Dobby.Task(title: "Completed Task", status: .completed, priority: .low)
        task.completedAt = Date()
        task.resultSummary = "Task completed successfully with all objectives met."

        let view = TaskCardTestView(task: task)
            .frame(width: 280)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 280, height: 120))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testTaskCard_AllPriorities_Snapshot() {
        let highTask = Dobby.Task(title: "High Priority", status: .backlog, priority: .high)
        let mediumTask = Dobby.Task(title: "Medium Priority", status: .backlog, priority: .medium)
        let lowTask = Dobby.Task(title: "Low Priority", status: .backlog, priority: .low)

        let view = VStack(spacing: 12) {
            TaskCardTestView(task: highTask)
            TaskCardTestView(task: mediumTask)
            TaskCardTestView(task: lowTask)
        }
        .frame(width: 280)
        .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 280, height: 350))
        assertSnapshot(of: hostingView, as: .image)
    }
}

// MARK: - Helper View for Testing

struct TaskCardTestView: View {
    let task: Dobby.Task

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.priority.emoji)

                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            if task.status == .inProcess, let progress = task.progressPercent {
                ProgressView(value: Double(progress) / 100.0)
                    .progressViewStyle(.linear)
                Text("Running... \(progress)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if task.status == .completed, task.resultSummary != nil {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("View Result")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            HStack {
                Text(task.source.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(task.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
