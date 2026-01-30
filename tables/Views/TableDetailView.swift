import SwiftUI
import SwiftData
import CloudKit

struct TableDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var table: TableModel

    @State private var quickAddText = ""
    @FocusState private var isQuickAddFocused: Bool
    @State private var isShowingNudgeSheet = false
    @State private var share: CKShare?
    @State private var shareError: String?

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
        .navigationTitle(table.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await prepareShare()
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isShowingNudgeSheet) {
            NudgeReminderView(table: table)
        }
        .sheet(item: $share) { share in
            CloudSharingView(share: share, container: CKContainer.default())
        }
        .alert("Sharing unavailable", isPresented: Binding(
            get: { shareError != nil },
            set: { isPresented in
                if !isPresented {
                    shareError = nil
                }
            }
        ), actions: {
            Button("OK", role: .cancel) {
                shareError = nil
            }
        }, message: {
            Text(shareError ?? "Sharing failed.")
        })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(alignment: .center) {
                Text(table.title)
                    .font(.system(size: 24, weight: .bold))

                Spacer()

                if table.status == .discussed {
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
                AvatarStackView(members: table.members)
                Text("\(table.members.count) members active")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                Spacer()

                if let reminder = table.nextReminderDate {
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
                archiveTable()
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
            if cards.isEmpty {
                Text("No cards yet. Add your first question or note.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignSystem.Spacing.small)
            } else {
                ForEach(cards) { card in
                    NavigationLink(destination: CardDetailView(card: card)) {
                        CardCellView(card: card)
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
                addQuickCard()
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
    }

    private var cards: [CardModel] {
        table.cards.sorted { $0.createdAt > $1.createdAt }
    }

    private func addQuickCard() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let card = CardModel(
            title: nil,
            body: trimmed,
            authorName: "You",
            table: table
        )
        modelContext.insert(card)
        table.updatedAt = Date()
        quickAddText = ""
        isQuickAddFocused = false
    }

    private func archiveTable() {
        table.status = .archived
        table.updatedAt = Date()
        try? modelContext.save()
    }

    private func prepareShare() async {
        do {
            // Save any pending changes before sharing
            try modelContext.save()

            // Create a share for the table using CloudKit
            let container = CKContainer.default()
            let database = container.privateCloudDatabase

            // Create a new CKShare with the default record zone
            let newShare = CKShare(recordZoneID: .default)

            // Configure the share
            newShare[CKShare.SystemFieldKey.title] = table.title as CKRecordValue
            newShare.publicPermission = .none

            // Save the share to CloudKit
            let operation = CKModifyRecordsOperation(recordsToSave: [newShare])
            operation.savePolicy = .changedKeys

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                database.add(operation)
            }

            share = newShare
        } catch {
            shareError = error.localizedDescription
        }
    }
}

#Preview {
    TableDetailView(table: TableModel(title: "Career crossroads", members: ["Sarah", "Marcus", "James"]))
        .modelContainer(for: [TableModel.self, CardModel.self, CommentModel.self, NudgeModel.self], inMemory: true)
}
