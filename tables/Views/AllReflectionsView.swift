import SwiftUI

struct AllReflectionsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var selectedReflection: SupabaseReflection?

    private var sortedReflections: [SupabaseReflection] {
        supabaseManager.reflections.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(sortedReflections) { reflection in
                    ReflectionRowView(reflection: reflection)
                        .onTapGesture {
                            selectedReflection = reflection
                        }
                }
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.screenBackground)
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedReflection) { reflection in
            ReflectionDetailView(reflection: reflection)
        }
    }
}

struct ReflectionRowView: View {
    let reflection: SupabaseReflection

    private var isQuickWin: Bool {
        reflection.reflectionType == "quick_win"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: isQuickWin ? "star.fill" : "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(isQuickWin ? .yellow : DesignSystem.Colors.primary)

                    Text(isQuickWin ? "Quick Win" : "Reflection")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Spacer()

                Text(reflection.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Text(reflection.body)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(4)

            if let prompt = reflection.prompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(DesignSystem.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        AllReflectionsView()
            .environmentObject(SupabaseManager())
    }
}
