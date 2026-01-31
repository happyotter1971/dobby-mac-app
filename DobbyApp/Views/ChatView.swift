import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var messageText: String = ""
    @State private var wsManager = WebSocketManager.shared
    @State private var clearedAfter: Date? = nil
    @State private var isWaitingForResponse = false
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSettings

    @Query(sort: \ChatMessage.timestamp, order: .forward) private var messages: [ChatMessage]

    private var filteredMessages: [ChatMessage] {
        messages.filter { message in
            message.sessionKey.lowercased() == settings.activeSessionId.lowercased() &&
            (clearedAfter == nil || message.timestamp > clearedAfter!)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with connection status and clear button
            HStack {
                ConnectionStatusView(status: wsManager.connectionStatus)
                Spacer()
                if !filteredMessages.isEmpty {
                    Button("Clear") {
                        clearChat()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Clear chat view")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(filteredMessages) { message in
                            MessageBubble(message: message, onSuggestionTapped: { suggestion in
                                messageText = suggestion
                            })
                        }

                        if isWaitingForResponse {
                            TypingIndicator()
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(24)
                }
                .onChange(of: filteredMessages.count) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            MessageInputView(
                messageText: $messageText,
                isConnected: wsManager.isConnected,
                onSend: sendMessage
            )
        }
        .onAppear {
            setupMessageHandler()
            loadHistoryFromGateway()
        }
        .onChange(of: settings.activeSessionId) {
            clearedAfter = nil  // Reset clear state when switching sessions
            loadHistoryFromGateway()
        }
    }
    
    private func loadHistoryFromGateway() {
        guard !settings.activeSessionId.isEmpty else { return }
        wsManager.loadChatHistory(sessionId: settings.activeSessionId)
    }

    private func setupMessageHandler() {
        wsManager.onMessageReceived = { gatewayMessage in
            DispatchQueue.main.async {
                // Hide typing indicator when response arrives
                if !gatewayMessage.isFromUser {
                    isWaitingForResponse = false
                }

                // The query will automatically update the view if the session matches
                let chatMessage = ChatMessage(
                    content: gatewayMessage.content,
                    isFromUser: gatewayMessage.isFromUser,
                    sessionKey: gatewayMessage.sessionKey,
                    messageRole: gatewayMessage.isFromUser ? "user" : "assistant"
                )
                modelContext.insert(chatMessage)
            }
        }
        
        wsManager.onHistoryLoaded = { historyMessages in
            DispatchQueue.main.async {
                let existingMessages = try? modelContext.fetch(FetchDescriptor<ChatMessage>())
                for historyMsg in historyMessages {
                    let isDuplicate = existingMessages?.contains {
                        $0.content == historyMsg.content && abs($0.timestamp.timeIntervalSince(historyMsg.timestamp)) < 1
                    } ?? false

                    if !isDuplicate {
                        let chatMessage = ChatMessage(
                            content: historyMsg.content,
                            isFromUser: historyMsg.role == "user",
                            sessionKey: settings.activeSessionId,
                            timestamp: historyMsg.timestamp,
                            messageRole: historyMsg.role
                        )
                        modelContext.insert(chatMessage)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty, wsManager.isConnected, !settings.activeSessionId.isEmpty else { return }

        let chatMessage = ChatMessage(
            content: messageText,
            isFromUser: true,
            sessionKey: settings.activeSessionId,
            messageRole: "user"
        )
        modelContext.insert(chatMessage)

        wsManager.sendChatMessage(content: messageText, sessionId: settings.activeSessionId)
        messageText = ""
        isWaitingForResponse = true
    }

    private func clearChat() {
        // Just hide messages in UI, don't delete from storage
        clearedAfter = Date()
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    let isConnected: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill").foregroundColor(.secondary)
            
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .onSubmit(onSend)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty || !isConnected)
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var onSuggestionTapped: ((String) -> Void)?

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 50) }

            VStack(alignment: .leading, spacing: 4) {
                RichMarkdownText(content: message.content, onSuggestionTapped: message.isFromUser ? nil : onSuggestionTapped)
                    .padding(12)
                    .background(message.isFromUser ? .blue : Color(.textBackgroundColor))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }

            if !message.isFromUser { Spacer(minLength: 50) }
        }
    }
}

struct ConnectionStatusView: View {
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

struct TypingIndicator: View {
    @State private var animationOffset = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(animationOffset == index ? 1.0 : 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.textBackgroundColor))
            .cornerRadius(16)

            Spacer(minLength: 50)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}
