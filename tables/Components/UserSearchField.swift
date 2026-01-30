import SwiftUI

struct UserSearchField: View {
    @EnvironmentObject var supabaseManager: SupabaseManager

    @Binding var selectedEmail: String
    let placeholder: String
    let onUserSelected: ((SupabaseManager.UserSearchResult) -> Void)?

    @State private var searchText = ""
    @State private var searchResults: [SupabaseManager.UserSearchResult] = []
    @State private var isSearching = false
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    private let searchDebouncer = Debouncer(delay: 0.3)

    init(
        selectedEmail: Binding<String>,
        placeholder: String = "Search by name or email",
        onUserSelected: ((SupabaseManager.UserSearchResult) -> Void)? = nil
    ) {
        self._selectedEmail = selectedEmail
        self.placeholder = placeholder
        self.onUserSelected = onUserSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.mutedText)

                TextField(placeholder, text: $searchText)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
                    .onSubmit {
                        // If search text looks like email, use it directly
                        if searchText.contains("@") {
                            selectedEmail = searchText.lowercased().trimmingCharacters(in: .whitespaces)
                            showSuggestions = false
                        }
                    }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.mutedText)
                    }
                }
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: 1)
            )

            // Suggestions dropdown
            if showSuggestions && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults) { user in
                        Button {
                            selectUser(user)
                        } label: {
                            userRow(user)
                        }
                        .buttonStyle(.plain)

                        if user.id != searchResults.last?.id {
                            Divider()
                        }
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                .padding(.top, 4)
            }

            // "Use email" option when typing something that looks like email
            if showSuggestions && searchText.contains("@") && !searchResults.contains(where: { $0.email.lowercased() == searchText.lowercased() }) {
                Button {
                    selectedEmail = searchText.lowercased().trimmingCharacters(in: .whitespaces)
                    searchText = ""
                    showSuggestions = false
                    isFocused = false
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .frame(width: 40, height: 40)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use \"\(searchText)\"")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("Send invite to this email")
                                .font(.caption)
                                .foregroundStyle(DesignSystem.Colors.mutedText)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                }
                .buttonStyle(.plain)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                .padding(.top, 4)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                // Delay hiding to allow button tap to register
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showSuggestions = false
                }
            }
        }
    }

    private func userRow(_ user: SupabaseManager.UserSearchResult) -> some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Avatar
            Circle()
                .fill(avatarColor(for: user.displayText))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials(for: user))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                )

            // Name and email
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let fullName = user.fullName, fullName != user.email {
                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }
            }

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .contentShape(Rectangle())
    }

    private func initials(for user: SupabaseManager.UserSearchResult) -> String {
        if let first = user.firstName, !first.isEmpty {
            let firstInitial = String(first.prefix(1)).uppercased()
            if let last = user.lastName, !last.isEmpty {
                return firstInitial + String(last.prefix(1)).uppercased()
            }
            return firstInitial
        }

        let name = user.displayText
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.3),
            Color(red: 0.3, green: 0.6, blue: 0.9),
            Color(red: 0.3, green: 0.8, blue: 0.5),
            Color(red: 0.9, green: 0.6, blue: 0.2),
            Color(red: 0.7, green: 0.4, blue: 0.9),
            Color(red: 0.9, green: 0.7, blue: 0.2),
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    private func selectUser(_ user: SupabaseManager.UserSearchResult) {
        selectedEmail = user.email
        searchText = user.displayText
        showSuggestions = false
        isFocused = false
        onUserSelected?(user)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            showSuggestions = false
            return
        }

        showSuggestions = true

        searchDebouncer.debounce {
            await search(query: query)
        }
    }

    @MainActor
    private func search(query: String) async {
        isSearching = true
        defer { isSearching = false }

        print("🔍 UserSearchField: Starting search for '\(query)'")

        do {
            searchResults = try await supabaseManager.searchUsers(query: query)
            print("🔍 UserSearchField: Got \(searchResults.count) results")
        } catch {
            print("🔍 UserSearchField: Search error: \(error)")
            searchResults = []
        }
    }
}

// Simple debouncer for search
@MainActor
class Debouncer {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func debounce(_ action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var email = ""

        var body: some View {
            VStack {
                UserSearchField(selectedEmail: $email)
                    .padding()

                Text("Selected: \(email)")
            }
            .environmentObject(SupabaseManager())
        }
    }

    return PreviewWrapper()
}
