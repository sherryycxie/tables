import SwiftUI

struct SupabaseShareView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let table: SupabaseTable

    @State private var email = ""
    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.large) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("SHARE WITH")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.mutedText)

                    VStack(spacing: DesignSystem.Spacing.medium) {
                        UserSearchField(
                            selectedEmail: $email,
                            placeholder: "Search by name or email"
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if let successMessage {
                            Text(successMessage)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        Button {
                            Task {
                                await shareTable()
                            }
                        } label: {
                            HStack {
                                if isSharing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Invite")
                                }
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        }
                        .disabled(email.isEmpty || !email.contains("@") || isSharing)
                    }
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("HOW IT WORKS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.mutedText)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        infoRow(icon: "person.badge.plus", text: "Enter the email of someone with a Tables account")
                        infoRow(icon: "bell.badge", text: "They'll see the shared table in their app")
                        infoRow(icon: "pencil", text: "Collaborators can add cards and comments")
                    }
                    .padding(DesignSystem.Padding.card)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }

                Spacer()
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.top, DesignSystem.Spacing.large)
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Share Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
        }
    }

    private func shareTable() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return }

        isSharing = true
        errorMessage = nil
        successMessage = nil

        do {
            try await supabaseManager.shareTable(tableId: table.id, withEmail: trimmedEmail)

            // No need to call fetchTables() - shareTable() already updates local state instantly

            successMessage = "Table shared with \(trimmedEmail)"
            email = ""
        } catch let error as SupabaseError {
            errorMessage = error.errorDescription
            print("❌ Share error: \(error)")
        } catch {
            errorMessage = "Failed to share: \(error.localizedDescription)"
            print("❌ Share error: \(error)")
        }

        isSharing = false
    }
}

#Preview {
    SupabaseShareView(
        table: SupabaseTable(
            id: UUID(),
            title: "Sample Table",
            context: nil,
            status: "active",
            createdAt: Date(),
            updatedAt: Date(),
            members: ["Alice"],
            nextReminderDate: nil,
            ownerId: UUID()
        )
    )
    .environmentObject(SupabaseManager())
}
