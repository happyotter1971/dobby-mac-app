import XCTest
import SwiftData
@testable import Dobby

/// Tests for the ChatMessage model
final class ChatMessageTests: XCTestCase {

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
    func testChatMessage_UserMessage() {
        let message = ChatMessage(
            content: "Hello, Dobby!",
            isFromUser: true,
            sessionKey: "main",
            messageRole: "user"
        )

        XCTAssertEqual(message.content, "Hello, Dobby!")
        XCTAssertTrue(message.isFromUser)
        XCTAssertEqual(message.sessionKey, "main")
        XCTAssertEqual(message.messageRole, "user")
        XCTAssertNotNil(message.id)
        XCTAssertNotNil(message.timestamp)
    }

    @MainActor
    func testChatMessage_AssistantMessage() {
        let message = ChatMessage(
            content: "Hello! How can I help you?",
            isFromUser: false,
            sessionKey: "main",
            messageRole: "assistant"
        )

        XCTAssertEqual(message.content, "Hello! How can I help you?")
        XCTAssertFalse(message.isFromUser)
        XCTAssertEqual(message.sessionKey, "main")
        XCTAssertEqual(message.messageRole, "assistant")
    }

    @MainActor
    func testChatMessage_CustomTimestamp() {
        let customDate = Date(timeIntervalSince1970: 1000000)
        let message = ChatMessage(
            content: "Test",
            isFromUser: true,
            sessionKey: "test",
            timestamp: customDate,
            messageRole: "user"
        )

        XCTAssertEqual(message.timestamp, customDate)
    }

    // MARK: - SwiftData Persistence Tests

    @MainActor
    func testChatMessage_InsertAndFetch() throws {
        let message = ChatMessage(
            content: "Persistent message",
            isFromUser: true,
            sessionKey: "main",
            messageRole: "user"
        )
        context.insert(message)
        try context.save()

        let descriptor = FetchDescriptor<ChatMessage>()
        let messages = try context.fetch(descriptor)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.content, "Persistent message")
    }

    @MainActor
    func testChatMessage_FilterBySession() throws {
        let session1Message = ChatMessage(
            content: "Session 1 message",
            isFromUser: true,
            sessionKey: "session-1",
            messageRole: "user"
        )
        let session2Message = ChatMessage(
            content: "Session 2 message",
            isFromUser: true,
            sessionKey: "session-2",
            messageRole: "user"
        )

        context.insert(session1Message)
        context.insert(session2Message)
        try context.save()

        let allMessages = try context.fetch(FetchDescriptor<ChatMessage>())
        XCTAssertEqual(allMessages.count, 2)

        let session1Messages = allMessages.filter { $0.sessionKey == "session-1" }
        XCTAssertEqual(session1Messages.count, 1)
        XCTAssertEqual(session1Messages.first?.content, "Session 1 message")
    }

    @MainActor
    func testChatMessage_SortByTimestamp() throws {
        let oldMessage = ChatMessage(
            content: "Old message",
            isFromUser: true,
            sessionKey: "main",
            timestamp: Date(timeIntervalSince1970: 1000),
            messageRole: "user"
        )
        let newMessage = ChatMessage(
            content: "New message",
            isFromUser: true,
            sessionKey: "main",
            timestamp: Date(timeIntervalSince1970: 2000),
            messageRole: "user"
        )

        context.insert(newMessage)
        context.insert(oldMessage)
        try context.save()

        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let messages = try context.fetch(descriptor)

        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.first?.content, "Old message")
        XCTAssertEqual(messages.last?.content, "New message")
    }

    @MainActor
    func testChatMessage_FilterByRole() throws {
        let userMessage = ChatMessage(
            content: "User question",
            isFromUser: true,
            sessionKey: "main",
            messageRole: "user"
        )
        let assistantMessage = ChatMessage(
            content: "Assistant answer",
            isFromUser: false,
            sessionKey: "main",
            messageRole: "assistant"
        )

        context.insert(userMessage)
        context.insert(assistantMessage)
        try context.save()

        let allMessages = try context.fetch(FetchDescriptor<ChatMessage>())

        let userMessages = allMessages.filter { $0.isFromUser }
        XCTAssertEqual(userMessages.count, 1)
        XCTAssertEqual(userMessages.first?.messageRole, "user")

        let assistantMessages = allMessages.filter { !$0.isFromUser }
        XCTAssertEqual(assistantMessages.count, 1)
        XCTAssertEqual(assistantMessages.first?.messageRole, "assistant")
    }

    // MARK: - Content Tests

    @MainActor
    func testChatMessage_EmptyContent() {
        let message = ChatMessage(
            content: "",
            isFromUser: true,
            sessionKey: "main",
            messageRole: "user"
        )

        XCTAssertTrue(message.content.isEmpty)
    }

    @MainActor
    func testChatMessage_LongContent() throws {
        let longContent = String(repeating: "A", count: 10000)
        let message = ChatMessage(
            content: longContent,
            isFromUser: false,
            sessionKey: "main",
            messageRole: "assistant"
        )

        context.insert(message)
        try context.save()

        let messages = try context.fetch(FetchDescriptor<ChatMessage>())
        XCTAssertEqual(messages.first?.content.count, 10000)
    }

    @MainActor
    func testChatMessage_MarkdownContent() throws {
        let markdownContent = """
        Here's some code:

        ```swift
        func hello() {
            print("Hello!")
        }
        ```

        And a list:
        - Item 1
        - Item 2
        """

        let message = ChatMessage(
            content: markdownContent,
            isFromUser: false,
            sessionKey: "main",
            messageRole: "assistant"
        )

        context.insert(message)
        try context.save()

        let messages = try context.fetch(FetchDescriptor<ChatMessage>())
        XCTAssertTrue(messages.first?.content.contains("```swift") ?? false)
    }

    // MARK: - Delete Tests

    @MainActor
    func testChatMessage_Delete() throws {
        let message = ChatMessage(
            content: "To be deleted",
            isFromUser: true,
            sessionKey: "main",
            messageRole: "user"
        )
        context.insert(message)
        try context.save()

        context.delete(message)
        try context.save()

        let messages = try context.fetch(FetchDescriptor<ChatMessage>())
        XCTAssertEqual(messages.count, 0)
    }
}
