import SwiftUI

struct ShareReflectionSheet: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss

    let reflection: SupabaseReflection

    // MARK: - State

    @State private var selectedTable: SupabaseTable?
    @State private var showNewTableFlow = false
    @State private var excerptText: String = ""
    @State private var askText: String = ""
    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // New Table flow state
    @State private var newTableName: String = ""
    @State private var newTableInviteEmail: String = ""
    @State private var newTableInvitedEmails: [String] = []
    @State private var newTableStep: NewTableStep = .setup
    @State private var newTableExcerptText: String = ""
    @State private var newTableQuestionText: String = ""
    @State private var newTableNextStepText: String = "What's one small thing I should try next week?"
    @State private var isCreatingTable = false

    enum NewTableStep {
        case setup
        case seed
    }

    // MARK: - Computed

    private var activeTables: [SupabaseTable] {
        supabaseManager.tables.filter { $0.status == "active" }
    }

    private var trimmedExcerpt: String {
        excerptText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAsk: String {
        askText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isExcerptValid: Bool {
        trimmedExcerpt.count >= 20
    }

    private var isExcerptLong: Bool {
        trimmedExcerpt.count > 1200
    }

    private var cardTitle: String {
        "From my Garden · \(reflection.createdAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private var cardBody: String {
        if trimmedAsk.isEmpty {
            return trimmedExcerpt
        } else {
            return "Question: \(trimmedAsk)\n\n\(trimmedExcerpt)"
        }
    }

    /// Which top-level screen are we on?
    private var isOnPicker: Bool {
        selectedTable == nil && !showNewTableFlow
    }

    private var navTitle: String {
        if showNewTableFlow {
            return newTableStep == .setup ? "Create a new Table" : "Seed your Table"
        } else if selectedTable != nil {
            return "Choose what to share"
        } else {
            return "Share to a Table"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isOnPicker {
                    step1TablePicker
                } else if selectedTable != nil {
                    step2ExistingTable
                } else {
                    step2NewTable
                }
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnPicker {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            handleBack()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if excerptText.isEmpty {
                    excerptText = reflection.body
                }
                if newTableExcerptText.isEmpty {
                    newTableExcerptText = reflection.body
                }
                if newTableName.isEmpty {
                    newTableName = reflection.prompt ?? "New Table"
                }
            }
        }
    }

    private func handleBack() {
        if showNewTableFlow && newTableStep == .seed {
            newTableStep = .setup
        } else if showNewTableFlow {
            showNewTableFlow = false
        } else {
            selectedTable = nil
        }
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Step 1: Table Picker

    private var step1TablePicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Pick a table, or create a new one from this reflection.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .padding(.horizontal, DesignSystem.Padding.screen)
                    .padding(.top, DesignSystem.Spacing.medium)

                LazyVStack(spacing: DesignSystem.Spacing.small) {
                    // "+ Create new Table" row — always first
                    Button {
                        showNewTableFlow = true
                        newTableStep = .setup
                    } label: {
                        createNewTableRow
                    }

                    // Existing tables
                    ForEach(activeTables) { table in
                        Button {
                            selectedTable = table
                        } label: {
                            TableRowForSharing(table: table, isSharing: false)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)
                .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
    }

    private var createNewTableRow: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Create new Table")
                    .font(.headline)
                    .foregroundStyle(DesignSystem.Colors.primary)

                Text("Start a table seeded from this reflection")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Step 2A: Existing Table Flow

    private var step2ExistingTable: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                excerptSection
                askSection
                previewSection

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }

                postButton
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.vertical, DesignSystem.Spacing.large)
        }
    }

    private var excerptSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("EXCERPT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .tracking(0.5)

                Spacer()

                Text("\(trimmedExcerpt.count) chars")
                    .font(.caption)
                    .foregroundStyle(
                        !trimmedExcerpt.isEmpty && !isExcerptValid ? .red :
                        isExcerptLong ? .orange :
                        DesignSystem.Colors.mutedText
                    )
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $excerptText)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .font(.body)

                if excerptText.isEmpty {
                    Text("Paste or type an excerpt from your reflection…")
                        .font(.body)
                        .foregroundStyle(DesignSystem.Colors.mutedText.opacity(0.5))
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
                    .stroke(
                        !trimmedExcerpt.isEmpty && !isExcerptValid ? .red :
                        isExcerptLong ? .orange :
                        Color.clear,
                        lineWidth: 1
                    )
            )

            if !trimmedExcerpt.isEmpty && !isExcerptValid {
                Text("Excerpt must be at least 20 characters")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isExcerptLong {
                Text("Consider trimming — long excerpts may be hard to read at the table")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var askSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("ADD A QUESTION (OPTIONAL)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .tracking(0.5)

                Spacer()

                Text("\(trimmedAsk.count)/200")
                    .font(.caption)
                    .foregroundStyle(trimmedAsk.count >= 200 ? .orange : DesignSystem.Colors.mutedText)
            }

            TextField("What would you do in my situation?", text: $askText)
                .font(.body)
                .padding(DesignSystem.Padding.card)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .onChange(of: askText) { _, newValue in
                    if newValue.count > 200 {
                        askText = String(newValue.prefix(200))
                    }
                }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("PREVIEW")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.mutedText)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack(alignment: .top) {
                    Text(cardTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                        Text("Shared Reflection")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())
                }

                if let sourcePrompt = reflection.prompt, !sourcePrompt.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text(sourcePrompt)
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                            .italic()
                            .lineLimit(2)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                    .background(DesignSystem.Colors.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                }

                Text(cardBody.isEmpty ? " " : cardBody)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .lineLimit(5)

                HStack {
                    Text(supabaseManager.currentDisplayName ?? supabaseManager.currentUserEmail ?? "You")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.mutedText)

                    Spacer()

                    Text("Just now")
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

    @ViewBuilder
    private var postButton: some View {
        if let table = selectedTable {
            Button {
                Task {
                    await shareExcerptToTable(table)
                }
            } label: {
                HStack {
                    if isSharing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Post")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .background(isExcerptValid && !isSharing ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
            .disabled(!isExcerptValid || isSharing)
        }
    }

    // MARK: - Step 2B: New Table Flow (placeholder — implemented in Checkpoint 5)

    @ViewBuilder
    private var step2NewTable: some View {
        if newTableStep == .setup {
            newTableSetupView
        } else {
            newTableSeedView
        }
    }

    private var newTableSetupView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Table name
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("TABLE NAME")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                        .tracking(0.5)

                    TextField("e.g., Taking care of myself", text: $newTableName)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                        .padding(DesignSystem.Padding.card)
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }

                // Invite section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("INVITE (OPTIONAL)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                        .tracking(0.5)

                    HStack(alignment: .top) {
                        UserSearchField(
                            selectedEmail: $newTableInviteEmail,
                            placeholder: "Search by name or email"
                        )

                        Button {
                            addNewTableInvitee()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(DesignSystem.Colors.primary)
                        }
                        .disabled(newTableInviteEmail.isEmpty || !newTableInviteEmail.contains("@"))
                        .padding(.top, 12)
                    }

                    ForEach(newTableInvitedEmails, id: \.self) { email in
                        HStack {
                            Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.15))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(String(email.prefix(1)).uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                )

                            Text(email)
                                .font(.subheadline)

                            Spacer()

                            Button {
                                newTableInvitedEmails.removeAll { $0 == email }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DesignSystem.Colors.mutedText)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Next button
                Button {
                    newTableStep = .seed
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(newTableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? DesignSystem.Colors.primary.opacity(0.4)
                            : DesignSystem.Colors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }
                .disabled(newTableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.vertical, DesignSystem.Spacing.large)
        }
    }

    private var newTableSeedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                Text("We'll create a few starter cards you can edit.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                // Card 1: Excerpt
                seedCardSection(
                    number: "1",
                    label: "EXCERPT",
                    text: $newTableExcerptText,
                    placeholder: "Paste or edit an excerpt from your reflection…",
                    minHeight: 120
                )

                // Card 2: Question
                seedCardSection(
                    number: "2",
                    label: "QUESTION (OPTIONAL)",
                    text: $newTableQuestionText,
                    placeholder: "e.g., Have you felt this too?",
                    minHeight: 60
                )

                // Card 3: Next step
                seedCardSection(
                    number: "3",
                    label: "NEXT STEP / EXPERIMENT (OPTIONAL)",
                    text: $newTableNextStepText,
                    placeholder: "What's one small thing I should try next week?",
                    minHeight: 60
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }

                // Create Table button
                Button {
                    Task {
                        await createSeededTable()
                    }
                } label: {
                    HStack {
                        if isCreatingTable {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Create Table")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.medium)
                    .background(isNewTableExcerptValid && !isCreatingTable
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.primary.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                }
                .disabled(!isNewTableExcerptValid || isCreatingTable)
            }
            .padding(.horizontal, DesignSystem.Padding.screen)
            .padding(.vertical, DesignSystem.Spacing.large)
        }
    }

    private func seedCardSection(number: String, label: String, text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.xSmall) {
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(Circle())

                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
                    .tracking(0.5)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .font(.body)

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(DesignSystem.Colors.mutedText.opacity(0.5))
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
    }

    private var isNewTableExcerptValid: Bool {
        newTableExcerptText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }

    private func addNewTableInvitee() {
        let email = newTableInviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, email.contains("@"), !newTableInvitedEmails.contains(email) else { return }
        newTableInvitedEmails.append(email)
        newTableInviteEmail = ""
    }

    // MARK: - Actions

    private func shareExcerptToTable(_ table: SupabaseTable) async {
        isSharing = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await supabaseManager.shareReflectionExcerptToTable(
                reflection: reflection,
                tableId: table.id,
                excerptBody: cardBody,
                title: cardTitle
            )
            successMessage = "Shared to \(table.title)"

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        } catch {
            errorMessage = "Failed to share: \(error.localizedDescription)"
            isSharing = false
        }
    }

    private func createSeededTable() async {
        // Implemented in Checkpoint 5
        isCreatingTable = true
        errorMessage = nil
        successMessage = nil

        let trimmedName = newTableName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExcerpt = newTableExcerptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuestion = newTableQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNextStep = newTableNextStepText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, trimmedExcerpt.count >= 20 else {
            errorMessage = "Table name and excerpt (≥20 chars) are required."
            isCreatingTable = false
            return
        }

        do {
            let displayName = supabaseManager.currentDisplayName ?? supabaseManager.currentUserEmail ?? "You"

            // 1. Create the table
            let newTable = try await supabaseManager.createTable(
                title: trimmedName,
                context: nil,
                members: [displayName]
            )

            // 2. Create seed cards
            _ = try await supabaseManager.shareReflectionExcerptToTable(
                reflection: reflection,
                tableId: newTable.id,
                excerptBody: trimmedExcerpt,
                title: cardTitle
            )

            if !trimmedQuestion.isEmpty {
                _ = try await supabaseManager.createCard(
                    tableId: newTable.id,
                    title: "Question",
                    body: trimmedQuestion,
                    linkUrl: nil
                )
            }

            if !trimmedNextStep.isEmpty {
                _ = try await supabaseManager.createCard(
                    tableId: newTable.id,
                    title: "Next step",
                    body: trimmedNextStep,
                    linkUrl: nil
                )
            }

            // 3. Invite collaborators
            for email in newTableInvitedEmails {
                try? await supabaseManager.shareTable(tableId: newTable.id, withEmail: email)
            }

            successMessage = "Created \(trimmedName)"

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        } catch {
            errorMessage = "Couldn't create table. Try again."
            isCreatingTable = false
        }
    }
}

// MARK: - Table Row

struct TableRowForSharing: View {
    let table: SupabaseTable
    let isSharing: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(table.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(table.members.count) members")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }

            Spacer()

            if isSharing {
                ProgressView()
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.mutedText)
            }
        }
        .padding(DesignSystem.Padding.card)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

#Preview {
    ShareReflectionSheet(
        reflection: SupabaseReflection(
            id: UUID(),
            userId: UUID(),
            body: "This is a sample reflection that I wrote about my day. It captures how I've been feeling about work-life balance and what I want to change going forward.",
            prompt: "What made you smile today?",
            reflectionType: "deep_reflection",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .environmentObject(SupabaseManager())
}
