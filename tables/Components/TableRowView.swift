import SwiftUI

struct TableRowView: View {
    let table: TableModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                Text(table.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)

                if table.status == .discussed {
                    Text("Discussed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(relativeUpdatedAt)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Text("Group of \(table.members.count) members")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)

            HStack {
                AvatarStackView(members: table.members)

                Spacer()

                if let reminderDate = table.nextReminderDate {
                    ReminderChipView(date: reminderDate)
                }
            }
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }

    private var relativeUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: table.updatedAt, relativeTo: Date())
    }
}

#Preview {
    TableRowView(table: TableModel(title: "Career crossroads", members: ["Sarah", "Marcus", "James"]))
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
