import SwiftUI

struct QuickStartMenuView: View {
    let onLogWin: () -> Void
    let onDeepReflection: () -> Void
    let onStartTable: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, DesignSystem.Spacing.medium)

            VStack(spacing: 0) {
                actionRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Log a Win",
                    subtitle: "Capture a quick victory"
                ) {
                    onLogWin()
                }

                Divider()
                    .padding(.leading, 60)

                actionRow(
                    icon: "leaf.fill",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Deep Reflection",
                    subtitle: "Take time to explore your thoughts"
                ) {
                    onDeepReflection()
                }

                Divider()
                    .padding(.leading, 60)

                actionRow(
                    icon: "rectangle.3.group.fill",
                    iconColor: .purple,
                    title: "Start a Table",
                    subtitle: "Begin a new discussion with others"
                ) {
                    onStartTable()
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .padding(.horizontal, DesignSystem.Padding.screen)

            Spacer()
        }
        .background(DesignSystem.Colors.screenBackground)
    }

    private func actionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(iconColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                        .lineLimit(1)
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
    QuickStartMenuView(
        onLogWin: {},
        onDeepReflection: {},
        onStartTable: {}
    )
}
