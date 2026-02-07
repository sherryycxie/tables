import SwiftUI

struct SupabaseHomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var searchText = ""
    @State private var selectedSegment: TableSegment = .active
    @State private var isShowingCreateTable = false
    @State private var isShowingProfile = false
    @State private var selectedFriend: String? = nil
    @State private var showingFriendFilter = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedTableId: UUID?
    @State private var selectedTable: SupabaseTable?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                    // Header section
                    Section {
                        header
                        searchField

                        // Friend filter toggle button
                        if !allFriends.isEmpty {
                            Button {
                                withAnimation {
                                    showingFriendFilter.toggle()
                                    if !showingFriendFilter {
                                        selectedFriend = nil  // Clear selection when hiding
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: showingFriendFilter ? "person.2.fill" : "person.2")
                                    Text(showingFriendFilter ? "Show All Tables" : "Filter by Friend")
                                }
                                .font(.subheadline)
                                .foregroundStyle(DesignSystem.Colors.primary)
                                .padding(.vertical, 8)
                            }
                        }

                        // Friend selector (shown when filter mode is active)
                        if showingFriendFilter && !allFriends.isEmpty {
                            FriendSelectorView(friends: allFriends, selectedFriend: $selectedFriend)
                                .padding(.vertical, 8)
                        }

                        // Filter header (shown when friend is selected)
                        if let friend = selectedFriend {
                            HStack {
                                Text("Tables with \(friend)")
                                    .font(.headline)

                                Spacer()

                                Text("(\(filteredTables.count))")
                                    .font(.subheadline)
                                    .foregroundStyle(DesignSystem.Colors.mutedText)

                                Button {
                                    selectedFriend = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(DesignSystem.Colors.mutedText)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        segmentControl
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.Padding.screen, bottom: 0, trailing: DesignSystem.Padding.screen))
                    .listRowSeparator(.hidden)

                    // Tables section
                    if supabaseManager.isLoading {
                        Section {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, DesignSystem.Spacing.large)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else if filteredTables.isEmpty {
                        Section {
                            EmptyStateView(
                                title: emptyStateTitle,
                                message: emptyStateMessage,
                                actionTitle: emptyStateActionTitle
                            ) {
                                isShowingCreateTable = true
                            }
                            .padding(.top, 50)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        Section {
                            ForEach(filteredTables) { table in
                                Button {
                                    selectedTable = table
                                } label: {
                                    SupabaseTableRowView(table: table)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 6, leading: DesignSystem.Padding.screen, bottom: 6, trailing: DesignSystem.Padding.screen))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if table.status == "archived" {
                                        Button {
                                            Task { await unarchiveTable(table.id) }
                                        } label: {
                                            Label("Unarchive", systemImage: "tray.and.arrow.up")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if table.status == "active" || table.status == "discussed" {
                                        Button {
                                            Task { await archiveTable(table.id) }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(.orange)
                                    } else if table.status == "archived" {
                                        if isOwner(of: table) {
                                            Button(role: .destructive) {
                                                Task { await deleteTable(table.id) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        } else {
                                            Button(role: .destructive) {
                                                Task { await leaveTable(table.id) }
                                            } label: {
                                                Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.screenBackground)
                .refreshable {
                    await supabaseManager.fetchTables()
                }
                .contentMargins(.bottom, 110, for: .scrollContent)

                PrimaryButton(title: "New Table", systemImage: "plus") {
                    isShowingCreateTable = true
                }
                .padding(.trailing, DesignSystem.Padding.screen)
                .padding(.bottom, DesignSystem.Padding.screen)
        }
        .background(DesignSystem.Colors.screenBackground)
        .navigationTitle("Tables")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedTable) { table in
            SupabaseTableDetailView(table: table)
        }
        .sheet(isPresented: $isShowingCreateTable) {
            SupabaseCreateTableView()
        }
        .sheet(isPresented: $isShowingProfile) {
            ProfileView()
        }
        .sheet(item: Binding(
            get: { selectedTableId.flatMap { id in supabaseManager.tables.first { $0.id == id } } },
            set: { selectedTableId = $0?.id }
        )) { table in
            NavigationStack {
                SupabaseTableDetailView(table: table)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTable)) { notification in
            if let tableId = notification.userInfo?["tableId"] as? UUID {
                selectedTableId = tableId
                print("📱 Deep link: Opening table \(tableId)")
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var allFriends: [String] {
        let allMembers = supabaseManager.tables.flatMap { $0.members }
        let uniqueMembers = Set(allMembers)

        // Collect all possible variations of current user's name (lowercased for comparison)
        var currentUserNamesLowercased: Set<String> = []
        if let fullName = supabaseManager.currentFullName, !fullName.isEmpty {
            currentUserNamesLowercased.insert(fullName.lowercased().trimmingCharacters(in: .whitespaces))
        }
        if let displayName = supabaseManager.currentDisplayName, !displayName.isEmpty {
            currentUserNamesLowercased.insert(displayName.lowercased().trimmingCharacters(in: .whitespaces))
        }
        if let email = supabaseManager.currentUserEmail, !email.isEmpty {
            currentUserNamesLowercased.insert(email.lowercased().trimmingCharacters(in: .whitespaces))
            // Also add the email handle (part before @)
            if let handle = email.components(separatedBy: "@").first, !handle.isEmpty {
                currentUserNamesLowercased.insert(handle.lowercased().trimmingCharacters(in: .whitespaces))
            }
        }
        if let firstName = supabaseManager.currentFirstName, !firstName.isEmpty {
            currentUserNamesLowercased.insert(firstName.lowercased().trimmingCharacters(in: .whitespaces))
        }
        if let lastName = supabaseManager.currentLastName, !lastName.isEmpty {
            currentUserNamesLowercased.insert(lastName.lowercased().trimmingCharacters(in: .whitespaces))
        }

        // Filter out current user using case-insensitive comparison
        return uniqueMembers
            .filter { member in
                let memberLowercased = member.lowercased().trimmingCharacters(in: .whitespaces)
                return !currentUserNamesLowercased.contains(memberLowercased)
            }
            .sorted()
    }

    private var filteredTables: [SupabaseTable] {
        // 1. Segment filtering (Active/Archived)
        let segmentFiltered = supabaseManager.tables.filter { table in
            switch selectedSegment {
            case .active:
                return table.status == "active" || table.status == "discussed"
            case .archived:
                return table.status == "archived"
            }
        }

        // 2. Friend filtering
        let friendFiltered = segmentFiltered.filter { table in
            guard let friend = selectedFriend else { return true }
            return table.members.contains(friend)
        }

        // 3. Search filtering
        let searchFiltered = friendFiltered.filter { table in
            guard !searchText.isEmpty else { return true }
            return table.title.localizedCaseInsensitiveContains(searchText)
        }

        return searchFiltered.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var emptyStateTitle: String {
        if selectedFriend != nil {
            return "No Tables with \(selectedFriend!)"
        }

        switch selectedSegment {
        case .active:
            return "No tables yet"
        case .archived:
            return "No archived tables"
        }
    }

    private var emptyStateMessage: String {
        if selectedFriend != nil {
            return "You haven't created any tables with \(selectedFriend!) yet."
        }

        switch selectedSegment {
        case .active:
            return "Start a conversation that matters. Create a table to begin your first deep discussion."
        case .archived:
            return "Archived tables will appear here once you file them away."
        }
    }

    private var emptyStateActionTitle: String {
        if selectedFriend != nil {
            return "Create a Table"
        }

        switch selectedSegment {
        case .active:
            return "Create your first Table"
        case .archived:
            return "Create a Table"
        }
    }

    private var header: some View {
        HStack {
            Text("All Tables")
                .font(.system(size: 28, weight: .bold))

            Spacer()

            Button {
                isShowingProfile = true
            } label: {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(DesignSystem.Colors.primary)
                    )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.mutedText)
            TextField("Search your tables", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }

    private var segmentControl: some View {
        Picker("Status", selection: $selectedSegment) {
            ForEach(TableSegment.allCases) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    private func archiveTable(_ tableId: UUID) async {
        do {
            try await supabaseManager.archiveTable(tableId)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func unarchiveTable(_ tableId: UUID) async {
        do {
            try await supabaseManager.unarchiveTable(tableId)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func deleteTable(_ tableId: UUID) async {
        do {
            try await supabaseManager.deleteTable(tableId)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func leaveTable(_ tableId: UUID) async {
        do {
            try await supabaseManager.leaveSharedTable(tableId)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    private func isOwner(of table: SupabaseTable) -> Bool {
        guard let userId = supabaseManager.currentUserId else { return false }
        return table.ownerId == userId
    }
}

private enum TableSegment: String, CaseIterable, Identifiable {
    case active
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        }
    }
}

// MARK: - Table Row View for Supabase

struct SupabaseTableRowView: View {
    let table: SupabaseTable

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text(table.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if table.status == "discussed" {
                    Text("Discussed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                if !table.members.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(table.members.prefix(3), id: \.self) { member in
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

                    Text("\(table.members.count) members")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Spacer()

                Text(table.updatedAt.formatted(.relative(presentation: .named)))
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
    SupabaseHomeView()
        .environmentObject(SupabaseManager())
}
