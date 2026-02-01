import SwiftUI

struct YourGardenView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    let onViewAll: () -> Void
    let onSelectReflection: (SupabaseReflection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("YOUR GARDEN")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .tracking(0.5)

                Spacer()

                if !supabaseManager.reflections.isEmpty {
                    Button(action: onViewAll) {
                        Text("View All")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }

            if supabaseManager.reflections.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        ForEach(supabaseManager.reflections.prefix(5)) { reflection in
                            GardenCardView(reflection: reflection)
                                .onTapGesture {
                                    onSelectReflection(reflection)
                                }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Padding.screen)
                }
                .padding(.horizontal, -DesignSystem.Padding.screen)
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "leaf")
                .font(.title2)
                .foregroundStyle(DesignSystem.Colors.mutedText)

            Text("Seeds you plant will grow here")
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

struct GardenCardView: View {
    let reflection: SupabaseReflection

    private var isQuickWin: Bool {
        reflection.reflectionType == "quick_win"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(systemName: isQuickWin ? "star.fill" : "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(isQuickWin ? .yellow : DesignSystem.Colors.primary)

                Spacer()

                Text(reflection.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Text(reflection.body)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            if let prompt = reflection.prompt {
                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(DesignSystem.Padding.card)
        .frame(width: 200, alignment: .topLeading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    YourGardenView(onViewAll: {}, onSelectReflection: { _ in })
        .padding()
        .background(DesignSystem.Colors.screenBackground)
        .environmentObject(SupabaseManager())
}
