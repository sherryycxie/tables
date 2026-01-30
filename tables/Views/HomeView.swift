import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tables: [TableModel]
    @State private var searchText = ""
    @State private var selectedSegment: TableSegment = .active
    @State private var isShowingCreateTable = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        header
                        searchField
                        segmentControl

                        if filteredTables.isEmpty {
                            EmptyStateView(
                                title: emptyStateTitle,
                                message: emptyStateMessage,
                                actionTitle: emptyStateActionTitle
                            ) {
                                isShowingCreateTable = true
                            }
                            .padding(.top, DesignSystem.Spacing.large)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.medium) {
                                ForEach(filteredTables) { table in
                                    NavigationLink(destination: TableDetailView(table: table)) {
                                        TableRowView(table: table)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if table.status == .archived {
                                            Button {
                                                unarchiveTable(table)
                                            } label: {
                                                Label("Unarchive", systemImage: "tray.and.arrow.up")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if table.status == .active || table.status == .discussed {
                                            Button {
                                                archiveTable(table)
                                            } label: {
                                                Label("Archive", systemImage: "archivebox")
                                            }
                                            .tint(.orange)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Padding.screen)
                    .padding(.top, DesignSystem.Spacing.large)
                    .padding(.bottom, 110)
                }

                PrimaryButton(title: "New Table", systemImage: "plus") {
                    isShowingCreateTable = true
                }
                    .padding(.trailing, DesignSystem.Padding.screen)
                    .padding(.bottom, DesignSystem.Padding.screen)
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Tables")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingCreateTable) {
                CreateTableView()
            }
        }
    }

    private var filteredTables: [TableModel] {
        let segmentFiltered = tables.filter { table in
            switch selectedSegment {
            case .active:
                return table.status == .active || table.status == .discussed
            case .archived:
                return table.status == .archived
            }
        }

        let searchFiltered = segmentFiltered.filter { table in
            guard !searchText.isEmpty else { return true }
            return table.title.localizedCaseInsensitiveContains(searchText)
        }

        return searchFiltered.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var emptyStateTitle: String {
        switch selectedSegment {
        case .active:
            return "No tables yet"
        case .archived:
            return "No archived tables"
        }
    }

    private var emptyStateMessage: String {
        switch selectedSegment {
        case .active:
            return "Start a conversation that matters. Create a table to begin your first deep discussion."
        case .archived:
            return "Archived tables will appear here once you file them away."
        }
    }

    private var emptyStateActionTitle: String {
        switch selectedSegment {
        case .active:
            return "Create your first Table"
        case .archived:
            return "Create a Table"
        }
    }

    private var header: some View {
        HStack {
            Text("Your Tables")
                .font(.system(size: 28, weight: .bold))

            Spacer()

            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                )
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

    private func archiveTable(_ table: TableModel) {
        table.status = .archived
        table.updatedAt = Date()
        try? modelContext.save()
    }

    private func unarchiveTable(_ table: TableModel) {
        table.status = .active
        table.updatedAt = Date()
        try? modelContext.save()
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

#Preview {
    HomeView()
        .modelContainer(for: [TableModel.self, CardModel.self, CommentModel.self, NudgeModel.self], inMemory: true)
}
