import SwiftUI

struct ReflectionComposerView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let reflectionType: ReflectionType
    let prefilledPrompt: DailyPrompt?

    @State private var reflectionText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(reflectionType: ReflectionType, prefilledPrompt: DailyPrompt? = nil) {
        self.reflectionType = reflectionType
        self.prefilledPrompt = prefilledPrompt
    }

    private var title: String {
        switch reflectionType {
        case .quickWin:
            return "Log a Win"
        case .deepReflection:
            return "Deep Reflection"
        }
    }

    private var placeholder: String {
        switch reflectionType {
        case .quickWin:
            return "What's your win? Celebrate it here..."
        case .deepReflection:
            return "Take your time to explore your thoughts..."
        }
    }

    private var canSave: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    if let prompt = prefilledPrompt {
                        promptCard(prompt)
                    }

                    textEditorSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.large)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveReflection()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func promptCard(_ prompt: DailyPrompt) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(prompt.question)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Text(prompt.explanation)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.mutedText)
        }
        .padding(DesignSystem.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("YOUR REFLECTION")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .tracking(0.5)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $reflectionText)
                    .frame(minHeight: reflectionType == .deepReflection ? 200 : 120)
                    .scrollContentBackground(.hidden)
                    .padding(DesignSystem.Padding.card)

                if reflectionText.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                        .padding(DesignSystem.Padding.card)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    private func saveReflection() async {
        let trimmedBody = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        do {
            _ = try await supabaseManager.createReflection(
                body: trimmedBody,
                prompt: prefilledPrompt?.question,
                reflectionType: reflectionType.rawValue
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

#Preview {
    ReflectionComposerView(reflectionType: .quickWin)
        .environmentObject(SupabaseManager())
}

#Preview("With Prompt") {
    ReflectionComposerView(
        reflectionType: .deepReflection,
        prefilledPrompt: DailyPrompts.todaysPrompt
    )
    .environmentObject(SupabaseManager())
}
