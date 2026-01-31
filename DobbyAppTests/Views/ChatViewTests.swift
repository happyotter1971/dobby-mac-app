import XCTest
import SwiftUI
import SwiftData
@testable import Dobby

/// Tests for ChatView logic and behavior
final class ChatViewTests: XCTestCase {

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

    // MARK: - Message Filtering Tests

    @MainActor
    func testMessageFiltering_BySessionKey() throws {
        // Create messages for different sessions
        let session1Key = "session-1"
        let session2Key = "session-2"

        let msg1 = ChatMessage(content: "Session 1 message", isFromUser: true, sessionKey: session1Key, messageRole: "user")
        let msg2 = ChatMessage(content: "Session 2 message", isFromUser: true, sessionKey: session2Key, messageRole: "user")
        let msg3 = ChatMessage(content: "Another Session 1 message", isFromUser: false, sessionKey: session1Key, messageRole: "assistant")

        context.insert(msg1)
        context.insert(msg2)
        context.insert(msg3)
        try context.save()

        let allMessages = try context.fetch(FetchDescriptor<ChatMessage>())

        // Filter for session 1
        let session1Messages = allMessages.filter { $0.sessionKey.lowercased() == session1Key.lowercased() }
        XCTAssertEqual(session1Messages.count, 2)

        // Filter for session 2
        let session2Messages = allMessages.filter { $0.sessionKey.lowercased() == session2Key.lowercased() }
        XCTAssertEqual(session2Messages.count, 1)
    }

    @MainActor
    func testMessageFiltering_CaseInsensitive() throws {
        let sessionKey = "Main-Session"

        let msg1 = ChatMessage(content: "Message 1", isFromUser: true, sessionKey: sessionKey, messageRole: "user")
        let msg2 = ChatMessage(content: "Message 2", isFromUser: true, sessionKey: "MAIN-SESSION", messageRole: "user")
        let msg3 = ChatMessage(content: "Message 3", isFromUser: true, sessionKey: "main-session", messageRole: "user")

        context.insert(msg1)
        context.insert(msg2)
        context.insert(msg3)
        try context.save()

        let allMessages = try context.fetch(FetchDescriptor<ChatMessage>())

        // All should match when filtering case-insensitively
        let filteredMessages = allMessages.filter { $0.sessionKey.lowercased() == sessionKey.lowercased() }
        XCTAssertEqual(filteredMessages.count, 3)
    }

    @MainActor
    func testMessageFiltering_ByClearedAt() throws {
        let sessionKey = "test-session"
        let clearedAt = Date()

        // Message before clearedAt (should be filtered out)
        let oldMessage = ChatMessage(
            content: "Old message",
            isFromUser: true,
            sessionKey: sessionKey,
            timestamp: clearedAt.addingTimeInterval(-100),
            messageRole: "user"
        )

        // Message after clearedAt (should be shown)
        let newMessage = ChatMessage(
            content: "New message",
            isFromUser: true,
            sessionKey: sessionKey,
            timestamp: clearedAt.addingTimeInterval(100),
            messageRole: "user"
        )

        context.insert(oldMessage)
        context.insert(newMessage)
        try context.save()

        let allMessages = try context.fetch(FetchDescriptor<ChatMessage>())

        // Filter by clearedAt
        let visibleMessages = allMessages.filter { msg in
            msg.sessionKey.lowercased() == sessionKey.lowercased() &&
            msg.timestamp > clearedAt
        }

        XCTAssertEqual(visibleMessages.count, 1)
        XCTAssertEqual(visibleMessages.first?.content, "New message")
    }

    // MARK: - Message Sorting Tests

    @MainActor
    func testMessageSorting_ByTimestamp() throws {
        let sessionKey = "test-session"

        let timestamps = [
            Date(timeIntervalSince1970: 3000),
            Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 2000)
        ]

        for (index, timestamp) in timestamps.enumerated() {
            let msg = ChatMessage(
                content: "Message \(index)",
                isFromUser: true,
                sessionKey: sessionKey,
                timestamp: timestamp,
                messageRole: "user"
            )
            context.insert(msg)
        }
        try context.save()

        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let sortedMessages = try context.fetch(descriptor)

