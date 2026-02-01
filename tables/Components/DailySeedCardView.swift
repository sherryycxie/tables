import SwiftUI

struct DailySeedCardView: View {
    let prompt: DailyPrompt
    let onPlantSeed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(prompt.question)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(prompt.explanation)
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)

            Button(action: onPlantSeed) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "leaf.fill")
                    Text("Plant this seed")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.primary.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Padding.card)
        .frame(alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    DailySeedCardView(
        prompt: DailyPrompts.todaysPrompt,
        onPlantSeed: {}
    )
    .padding()
    .background(DesignSystem.Colors.screenBackground)
}
