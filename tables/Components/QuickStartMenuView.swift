import SwiftUI

struct QuickStartMenuView: View {
    let onLogWin: () -> Void
    let onDeepReflection: () -> Void
    let onStartTable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 120)

            Text("What would you like to do?")
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)

            Text("Select an activity to begin")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .padding(.bottom, DesignSystem.Spacing.large)

            VStack(spacing: DesignSystem.Spacing.small) {
                actionCard(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Log a Win",
                    subtitle: "Capture a quick victory"
                ) {
                    onLogWin()
                }

                actionCard(
                    icon: "leaf.fill",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Deep Reflection",
                    subtitle: "Take time to explore your thoughts"
                ) {
                    onDeepReflection()
                }

                actionCard(
                    icon: "rectangle.3.group.fill",
                    iconColor: .purple,
                    title: "Start a Table",
                    subtitle: "Begin a new discussion with others"
                ) {
                    onStartTable()
                }
            }
            .padding(.horizontal, DesignSystem.Padding.screen)

            Spacer()

            Button(action: onDismiss) {
                Circle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    )
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.screenBackground)
    }

    private func actionCard(
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
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

#Preview {
    QuickStartMenuView(
        onLogWin: {},
        onDeepReflection: {},
        onStartTable: {},
        onDismiss: {}
    )
}
