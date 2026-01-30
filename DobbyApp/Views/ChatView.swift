import SwiftUI

struct ChatView: View {
    let sessionName: String
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Session tabs
            SessionTabsView()
            
            // Messages area
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(24)
            }
            
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.secondary)
                
                TextField("Type or speak...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...10)
                    .onSubmit {
                        send Message()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderless)
                .disabled(messageText.isEmpty)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = Message(
            content: messageText,
            isFromUser: true
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // Simulate response (in real app, send to WebSocket)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = Message(
                content: "This is a placeholder response. WebSocket connection coming in Phase 2!",
                isFromUser: false
            )
            messages.append(response)
        }
    }
}

struct SessionTabsView: View {
    var body: some View {
        HStack(spacing: 8) {
            SessionTab(name: "Main", isActive: true)
            SessionTab(name: "Research", isActive: false)
            SessionTab(name: "Strategy", isActive: false)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

struct SessionTab: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        Text(name)
            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
            .foregroundStyle(isActive ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isFromUser {
                Image(systemName: "sparkles")
                    .foregroundStyle(.accent Color)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(16)
                    .background(message.isFromUser ? Color.accentColor : Color(.windowBackgroundColor))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(message.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if message.isFromUser {
                Spacer()
            }
        }
        .frame(maxWidth: 800, alignment: message.isFromUser ? .trailing : .leading)
    }
}

// Message model
struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
}

#Preview {
    ChatView(sessionName: "Main")
        .frame(width: 1000, height: 700)
}
