import XCTest
import SwiftData
@testable import Dobby

/// Tests for the ChatSession model
final class ChatSessionTests: XCTestCase {

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
    func testChatSession_DefaultValues() {
        let session = ChatSession(name: "Test Session")

        XCTAssertEqual(session.name, "Test Session")
        XCTAssertFalse(session.isArchived)
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.createdAt)
        XCTAssertNotNil(session.lastActiveAt)
    }

    @MainActor
    func testChatSession_WithIcon() {
        let session = ChatSession(name: "Work", icon: "briefcase")

        XCTAssertEqual(session.name, "Work")
        XCTAssertEqual(session.icon, "briefcase")
    }

    // MARK: - SwiftData Persistence Tests

    @MainActor
    func testChatSession_InsertAndFetch() throws {
        let session = ChatSession(name: "Persistent Session")
        context.insert(session)
        try context.save()

        let descriptor = FetchDescriptor<ChatSession>()
        let sessions = try context.fetch(descriptor)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.name, "Persistent Session")
    }

    @MainActor
    func testChatSession_Update() throws {
        let session = ChatSession(name: "Original Name")
        context.insert(session)
        try context.save()

        session.name = "Updated Name"
        session.icon = "star"
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<ChatSession>())

        XCTAssertEqual(sessions.first?.name, "Updated Name")
        XCTAssertEqual(sessions.first?.icon, "star")
    }

    @MainActor
    func testChatSession_Archive() throws {
        let session = ChatSession(name: "To Archive")
        context.insert(session)
        try context.save()

        XCTAssertFalse(session.isArchived)

        session.isArchived = true
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<ChatSession>())
        XCTAssertTrue(sessions.first?.isArchived ?? false)
    }

    @MainActor
    func testChatSession_FilterArchived() throws {
        let activeSession = ChatSession(name: "Active")
        let archivedSession = ChatSession(name: "Archived")
        archivedSession.isArchived = true

        context.insert(activeSession)
        context.insert(archivedSession)
        try context.save()

        let allSessions = try context.fetch(FetchDescriptor<ChatSession>())
        XCTAssertEqual(allSessions.count, 2)

        let activeSessions = allSessions.filter { !$0.isArchived }
        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions.first?.name, "Active")

        let archivedSessions = allSessions.filter { $0.isArchived }
        XCTAssertEqual(archivedSessions.count, 1)
        XCTAssertEqual(archivedSessions.first?.name, "Archived")
    }

    @MainActor
    func testChatSession_LastActiveAt() throws {
        let session = ChatSession(name: "Active Session")
        let originalLastActive = session.lastActiveAt
        context.insert(session)
        try context.save()

        // Simulate updating lastActiveAt
        Thread.sleep(forTimeInterval: 0.1)  // Small delay
        session.lastActiveAt = Date()
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<ChatSession>())
        XCTAssertGreaterThan(sessions.first?.lastActiveAt ?? Date.distantPast, originalLastActive)
    }

    @MainActor
    func testChatSession_SortByCreatedAt() throws {
        let oldSession = ChatSession(name: "Old Session")
        oldSession.createdAt = Date(timeIntervalSince1970: 1000)

        let newSession = ChatSession(name: "New Session")
        newSession.createdAt = Date(timeIntervalSince1970: 2000)

        context.insert(newSession)
        context.insert(oldSession)
        try context.save()

        var descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let sessions = try context.fetch(descriptor)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.first?.name, "Old Session")
        XCTAssertEqual(sessions.last?.name, "New Session")
    }

    @MainActor
    func testChatSession_Delete() throws {
        let session = ChatSession(name: "To Delete")
        context.insert(session)
        try context.save()

        context.delete(session)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<ChatSession>())
        XCTAssertEqual(sessions.count, 0)
    }

    // MARK: - Multiple Sessions

    @MainActor
    func testChatSession_MultipleSessions() throws {
        let sessions = [
            ChatSession(name: "Work", icon: "briefcase"),
            ChatSession(name: "Personal", icon: "person"),
            ChatSession(name: "Research", icon: "magnifyingglass")
        ]

        for session in sessions {
            context.insert(session)
        }
        try context.save()

        let fetchedSessions = try context.fetch(FetchDescriptor<ChatSession>())
        XCTAssertEqual(fetchedSessions.count, 3)

        let names = fetchedSessions.map { $0.name }
        XCTAssertTrue(names.contains("Work"))
        XCTAssertTrue(names.contains("Personal"))
        XCTAssertTrue(names.contains("Research"))
    }
}
