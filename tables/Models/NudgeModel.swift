import Foundation
import SwiftData

@Model
final class NudgeModel {
    var id: UUID
    var createdAt: Date
    var authorName: String
    var message: String?

    var table: TableModel?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        authorName: String,
        message: String? = nil,
        table: TableModel? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.authorName = authorName
        self.message = message
        self.table = table
    }
}
