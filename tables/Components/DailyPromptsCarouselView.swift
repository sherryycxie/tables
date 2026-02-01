import SwiftUI

struct DailyPromptsCarouselView: View {
    let prompts: [DailyPrompt]
    let onSelectPrompt: (DailyPrompt) -> Void
    let onWriteOwn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("DAILY PROMPTS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(prompts) { prompt in
                        DailySeedCardView(prompt: prompt) {
                            onSelectPrompt(prompt)
                        }
                        .frame(width: 280)
                    }

                    // "Write your own" card at the end
                    WriteYourOwnPromptCard(onTap: onWriteOwn)
                        .frame(width: 280)
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
            }
            .padding(.horizontal, -DesignSystem.Padding.screen)
        }
    }
}

struct WriteYourOwnPromptCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "pencil.line")
                    .font(.title2)
                    .foregroundStyle(DesignSystem.Colors.primary)

                Text("Write your own")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Reflect on something specific to you today.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Spacer()
            }
            .padding(DesignSystem.Padding.card)
            .frame(maxHeight: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DailyPromptsCarouselView(
        prompts: DailyPrompts.todaysPrompts,
        onSelectPrompt: { _ in },
        onWriteOwn: {}
    )
    .padding()
    .background(DesignSystem.Colors.screenBackground)
}
