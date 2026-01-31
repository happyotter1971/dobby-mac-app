import SwiftData
import SwiftUI
@testable import Dobby

/// Helpers for creating in-memory SwiftData containers for testing
enum TestModelContainer {
    /// Creates an in-memory ModelContainer for testing
    @MainActor
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            ChatMessage.self,
            ChatSession.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Creates a test ModelContext from the container
    @MainActor
    static func createContext() throws -> ModelContext {
        let container = try create()
        return container.mainContext
    }

    /// Creates sample test data in the provided context
    @MainActor
    static func populateTestData(in context: ModelContext) throws {
        // Sample tasks for each status
        let backlogTask = Task(
            title: "Backlog Task",
            status: .backlog,
            priority: .high,
            source: .user
        )

        let inProgressTask = Task(
            title: "In Progress Task",
            status: .inProcess,
            priority: .medium,
            source: .dobby,
            progressPercent: 50
        )

        let completedTask = Task(
            title: "Completed Task",
            status: .completed,
            priority: .low,
            source: .user,
            resultSummary: "Task completed successfully"
        )
        completedTask.completedAt = Date()

        context.insert(backlogTask)
        context.insert(inProgressTask)
        context.insert(completedTask)

        // Sample chat session
        let session = ChatSession(name: "Test Session")
        context.insert(session)

        // Sample messages
        let userMessage = ChatMessage(
            content: "Hello, Dobby!",
            isFromUser: true,
            sessionKey: session.id.uuidString,
            messageRole: "user"
        )

        let assistantMessage = ChatMessage(
            content: "Hello! How can I help you today?",
            isFromUser: false,
            sessionKey: session.id.uuidString,
            messageRole: "assistant"
        )

        context.insert(userMessage)
        context.insert(assistantMessage)

        try context.save()
    }
}

// MARK: - SwiftUI Test View Wrapper

/// Wrapper view for testing SwiftUI views with SwiftData
struct TestViewWrapper<Content: View>: View {
    let content: Content
    let container: ModelContainer

    init(
        container: ModelContainer,
        @ViewBuilder content: () -> Content
    ) {
        self.container = container
        self.content = content()
    }

    var body: some View {
        content
            .modelContainer(container)
    }
}

/// Wrapper for snapshot testing with fixed frame
struct SnapshotWrapper<Content: View>: View {
    let content: Content
    let size: CGSize
    let colorScheme: ColorScheme

    init(
        size: CGSize = CGSize(width: 800, height: 600),
        colorScheme: ColorScheme = .light,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.colorScheme = colorScheme
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .preferredColorScheme(colorScheme)
    }
}
