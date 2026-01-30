import SwiftUI

struct SupabaseTableDetailView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    let table: SupabaseTable

    @State private var cards: [SupabaseCard] = []
    @State private var quickAddText = ""
    @FocusState private var isQuickAddFocused: Bool
    @State private var isShowingNudgeSheet = false
    @State private var isShowingShareSheet = false
    @State private var isLoading = true
    @State private var localTable: SupabaseTable

    init(table: SupabaseTable) {
        self.table = table
        self._localTable = State(initialValue: table)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                header
                actionRow
                cardsSection
                quickAddSection
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xLarge)
        }
        .background(DesignSystem.Colors.screenBackground)
        .navigationTitle(localTable.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isShowingNudgeSheet) {
            SupabaseNudgeReminderView(table: localTable) { reminderDate in
                localTable.nextReminderDate = reminderDate
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            SupabaseShareView(table: localTable)
        }
        .task {
            await loadCards()
            await subscribeToCardUpdates()
        }
        .onDisappear {
            Task {
                await unsubscribeFromCardUpdates()
            }
        }
        .refreshable {
            await loadCards()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(alignment: .center) {
                Text(localTable.title)
                    .font(.system(size: 24, weight: .bold))

                Spacer()

                if localTable.status == "discussed" {
                    Text("Discussed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                if !localTable.members.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(localTable.members.prefix(3), id: \.self) { member in
                            Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(String(member.prefix(1)).uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                )
                        }
                    }
                }

                Text("\(localTable.members.count) members active")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Spacer()

                if let reminder = localTable.nextReminderDate {
                    ReminderChipView(date: reminder)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            actionButton(title: "Add Card", systemImage: "plus") {
                isQuickAddFocused = true
            }
            actionButton(title: "Nudge", systemImage: "hand.tap") {
                isShowingNudgeSheet = true
            }
            actionButton(title: "Archive", systemImage: "archivebox") {
                Task {
                    await archiveTable()
                }
            }
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.small) {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    )
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var cardsSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.large)
            } else if cards.isEmpty {
                Text("No cards yet. Add your first question or note.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignSystem.Spacing.small)
            } else {
                ForEach(cards) { card in
                    NavigationLink(destination: SupabaseCardDetailView(card: card)) {
                        SupabaseCardCellView(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickAddSection: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            TextField("Add a card...", text: $quickAddText)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, 12)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(Capsule())
                .focused($isQuickAddFocused)

            Button {
                Task {
                    await addQuickCard()
                }
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
            .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func loadCards() async {
        isLoading = true
        do {
            print("DEBUG: Loading cards for table: \(table.id)")
            cards = try await supabaseManager.fetchCards(for: table.id)
            print("DEBUG: Loaded \(cards.count) cards")
        } catch {
            print("ERROR: Failed to load cards: \(error)")
        }
        isLoading = false
    }

    private func addQuickCard() async {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        print("DEBUG: Adding card with text: '\(trimmed)' to table: \(table.id)")

        do {
            let newCard = try await supabaseManager.createCard(
                tableId: table.id,
                title: nil,
                body: trimmed,
                linkUrl: nil
            )
            print("DEBUG: Card created successfully: \(newCard.id)")
            cards.insert(newCard, at: 0)
            quickAddText = ""
            isQuickAddFocused = false
        } catch {
            print("ERROR: Failed to add card: \(error)")
            print("ERROR: Error details: \(error.localizedDescription)")
        }
    }

    private func archiveTable() async {
        do {
            try await supabaseManager.archiveTable(table.id)
            localTable.status = "archived"
        } catch {
            // Handle error
        }
    }

    private func subscribeToCardUpdates() async {
        let tableId = table.id
        print("DEBUG: Subscribing to card updates for table: \(tableId)")
        await supabaseManager.subscribeToCardChanges(for: tableId) {
            print("DEBUG: Card change detected, reloading cards for table: \(tableId)")
            do {
                self.cards = try await self.supabaseManager.fetchCards(for: tableId)
                print("DEBUG: Reloaded \(self.cards.count) cards after change")
            } catch {
                print("ERROR: Failed to reload cards after change: \(error)")
            }
        }
    }

    private func unsubscribeFromCardUpdates() async {
        await supabaseManager.unsubscribeFromCardChanges(for: table.id)
    }
}

// MARK: - Card Cell View

struct SupabaseCardCellView: View {
    let card: SupabaseCard

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(alignment: .top) {
                if let title = card.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                if card.status == "discussed" {
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
                .font(.subheadline)
                .foregroundStyle(card.title == nil ? .primary : DesignSystem.Colors.mutedText)
                .lineLimit(3)

            HStack {
                Text(card.authorName)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Spacer()

                Text(card.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        SupabaseTableDetailView(
            table: SupabaseTable(
                id: UUID(),
                title: "Sample Table",
                context: nil,
                status: "active",
                createdAt: Date(),
                updatedAt: Date(),
                members: ["Alice", "Bob"],
                nextReminderDate: nil,
                ownerId: UUID()
            )
        )
    }
    .environmentObject(SupabaseManager())
}
