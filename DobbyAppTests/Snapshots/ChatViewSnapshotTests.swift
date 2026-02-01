import XCTest
import SwiftUI
import SwiftData
import AppKit
import SnapshotTesting
@testable import Dobby

/// Snapshot tests for ChatView visual regression
/// Note: Run with isRecording = true first to generate reference snapshots
final class ChatViewSnapshotTests: XCTestCase {

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
        isRecording = true
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Connection Status Unit Tests

    func testConnectionStatus_DisplayText() {
        XCTAssertEqual(ConnectionStatus.disconnected.displayText, "Disconnected")
        XCTAssertEqual(ConnectionStatus.connecting.displayText, "Connecting...")
        XCTAssertEqual(ConnectionStatus.connected.displayText, "Connected")
        XCTAssertEqual(ConnectionStatus.failed.displayText, "Connection Failed")
    }

    // MARK: - Message Creation Tests

    @MainActor
    func testCreateUserMessage() throws {
        let message = ChatMessage(
            content: "Hello, Dobby!",
            isFromUser: true,
            sessionKey: "test",
            messageRole: "user"
        )

        XCTAssertTrue(message.isFromUser)
        XCTAssertEqual(message.messageRole, "user")
        XCTAssertEqual(message.content, "Hello, Dobby!")
    }

    @MainActor
    func testCreateAssistantMessage() throws {
        let message = ChatMessage(
            content: "Hello! How can I help?",
            isFromUser: false,
            sessionKey: "test",
            messageRole: "assistant"
        )

        XCTAssertFalse(message.isFromUser)
        XCTAssertEqual(message.messageRole, "assistant")
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testMessageBubble_UserMessage_Snapshot() {
        let message = ChatMessage(
            content: "Hello, Dobby! How can you help me today?",
            isFromUser: true,
            sessionKey: "test",
            messageRole: "user"
        )

        let view = MessageBubbleView(message: message)
            .frame(width: 500)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 100))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testMessageBubble_AssistantMessage_Snapshot() {
        let message = ChatMessage(
            content: "Hello! I'm Dobby, your helpful assistant. I can help you with many tasks including answering questions, writing code, and more.",
            isFromUser: false,
            sessionKey: "test",
            messageRole: "assistant"
        )

        let view = MessageBubbleView(message: message)
            .frame(width: 500)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 120))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testMessageBubble_LongMessage_Snapshot() {
        let longContent = """
        This is a longer message that spans multiple lines to test how the message bubble handles text wrapping and vertical expansion. It should display properly without any truncation or layout issues.

        Here's a second paragraph to test paragraph spacing as well.
        """

        let message = ChatMessage(
            content: longContent,
            isFromUser: false,
            sessionKey: "test",
            messageRole: "assistant"
        )

        let view = MessageBubbleView(message: message)
            .frame(width: 500)
            .padding()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 200))
        assertSnapshot(of: hostingView, as: .image)
    }

    @MainActor
    func testConnectionStatusView_AllStates_Snapshot() {
        let view = VStack(spacing: 16) {
            ConnectionStatusTestView(status: .disconnected)
            ConnectionStatusTestView(status: .connecting)
            ConnectionStatusTestView(status: .connected)
            ConnectionStatusTestView(status: .failed)
        }
        .padding()
        .frame(width: 200)

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 150))
        assertSnapshot(of: hostingView, as: .image)
    }
}

// MARK: - Helper Views for Testing

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.controlBackgroundColor))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(12)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct ConnectionStatusTestView: View {
    let status: ConnectionStatus

    private var statusColor: Color {
        switch status {
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .connected: return .green
        case .failed: return .red
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor).frame(width: 8, height: 8)
            Text(status.displayText).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
