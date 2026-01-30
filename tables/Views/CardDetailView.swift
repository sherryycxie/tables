import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: CardModel

    @State private var replyText = ""
    @FocusState private var isReplyFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    header
                    cardBody
                    replySection
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.top, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xLarge)
            }
            .scrollDismissesKeyboard(.interactively)

            replyComposer
        }
        .background(DesignSystem.Colors.screenBackground)
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if card.status != .discussed {
                    Button("Mark Discussed") {
                        markAsDiscussed()
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(for: card.authorName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(card.authorName)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 8) {
                    if let tableTitle = card.table?.title {
                        Text(tableTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if card.status == .discussed {
                        Text("Discussed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary)
                            .clipShape(Capsule())
                    }

                    Text(relativeCreatedAt)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let title = card.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
            }

            Text(card.body)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                Button {} label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Button(role: .destructive) {} label: {
                    Label("Delete", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.top, DesignSystem.Spacing.small)
        }
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("REPLIES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)

            if replies.isEmpty {
                Text("No replies yet. Add your perspective.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            } else {
                ForEach(replies) { reply in
                    replyRow(reply)
                }
            }
        }
    }

    private func replyRow(_ reply: CommentModel) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials(for: reply.authorName))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(reply.authorName)
                        .font(.subheadline.weight(.semibold))
                    Text(relativeDate(reply.createdAt))
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Text(reply.body)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
    }

    private var replyComposer: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            TextField("Write a reply...", text: $replyText)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, 12)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(Capsule())
                .focused($isReplyFocused)

            Button {
                addReply()
            } label: {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(.horizontal, DesignSystem.Padding.screen)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.screenBackground)
        .safeAreaPadding(.bottom, DesignSystem.Spacing.small)
    }

    private var replies: [CommentModel] {
        card.comments.sorted { $0.createdAt < $1.createdAt }
    }

    private var relativeCreatedAt: String {
        relativeDate(card.createdAt)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }

    private func addReply() {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let reply = CommentModel(body: trimmed, authorName: "You", card: card)
        modelContext.insert(reply)
        replyText = ""
        isReplyFocused = false
    }

    private func markAsDiscussed() {
        card.status = .discussed
        try? modelContext.save()
    }
}

#Preview {
    CardDetailView(card: CardModel(title: "Success right now", body: "What does success feel like to you right now?", authorName: "Sarah"))
        .modelContainer(for: [TableModel.self, CardModel.self, CommentModel.self, NudgeModel.self], inMemory: true)
}
