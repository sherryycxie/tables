import SwiftUI

struct ReflectionDetailView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let reflection: SupabaseReflection

    @State private var currentBody: String
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showingShareSheet = false
    @State private var showingEditSheet = false
    @State private var editText = ""
    @State private var isSavingEdit = false
    @State private var editErrorMessage: String?

    init(reflection: SupabaseReflection) {
        self.reflection = reflection
        _currentBody = State(initialValue: reflection.body)
    }

    private var isQuickWin: Bool {
        reflection.reflectionType == "quick_win"
    }

    private var typeLabel: String {
        isQuickWin ? "Quick Win" : "Deep Reflection"
    }

    /// Returns a reflection copy with the latest body text (for passing to share sheet after edits)
    private var currentReflection: SupabaseReflection {
        var r = reflection
        r.body = currentBody
        return r
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

                        Text(currentBody)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(DesignSystem.Padding.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)

                    // Share to Table CTA
                    Button {
                        showingShareSheet = true
                    } label: {
                        VStack(spacing: 4) {
                            HStack {
                                Image(systemName: "rectangle.stack.badge.plus")
                                Text("Share to Table")
                            }
                            .font(.subheadline.weight(.medium))

                            Text("You'll choose an excerpt.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.xLarge)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            editText = currentBody
                            editErrorMessage = nil
                            showingEditSheet = true
                        } label: {
                            Label("Edit Reflection", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Reflection", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareReflectionSheet(reflection: currentReflection)
            }
            .sheet(isPresented: $showingEditSheet) {
                editReflectionSheet
            }
            .alert("Delete this reflection?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteReflection()
                    }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    // MARK: - Edit Sheet

    private var editReflectionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
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

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("YOUR REFLECTION")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                            .tracking(0.5)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $editText)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)

                            if editText.isEmpty {
                                Text("Write your reflection…")
                                    .foregroundStyle(DesignSystem.Colors.mutedText)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(DesignSystem.Padding.card)
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }

                    if let editErrorMessage {
                        Text(editErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.large)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Edit Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSavingEdit {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await saveEdit()
                            }
                        }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveEdit() async {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSavingEdit = true
        editErrorMessage = nil

        do {
            try await supabaseManager.updateReflection(id: reflection.id, body: trimmed)
            currentBody = trimmed
            showingEditSheet = false
        } catch {
            editErrorMessage = error.localizedDescription
        }
        isSavingEdit = false
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
