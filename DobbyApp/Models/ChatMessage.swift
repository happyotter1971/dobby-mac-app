import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var isFromUser: Bool
    var sessionKey: String
    var timestamp: Date
    var messageRole: String

    init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        sessionKey: String,
        timestamp: Date = Date(),
        messageRole: String
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.sessionKey = sessionKey
        self.timestamp = timestamp
        self.messageRole = messageRole
    }
}
