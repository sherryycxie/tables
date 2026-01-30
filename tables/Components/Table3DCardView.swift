import SwiftUI

struct Table3DCardView: View {
    let table: SupabaseTable
    let onArchive: (UUID) async -> Void
    let onUnarchive: (UUID) async -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text(table.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()

                if table.status == "discussed" {
                    Text("Discussed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            HStack(spacing: DesignSystem.Spacing.medium) {
                if !table.members.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(table.members.prefix(3), id: \.self) { member in
                            Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(String(member.prefix(1)).uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                )
                        }
                    }

                    Text("\(table.members.count) members")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Spacer()

                Text(table.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
        }
        .padding(DesignSystem.Padding.card)
        .frame(maxWidth: .infinity)
        .frame(height: DesignSystem.CardDimensions.carouselCardHeight)
        .background(
            ZStack {
                // Base card background
                DesignSystem.Colors.cardBackground

                // Subtle gradient overlay for dimension
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
        // Multi-layer shadows for realistic depth
        .shadow(color: DesignSystem.Shadows.cardElevated[0].color, radius: DesignSystem.Shadows.cardElevated[0].radius, y: DesignSystem.Shadows.cardElevated[0].y)
        .shadow(color: DesignSystem.Shadows.cardElevated[1].color, radius: DesignSystem.Shadows.cardElevated[1].radius, y: DesignSystem.Shadows.cardElevated[1].y)
        .contextMenu {
            if table.status == "active" || table.status == "discussed" {
                Button {
                    Task { await onArchive(table.id) }
                } label: {
                    Label("Archive Table", systemImage: "archivebox")
                }
            } else if table.status == "archived" {
                Button {
                    Task { await onUnarchive(table.id) }
                } label: {
                    Label("Unarchive Table", systemImage: "tray.and.arrow.up")
                }
            }
        }
    }
}
