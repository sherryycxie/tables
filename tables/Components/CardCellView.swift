import SwiftUI

struct CardCellView: View {
    let card: CardModel

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack(alignment: .top) {
                    if let title = card.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    if card.status == .discussed {
                        Text("Discussed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary)
                            .clipShape(Capsule())
                    }
                }

                Text(card.body)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(card.authorName) - \(relativeCreatedAt)")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.primary.opacity(0.2))
                .frame(width: 64, height: 64)
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }

    private var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: card.createdAt, relativeTo: Date())
    }
}

#Preview {
    CardCellView(card: CardModel(title: "Success right now", body: "What does success feel like to you right now?", authorName: "Sarah"))
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
