import SwiftUI

struct SupabaseCreateTableView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var context = ""
    @State private var inviteEmail = ""
    @State private var invitedEmails: [String] = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    detailsSection
                    inviteSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.xLarge)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("New Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: isCreating ? "Creating..." : "Create Table") {
                    Task {
                        await createTable()
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.medium)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("TABLE DETAILS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Table Title")
                        .font(.subheadline.weight(.semibold))
                    TextField("e.g., Book club: did the ending work?", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
                .padding(DesignSystem.Padding.card)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Context")
                        .font(.subheadline.weight(.semibold))
                    TextEditor(text: $context)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if context.isEmpty {
                                Text("What should people prepare to discuss?")
                                    .foregroundStyle(DesignSystem.Colors.mutedText)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
                .padding(DesignSystem.Padding.card)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("INVITE COLLABORATORS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack(alignment: .top) {
                    UserSearchField(
                        selectedEmail: $inviteEmail,
                        placeholder: "Search by name or email"
                    )

                    Button {
                        addInvitee()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                    .disabled(inviteEmail.isEmpty || !inviteEmail.contains("@"))
                    .padding(.top, 12)
                }

                if !invitedEmails.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(invitedEmails, id: \.self) { email in
                            HStack {
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(email.prefix(1)).uppercased())
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DesignSystem.Colors.primary)
                                    )

                                Text(email)
                                    .font(.subheadline)

                                Spacer()

                                Button {
                                    invitedEmails.removeAll { $0 == email }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(DesignSystem.Colors.mutedText)
                                }
                            }
                        }
                    }
                }

                Text("Collaborators will be invited after the table is created")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
            .padding(DesignSystem.Padding.card)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    private func addInvitee() {
        let email = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, email.contains("@"), !invitedEmails.contains(email) else { return }
        invitedEmails.append(email)
        inviteEmail = ""
    }

    private func createTable() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        do {
            let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = supabaseManager.currentDisplayName ?? supabaseManager.currentUserEmail ?? "You"

            let newTable = try await supabaseManager.createTable(
                title: trimmedTitle,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                members: [displayName]
            )

            // Share with invited users
            var failedShares: [String] = []

            for email in invitedEmails {
                do {
                    try await supabaseManager.shareTable(tableId: newTable.id, withEmail: email)
                } catch {
                    // Track failed shares instead of silently ignoring
                    failedShares.append(email)
                    print("❌ Failed to share with \(email): \(error.localizedDescription)")
                }
            }

            // Show error if any shares failed
            if !failedShares.isEmpty {
                errorMessage = "Failed to share with: \(failedShares.joined(separator: ", "))"
                isCreating = false
                return  // Don't dismiss the view
            }

            // No need to call fetchTables() - shareTable() already updates local state instantly
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

#Preview {
    SupabaseCreateTableView()
        .environmentObject(SupabaseManager())
}
