import Foundation
import SwiftData

enum CardStatus: String, Codable {
    case active
    case discussed
}

@Model
final class CardModel {
    var id: UUID
    var title: String?
    var body: String
    var linkURL: String?
    var createdAt: Date
    var authorName: String
    var status: CardStatus

    var table: TableModel?

    @Relationship(deleteRule: .cascade, inverse: \CommentModel.card)
    var comments: [CommentModel]

    init(
        id: UUID = UUID(),
        title: String? = nil,
        body: String,
        linkURL: String? = nil,
        createdAt: Date = Date(),
        authorName: String,
        status: CardStatus = .active,
        table: TableModel? = nil,
        comments: [CommentModel] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.linkURL = linkURL
        self.createdAt = createdAt
        self.authorName = authorName
        self.status = status
        self.table = table
        self.comments = comments
    }
}
