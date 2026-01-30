import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 200, height: 200)

                Image(systemName: "table.furniture")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            VStack(spacing: DesignSystem.Spacing.small) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .font(.body)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: actionTitle, systemImage: "plus", action: action)
        }
        .padding(.horizontal, DesignSystem.Padding.screen)
    }
}

#Preview {
    EmptyStateView(
        title: "No tables yet",
        message: "Start a conversation that matters.",
        actionTitle: "Create your first Table"
    ) {}
}
