import SwiftUI

struct SupabaseCardDetailView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    let card: SupabaseCard

    @State private var localCard: SupabaseCard
    @State private var comments: [SupabaseComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = true
    @FocusState private var isCommentFocused: Bool

    init(card: SupabaseCard) {
        self.card = card
        self._localCard = State(initialValue: card)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                cardContent
                commentsSection
                addCommentSection
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xLarge)
        }
        .background(DesignSystem.Colors.screenBackground)
        .navigationTitle("Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if localCard.status != "discussed" {
                    Button("Mark Discussed") {
                        Task { await markAsDiscussed() }
                    }
                }
            }
        }
        .task {
            await loadComments()
            await subscribeToCommentUpdates()
        }
        .onDisappear {
            Task {
                await unsubscribeFromCommentUpdates()
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack(alignment: .top) {
                if let title = card.title, !title.isEmpty {
                    Text(title)
                        .font(.title2.weight(.bold))
                }

                if localCard.status == "discussed" {
                    Text("Discussed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
            }

            Text(card.body)
                .font(.body)

            if let linkUrl = card.linkUrl, let url = URL(string: linkUrl) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                        Text(linkUrl)
                            .lineLimit(1)
                    }
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            HStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(card.authorName.prefix(1)).uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    )

                Text(card.authorName)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Text("·")
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Text(card.createdAt.formatted(.relative(presentation: .named)))
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
        }
        .padding(DesignSystem.Padding.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Comments")
                .font(.headline)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if comments.isEmpty {
                Text("No comments yet. Start the discussion!")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            } else {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
        }
    }

    private func commentRow(_ comment: SupabaseComment) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(comment.authorName.prefix(1)).uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    )

                Text(comment.authorName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(comment.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Text(comment.body)
                .font(.subheadline)
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private var addCommentSection: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            TextField("Add a comment...", text: $newCommentText)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, 12)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(Capsule())
                .focused($isCommentFocused)

            Button {
                Task {
                    await addComment()
                }
            } label: {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await supabaseManager.fetchComments(for: card.id)
        } catch {
            // Handle error
        }
        isLoading = false
    }

    private func addComment() async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let newComment = try await supabaseManager.createComment(cardId: card.id, body: trimmed)
            comments.append(newComment)
            newCommentText = ""
            isCommentFocused = false
        } catch {
            // Handle error
        }
    }

    private func subscribeToCommentUpdates() async {
        await supabaseManager.subscribeToCommentChanges(for: card.id) { [weak supabaseManager] in
            guard let supabaseManager = supabaseManager else { return }
            await MainActor.run {
                Task {
                    do {
                        self.comments = try await supabaseManager.fetchComments(for: self.card.id)
                    } catch {
                        // Handle error
                    }
                }
            }
        }
    }

    private func unsubscribeFromCommentUpdates() async {
        await supabaseManager.unsubscribeFromCommentChanges(for: card.id)
    }

    private func markAsDiscussed() async {
        var updatedCard = localCard
        updatedCard.status = "discussed"

        do {
            try await supabaseManager.updateCard(updatedCard)
            localCard = updatedCard
        } catch {
            // Handle error
        }
    }
}

#Preview {
    NavigationStack {
        SupabaseCardDetailView(
            card: SupabaseCard(
                id: UUID(),
                tableId: UUID(),
                title: "Sample Card",
                body: "This is a sample card body with some content.",
                linkUrl: nil,
                createdAt: Date(),
                authorName: "Alice",
                status: "active"
            )
        )
    }
    .environmentObject(SupabaseManager())
}