        XCTAssertEqual(sortedMessages[0].content, "Message 1")  // timestamp 1000
        XCTAssertEqual(sortedMessages[1].content, "Message 2")  // timestamp 2000
        XCTAssertEqual(sortedMessages[2].content, "Message 0")  // timestamp 3000
    }

    // MARK: - Send Button State Tests

    func testSendButton_DisabledWhenMessageEmpty() {
        let messageText = ""
        let isConnected = true

        let shouldBeDisabled = messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected

        XCTAssertTrue(shouldBeDisabled)
    }

    func testSendButton_DisabledWhenDisconnected() {
        let messageText = "Hello"
        let isConnected = false

        let shouldBeDisabled = messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected

        XCTAssertTrue(shouldBeDisabled)
    }

    func testSendButton_EnabledWhenConnectedAndHasText() {
        let messageText = "Hello, Dobby!"
        let isConnected = true

        let shouldBeDisabled = messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected

        XCTAssertFalse(shouldBeDisabled)
    }

    func testSendButton_DisabledWhenOnlyWhitespace() {
        let messageText = "   \n\t   "
        let isConnected = true

        let shouldBeDisabled = messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected

        XCTAssertTrue(shouldBeDisabled)
    }

    // MARK: - Connection Status Display Tests

    func testConnectionStatus_DisplayText() {
        XCTAssertEqual(ConnectionStatus.disconnected.displayText, "Disconnected")
        XCTAssertEqual(ConnectionStatus.connecting.displayText, "Connecting...")
        XCTAssertEqual(ConnectionStatus.connected.displayText, "Connected")
        XCTAssertEqual(ConnectionStatus.failed.displayText, "Connection Failed")
    }

    // MARK: - Message Deduplication Tests

    @MainActor
    func testHistoryDeduplication_ByContentAndTimestamp() throws {
        let sessionKey = "test-session"
        let timestamp = Date()

        // Existing message
        let existingMessage = ChatMessage(
            content: "Hello, world!",
            isFromUser: true,
            sessionKey: sessionKey,
            timestamp: timestamp,
            messageRole: "user"
        )
        context.insert(existingMessage)
        try context.save()

        // Incoming history messages (one duplicate, one new)
        let historyMessages = [
            (content: "Hello, world!", timestamp: timestamp, role: "user"),  // Duplicate
            (content: "New message", timestamp: timestamp.addingTimeInterval(100), role: "assistant")  // New
        ]

        let existingMessages = try context.fetch(FetchDescriptor<ChatMessage>())

        var addedCount = 0
        for history in historyMessages {
            let isDuplicate = existingMessages.contains { existing in
                existing.content == history.content &&
                abs(existing.timestamp.timeIntervalSince(history.timestamp)) < 1
            }

            if !isDuplicate {
                let newMsg = ChatMessage(
                    content: history.content,
                    isFromUser: history.role == "user",
                    sessionKey: sessionKey,
                    timestamp: history.timestamp,
                    messageRole: history.role
                )
                context.insert(newMsg)
                addedCount += 1
            }
        }
        try context.save()

        XCTAssertEqual(addedCount, 1)  // Only one new message added

        let finalMessages = try context.fetch(FetchDescriptor<ChatMessage>())
        XCTAssertEqual(finalMessages.count, 2)  // Original + 1 new
    }

    // MARK: - Message Role Tests

    @MainActor
    func testMessageRole_UserMessages() throws {
        let msg = ChatMessage(
            content: "User question",
            isFromUser: true,
            sessionKey: "test",
            messageRole: "user"
        )
        context.insert(msg)
        try context.save()

        let messages = try context.fetch(FetchDescriptor<ChatMessage>())

        XCTAssertTrue(messages.first?.isFromUser ?? false)
        XCTAssertEqual(messages.first?.messageRole, "user")
    }

    @MainActor
    func testMessageRole_AssistantMessages() throws {
        let msg = ChatMessage(
            content: "Assistant response",
            isFromUser: false,
            sessionKey: "test",
            messageRole: "assistant"
        )
        context.insert(msg)
        try context.save()

        let messages = try context.fetch(FetchDescriptor<ChatMessage>())

        XCTAssertFalse(messages.first?.isFromUser ?? true)
        XCTAssertEqual(messages.first?.messageRole, "assistant")
    }
}
