import Foundation
import SwiftData

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var status: TaskStatus
    var priority: TaskPriority
    var source: TaskSource
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var notes: String?
    var linkedMessageIds: [String]
    var progressPercent: Int?
    var resultSummary: String?
    var dueDate: Date?
    var reminder: Date?
    var tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        status: TaskStatus = .backlog,
        priority: TaskPriority = .medium,
        source: TaskSource = .user,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String? = nil,
        linkedMessageIds: [String] = [],
        progressPercent: Int? = nil,
        resultSummary: String? = nil,
        dueDate: Date? = nil,
        reminder: Date? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.priority = priority
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.notes = notes
        self.linkedMessageIds = linkedMessageIds
        self.progressPercent = progressPercent
        self.resultSummary = resultSummary
        self.dueDate = dueDate
        self.reminder = reminder
        self.tags = tags
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case backlog
    case inProcess
    case completed
    case archived
}

enum TaskPriority: String, Codable, CaseIterable {
    case high
    case medium
    case low
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "green"
        }
    }
    
    var emoji: String {
        switch self {
        case .high: return "🔴"
        case .medium: return "🟠"
        case .low: return "🟢"
        }
    }
}

enum TaskSource: String, Codable, CaseIterable {
    case dobby
    case user
    case automated
}
