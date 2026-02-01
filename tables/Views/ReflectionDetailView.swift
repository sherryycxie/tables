import SwiftUI

struct ReflectionDetailView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let reflection: SupabaseReflection

    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    private var isQuickWin: Bool {
        reflection.reflectionType == "quick_win"
    }

    private var typeLabel: String {
        isQuickWin ? "Quick Win" : "Deep Reflection"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Type badge and date
                    HStack {
                        HStack(spacing: DesignSystem.Spacing.xSmall) {
                            Image(systemName: isQuickWin ? "star.fill" : "leaf.fill")
                                .font(.caption)
                            Text(typeLabel)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(isQuickWin ? .yellow : DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.xSmall)
                        .background((isQuickWin ? Color.yellow : DesignSystem.Colors.primary).opacity(0.12))
                        .clipShape(Capsule())

                        Spacer()

                        Text(reflection.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }

                    // Prompt if present
                    if let prompt = reflection.prompt {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("PROMPT")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DesignSystem.Colors.mutedText)
                                .tracking(0.5)

                            Text(prompt)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(DesignSystem.Padding.card)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }

                    // Reflection body
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("YOUR REFLECTION")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                            .tracking(0.5)

                        Text(reflection.body)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(DesignSystem.Padding.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)

                    Spacer(minLength: DesignSystem.Spacing.large)

                    // Delete button
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .tint(.red)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("Delete Reflection")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }
                    .disabled(isDeleting)
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.large)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Reflection?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteReflection()
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func deleteReflection() async {
        isDeleting = true
        do {
            try await supabaseManager.deleteReflection(reflection.id)
            dismiss()
        } catch {
            isDeleting = false
        }
    }
}

#Preview {
    ReflectionDetailView(
        reflection: SupabaseReflection(
            id: UUID(),
            userId: UUID(),
            body: "This is a sample reflection that I wrote about my day. It was a good day overall and I learned a lot.",
            prompt: "What would you tell your younger self?",
            reflectionType: "deep_reflection",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .environmentObject(SupabaseManager())
}
