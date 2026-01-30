import Foundation
import SwiftData

@Model
final class CommentModel {
    var id: UUID
    var body: String
    var createdAt: Date
    var authorName: String

    var card: CardModel?

    init(
        id: UUID = UUID(),
        body: String,
        createdAt: Date = Date(),
        authorName: String,
        card: CardModel? = nil
    ) {
        self.id = id
        self.body = body
        self.createdAt = createdAt
        self.authorName = authorName
        self.card = card
    }
}
