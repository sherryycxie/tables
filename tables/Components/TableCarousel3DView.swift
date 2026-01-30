import SwiftUI

struct TableCarousel3DView: View {
    let tables: [SupabaseTable]
    let onArchive: (UUID) async -> Void
    let onUnarchive: (UUID) async -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ForEach(tables) { table in
                NavigationLink(destination: SupabaseTableDetailView(table: table)) {
                    Table3DCardView(
                        table: table,
                        onArchive: onArchive,
                        onUnarchive: onUnarchive
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
