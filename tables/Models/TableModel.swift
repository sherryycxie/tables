import Foundation
import SwiftData

enum TableStatus: String, Codable, CaseIterable {
    case active
    case archived
    case discussed
}

@Model
final class TableModel {
    var id: UUID
    var title: String
    var context: String?
    var status: TableStatus
    var createdAt: Date
    var updatedAt: Date
    var members: [String]
    var nextReminderDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \CardModel.table)
    var cards: [CardModel]

    @Relationship(deleteRule: .cascade, inverse: \NudgeModel.table)
    var nudges: [NudgeModel]

    init(
        id: UUID = UUID(),
        title: String,
        context: String? = nil,
        status: TableStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        members: [String] = [],
        nextReminderDate: Date? = nil,
        cards: [CardModel] = [],
        nudges: [NudgeModel] = []
    ) {
        self.id = id
        self.title = title
        self.context = context
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.members = members
        self.nextReminderDate = nextReminderDate
        self.cards = cards
        self.nudges = nudges
    }
}
