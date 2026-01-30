import SwiftUI
import SwiftData

struct CreateTableView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var context = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    detailsSection
                    inviteSection
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
                PrimaryButton(title: "Create Table") {
                    createTable()
                }
                .padding(.bottom, DesignSystem.Spacing.medium)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            Text("INVITE FRIENDS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Button {} label: {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Invite Link")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }

                HStack(spacing: DesignSystem.Spacing.medium) {
                    inviteAvatar(name: "Felix")
                    inviteAvatar(name: "Sarah")
                    inviteAvatar(name: "Marcus")
                    ZStack {
                        Circle()
                            .strokeBorder(DesignSystem.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inviting...")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }
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
    }

    private func inviteAvatar(name: String) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(for: name))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )
            Text(name)
                .font(.caption)
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined()
    }

    private func createTable() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTable = TableModel(
            title: trimmedTitle,
            context: trimmedContext.isEmpty ? nil : trimmedContext,
            status: .active,
            createdAt: Date(),
            updatedAt: Date(),
            members: ["You"]
        )
        modelContext.insert(newTable)
        dismiss()
    }
}

#Preview {
    CreateTableView()
        .modelContainer(for: [TableModel.self, CardModel.self, CommentModel.self, NudgeModel.self], inMemory: true)
}
