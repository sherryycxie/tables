import SwiftUI

struct RecentTablesSectionView: View {
    let tables: [SupabaseTable]
    let onViewAll: () -> Void
    let onSelectTable: (SupabaseTable) -> Void

    private var recentTables: [SupabaseTable] {
        tables
            .filter { $0.status == "active" || $0.status == "discussed" }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("RECENT TABLES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .tracking(0.5)

                Spacer()

                Button(action: onViewAll) {
                    Text("View All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if recentTables.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTables.enumerated()), id: \.element.id) { index, table in
                        RecentTableRowView(table: table) {
                            onSelectTable(table)
                        }

                        if index < recentTables.count - 1 {
                            Divider()
                                .padding(.leading, DesignSystem.Padding.card)
                        }
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "rectangle.3.group")
                .font(.title2)
                .foregroundStyle(DesignSystem.Colors.mutedText)

            Text("No tables yet")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Padding.card)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

struct RecentTableRowView: View {
    let table: SupabaseTable
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: DesignSystem.Spacing.small) {
                        if !table.members.isEmpty {
                            Text("\(table.members.count) members")
                                .font(.caption)
                                .foregroundStyle(DesignSystem.Colors.mutedText)
                        }

                        Text(table.updatedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
            .padding(DesignSystem.Padding.card)
        }
    }
}

#Preview {
    RecentTablesSectionView(
        tables: [],
        onViewAll: {},
        onSelectTable: { _ in }
    )
    .padding()
    .background(DesignSystem.Colors.screenBackground)
}
