import Foundation
import SwiftData

enum SeedData {
    static func insertIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<TableModel>()
        descriptor.fetchLimit = 1
        let hasData = (try? context.fetch(descriptor))?.isEmpty == false
        guard !hasData else { return }

        let career = TableModel(
            title: "Career crossroads",
            context: "Discuss options and values for next roles.",
            status: .active,
            members: ["Sarah", "Marcus", "James", "Anna"],
            nextReminderDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
        let finance = TableModel(
            title: "Finance & Values",
            context: "Align money decisions with long-term values.",
            status: .active,
            members: ["Alex", "Jordan", "You"]
        )
        let archived = TableModel(
            title: "Travel reflections",
            context: "Notes from the Iceland trip.",
            status: .archived,
            members: ["Mina", "Kai"]
        )

        let card1 = CardModel(
            title: "Success right now",
            body: "What does success feel like to you right now?",
            authorName: "Sarah",
            table: career
        )
        let card2 = CardModel(
            title: nil,
            body: "Is your current path sustainable for the next 5 years?",
            authorName: "Marcus",
            table: career
        )
        career.cards.append(contentsOf: [card1, card2])

        let financeCard = CardModel(
            title: nil,
            body: "What’s our philosophy on money and generosity?",
            authorName: "Alex",
            table: finance
        )
        finance.cards.append(financeCard)

        let comment1 = CommentModel(
            body: "Generosity should scale with our growth, not stay fixed.",
            authorName: "Jordan",
            card: financeCard
        )
        let comment2 = CommentModel(
            body: "Time is part of generosity too.",
            authorName: "Sarah",
            card: financeCard
        )
        financeCard.comments.append(contentsOf: [comment1, comment2])

        context.insert(career)
        context.insert(finance)
        context.insert(archived)
    }
}
