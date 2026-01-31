import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var name: String
    var icon: String // SF Symbol name
    var createdAt: Date
    var lastActiveAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "bubble.left.fill",
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isArchived = isArchived
    }
}
