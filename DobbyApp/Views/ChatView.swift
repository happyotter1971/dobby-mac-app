import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var messageText: String = ""
    @State private var wsManager = WebSocketManager.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSettings
    
    @Query(sort: \ChatMessage.timestamp, order: .forward) private var messages: [ChatMessage]
    
    private var filteredMessages: [ChatMessage] {
        messages.filter { $0.sessionKey == settings.activeSessionId }
    }

    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusView(status: wsManager.connectionStatus)
                .padding(.horizontal)
                .background(.ultraThinMaterial)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(filteredMessages) { message in
                            MessageBubble(message: message)
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

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 50) }
            
            VStack(alignment: .leading, spacing: 4) {
                RichMarkdownText(content: message.content)
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
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(status.color).frame(width: 8, height: 8)
            Text(status.displayText).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
