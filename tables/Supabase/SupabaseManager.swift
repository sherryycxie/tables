import Foundation
import Combine
import Auth
import PostgREST
import Realtime

@MainActor
final class SupabaseManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: UUID?
    @Published var currentUserEmail: String?
    @Published var currentDisplayName: String?
    @Published var currentFirstName: String?
    @Published var currentLastName: String?
    @Published var hasCompletedOnboarding: Bool = false

    /// Returns the full name (first + last) or falls back to displayName or email
    var currentFullName: String? {
        if let first = currentFirstName, !first.isEmpty {
            if let last = currentLastName, !last.isEmpty {
                return "\(first) \(last)"
            }
            return first
        }
        return currentDisplayName
    }

    @Published var tables: [SupabaseTable] = []
    @Published var reflections: [SupabaseReflection] = []
    @Published var isLoading = false
    @Published var error: String?

    private let authClient: AuthClient
    private let realtime: RealtimeClientV2

    private var realtimeChannel: RealtimeChannelV2?
    private var sharesRealtimeChannel: RealtimeChannelV2?
    private var cardsRealtimeChannels: [UUID: RealtimeChannelV2] = [:]
    private var cardChangeCallbacks: [UUID: () async -> Void] = [:]
    private var commentsRealtimeChannels: [UUID: RealtimeChannelV2] = [:]
    private var commentChangeCallbacks: [UUID: () async -> Void] = [:]
    private var currentAccessToken: String?

    // Notification system for real-time updates across users
    private var notificationChannel: RealtimeChannelV2?
    private var notificationPollingTask: Task<Void, Never>?

    // Local archive storage for shared tables (per-user, not synced to server)
    private let localArchivedTablesKey = "localArchivedTableIds"

    init() {
        // Initialize Auth client
        self.authClient = AuthClient(
            url: SupabaseConfig.projectURL.appendingPathComponent("auth/v1"),
            headers: ["apikey": SupabaseConfig.anonKey],
            localStorage: AuthLocalStorageImpl()
        )

        // Initialize Realtime client
        self.realtime = RealtimeClientV2(
            url: SupabaseConfig.projectURL.appendingPathComponent("realtime/v1"),
            options: RealtimeClientOptions(
                headers: ["apikey": SupabaseConfig.anonKey]
            )
        )

        Task {
            await checkSession()
        }
    }

    // Create a PostgREST client with the current auth token
    private var postgrest: PostgrestClient {
        let token = currentAccessToken ?? SupabaseConfig.anonKey
        return PostgrestClient(
            url: SupabaseConfig.projectURL.appendingPathComponent("rest/v1"),
            headers: [
                "apikey": SupabaseConfig.anonKey,
                "Authorization": "Bearer \(token)"
            ],
            logger: nil
        )
    }

    // MARK: - Authentication

    func checkSession() async {
        do {
            let session = try await authClient.session
            currentAccessToken = session.accessToken
            currentUserId = session.user.id
            currentUserEmail = session.user.email
            isAuthenticated = true
            await fetchProfile()
            await fetchTables()
            await fetchReflections()
            await setupRealtimeSubscription()
        } catch {
            isAuthenticated = false
            currentUserId = nil
            currentAccessToken = nil
        }
    }

    /// Refreshes the current session and updates the access token
    private func refreshSession() async throws {
        print("🔄 Refreshing session token...")
        let session = try await authClient.session
        currentAccessToken = session.accessToken
        print("✅ Session token refreshed successfully")
    }

    /// Executes an async operation with automatic token refresh on JWT expiration
    /// - Parameter operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: Re-throws the error if it's not a JWT expiration error or if refresh fails
    private func executeWithTokenRefresh<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            // Check if the error is a JWT expiration error
            let errorString = String(describing: error)
            if errorString.contains("JWT") && (errorString.contains("expired") || errorString.contains("invalid")) {
                print("⚠️ JWT token expired, attempting to refresh...")

                do {
                    // Try to refresh the session
                    try await refreshSession()

                    // Retry the operation with the new token
                    print("🔄 Retrying operation with refreshed token...")
                    return try await operation()
                } catch {
                    print("❌ Failed to refresh token: \(error)")
                    // If refresh fails, user needs to re-authenticate
                    isAuthenticated = false
                    currentAccessToken = nil
                    currentUserId = nil
                    throw SupabaseError.notAuthenticated
                }
            }

            // Not a JWT error, re-throw the original error
            throw error
        }
    }

    func signUp(email: String, password: String, displayName: String, firstName: String? = nil, lastName: String? = nil) async throws {
        let response = try await authClient.signUp(email: email, password: password)
        let user = response.user

        // Get the session to get the access token
        if let session = response.session {
            currentAccessToken = session.accessToken
        }

        currentUserId = user.id
        currentUserEmail = user.email
        isAuthenticated = true

        // Create profile with display name and first/last name
        try await createProfile(displayName: displayName, firstName: firstName, lastName: lastName)

        await setupRealtimeSubscription()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await authClient.signIn(email: email, password: password)
        currentAccessToken = session.accessToken
        currentUserId = session.user.id
        currentUserEmail = session.user.email
        isAuthenticated = true
        await fetchProfile()
        await fetchTables()
        await fetchReflections()
        await setupRealtimeSubscription()
    }

    func signOut() async throws {
        try await authClient.signOut()
        isAuthenticated = false
        currentUserId = nil
        currentUserEmail = nil
        currentDisplayName = nil
        currentFirstName = nil
        currentLastName = nil
        currentAccessToken = nil
        hasCompletedOnboarding = false
        tables = []
        reflections = []
        await removeRealtimeSubscription()
        await removeAllCardSubscriptions()
    }

    private func removeAllCardSubscriptions() async {
        for (_, channel) in cardsRealtimeChannels {
            await channel.unsubscribe()
        }
        cardsRealtimeChannels.removeAll()
        cardChangeCallbacks.removeAll()

        for (_, channel) in commentsRealtimeChannels {
            await channel.unsubscribe()
        }
        commentsRealtimeChannels.removeAll()
        commentChangeCallbacks.removeAll()
    }

    private func fetchProfile() async {
        guard let userId = currentUserId else { return }
        do {
            try await executeWithTokenRefresh {
                let response = try await self.postgrest
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()

                // Debug: Print raw response
                if let jsonString = String(data: response.data, encoding: .utf8) {
                    print("📋 Profile response: \(jsonString)")
                }

                let profile = try JSONDecoder.supabaseDecoder.decode(SupabaseProfile.self, from: response.data)
                self.currentDisplayName = profile.displayName
                self.currentFirstName = profile.firstName
                self.currentLastName = profile.lastName
                self.hasCompletedOnboarding = profile.hasCompletedOnboarding ?? false

                print("📋 Fetched profile - displayName: \(profile.displayName ?? "nil"), firstName: \(profile.firstName ?? "nil"), lastName: \(profile.lastName ?? "nil"), hasCompletedOnboarding: \(self.hasCompletedOnboarding)")
            }
        } catch {
            print("⚠️ Failed to fetch profile: \(error)")
            // Profile might not exist yet
        }
    }

    func createProfile(displayName: String, firstName: String? = nil, lastName: String? = nil) async throws {
        guard let userId = currentUserId else { return }

        try await executeWithTokenRefresh {
            // Compute display name from first/last if provided
            let effectiveDisplayName: String
            if let first = firstName, !first.isEmpty {
                if let last = lastName, !last.isEmpty {
                    effectiveDisplayName = "\(first) \(last)"
                } else {
                    effectiveDisplayName = first
                }
            } else {
                effectiveDisplayName = displayName
            }

            let profile = InsertProfile(
                id: userId,
                email: self.currentUserEmail,
                displayName: effectiveDisplayName,
                firstName: firstName,
                lastName: lastName
            )

            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(profile)

            try await self.postgrest
                .from("profiles")
                .insert(data)
                .execute()

            // Update local state
            self.currentDisplayName = effectiveDisplayName
            self.currentFirstName = firstName
            self.currentLastName = lastName
        }
    }

    func updateProfile(firstName: String, lastName: String) async throws {
        guard let userId = currentUserId else { return }

        // Capture ALL possible old names before updating (to find and replace in tables)
        // Include variations that might exist in the database
        var oldNames: Set<String> = []

        if let displayName = currentDisplayName, !displayName.isEmpty {
            oldNames.insert(displayName)
        }
        if let fullName = currentFullName, !fullName.isEmpty {
            oldNames.insert(fullName)
        }
        if let email = currentUserEmail, !email.isEmpty {
            oldNames.insert(email)
            // Also add variations of the email handle
            if let handle = email.components(separatedBy: "@").first, !handle.isEmpty {
                oldNames.insert(handle)
                // Common variations (with numbers stripped, etc.)
                let handleWithoutNumbers = handle.filter { !$0.isNumber }
                if !handleWithoutNumbers.isEmpty && handleWithoutNumbers != handle {
                    oldNames.insert(handleWithoutNumbers)
                }
            }
        }
        if let oldFirst = currentFirstName, !oldFirst.isEmpty {
            oldNames.insert(oldFirst)
        }
        if let oldLast = currentLastName, !oldLast.isEmpty {
            oldNames.insert(oldLast)
        }

        // ALSO scan existing tables for any member names that might be old versions of this user
        // This catches historical names that are no longer in the profile
        let allMembersInTables = Set(tables.flatMap { $0.members })
        let targetDisplayName = !firstName.isEmpty ? (lastName.isEmpty ? firstName : "\(firstName) \(lastName)") : (lastName.isEmpty ? "User" : lastName)

        // Check each member name - if it's similar to our email handle or initials, include it
        if let email = currentUserEmail, let handle = email.components(separatedBy: "@").first {
            for member in allMembersInTables {
                let memberLower = member.lowercased()
                let handleLower = handle.lowercased()

                // Include if member starts with same letters as email handle
                // or if it's a substring match
                if memberLower.hasPrefix(String(handleLower.prefix(4))) ||
                   handleLower.contains(memberLower) ||
                   memberLower.contains(handleLower) {
                    // Don't include the new name we're about to set
                    if member.lowercased() != targetDisplayName.lowercased() {
                        oldNames.insert(member)
                    }
                }
            }
        }

        print("📝 updateProfile: Old names to replace: \(oldNames)")

        // Compute new display name from first/last name
        let newDisplayName: String
        if !firstName.isEmpty {
            if !lastName.isEmpty {
                newDisplayName = "\(firstName) \(lastName)"
            } else {
                newDisplayName = firstName
            }
        } else {
            newDisplayName = lastName.isEmpty ? "User" : lastName
        }

        print("📝 updateProfile: New display name: \(newDisplayName)")

        try await executeWithTokenRefresh {
            // Use a dictionary for explicit control over what's sent
            var updateData: [String: String] = [
                "display_name": newDisplayName
            ]

            // Always include first_name and last_name (even if empty string)
            updateData["first_name"] = firstName
            updateData["last_name"] = lastName

            try await self.postgrest
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()

            // Update local state
            self.currentDisplayName = newDisplayName
            self.currentFirstName = firstName.isEmpty ? nil : firstName
            self.currentLastName = lastName.isEmpty ? nil : lastName
        }

        // Update member names in all tables where old name appears
        await updateMemberNameInTables(oldNames: oldNames, newName: newDisplayName)

        // Refresh tables to ensure we have the latest data
        await fetchTables()
    }

    /// Marks onboarding as complete for the current user
    func completeOnboarding() async {
        guard let userId = currentUserId else { return }

        do {
            try await executeWithTokenRefresh {
                try await self.postgrest
                    .from("profiles")
                    .update(["has_completed_onboarding": true])
                    .eq("id", value: userId.uuidString)
                    .execute()

                self.hasCompletedOnboarding = true
                print("✅ Onboarding marked as complete")
            }
        } catch {
            print("⚠️ Failed to mark onboarding complete: \(error)")
            // Still update local state so user can proceed
            self.hasCompletedOnboarding = true
        }
    }

    /// Updates the user's name in all tables' members arrays
    private func updateMemberNameInTables(oldNames: Set<String>, newName: String) async {
        print("📝 updateMemberNameInTables: Checking \(tables.count) tables for old names")

        // Create lowercased set for case-insensitive comparison
        let oldNamesLowercased = Set(oldNames.map { $0.lowercased() })

        for table in tables {
            var needsUpdate = false
            var updatedMembers = table.members

            for (index, member) in updatedMembers.enumerated() {
                // Case-insensitive comparison
                if oldNamesLowercased.contains(member.lowercased()) {
                    print("📝 Found match: '\(member)' in table '\(table.title)' -> replacing with '\(newName)'")
                    updatedMembers[index] = newName
                    needsUpdate = true
                }
            }

            if needsUpdate {
                // Remove duplicates (in case new name already exists)
                let uniqueMembers = Array(NSOrderedSet(array: updatedMembers)) as? [String] ?? updatedMembers

                do {
                    try await postgrest
                        .from("tables")
                        .update(["members": uniqueMembers])
                        .eq("id", value: table.id.uuidString)
                        .execute()

                    print("✅ Updated members in table '\(table.title)': \(uniqueMembers)")

                    // Update local state
                    if let index = tables.firstIndex(where: { $0.id == table.id }) {
                        var updatedTable = tables[index]
                        updatedTable.members = uniqueMembers
                        tables[index] = updatedTable
                    }
                } catch {
                    print("⚠️ Failed to update member name in table '\(table.title)': \(error)")
                }
            }
        }
    }

    // MARK: - Tables CRUD

    func fetchTables() async {
        guard isAuthenticated, let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await executeWithTokenRefresh {
                print("🔄 fetchTables() called - fetching from Supabase...")
                let response = try await self.postgrest
                    .from("tables")
                    .select()
                    .order("updated_at", ascending: false)
                    .execute()

                var fetchedTables = try JSONDecoder.supabaseDecoder.decode([SupabaseTable].self, from: response.data)

                // Apply local archive status for shared tables (non-owned)
                let localArchivedIds = self.getLocalArchivedTableIds()

                for index in fetchedTables.indices {
                    let table = fetchedTables[index]
                    // If user doesn't own this table and it's locally archived, override status
                    if table.ownerId != userId && localArchivedIds.contains(table.id) {
                        fetchedTables[index].status = "archived"
                        print("📦 Applied local archive to shared table '\(table.title)'")
                    }
                }

                // Debug: Log each table's status
                for table in fetchedTables {
                    print("📊 Fetched table '\(table.title)' - status: \(table.status)")
                }

                self.tables = fetchedTables
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createTable(title: String, context: String?, members: [String]) async throws -> SupabaseTable {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        return try await executeWithTokenRefresh {
            let newTable = InsertTable(
                id: UUID(),
                title: title,
                context: context,
                status: "active",
                members: members,
                nextReminderDate: nil,
                ownerId: userId
            )

            let response = try await self.postgrest
                .from("tables")
                .insert(newTable)
                .select()
                .single()
                .execute()

            let created = try JSONDecoder.supabaseDecoder.decode(SupabaseTable.self, from: response.data)
            self.tables.insert(created, at: 0)
            return created
        }
    }

    func updateTable(_ table: SupabaseTable) async throws {
        try await executeWithTokenRefresh {
            var updateData: [String: String?] = [
                "title": table.title,
                "status": table.status,
                "context": table.context,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]

            if let reminderDate = table.nextReminderDate {
                updateData["next_reminder_date"] = ISO8601DateFormatter().string(from: reminderDate)
            } else {
                // Reminder date was cleared - cancel any existing notifications
                await NotificationManager.shared.cancelTableReminder(tableId: table.id)
            }

            try await self.postgrest
                .from("tables")
                .update(updateData)
                .eq("id", value: table.id.uuidString)
                .execute()

            if let index = self.tables.firstIndex(where: { $0.id == table.id }) {
                self.tables[index] = table
            }
        }
    }

    func deleteTable(_ tableId: UUID) async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        // Check if user is the owner of this table
        guard let table = tables.first(where: { $0.id == tableId }) else {
            throw SupabaseError.tableNotFound
        }

        guard table.ownerId == userId else {
            throw SupabaseError.notTableOwner
        }

        try await executeWithTokenRefresh {
            // Get shared users BEFORE delete (needed for broadcast notifications)
            let shares = try await self.fetchShares(for: tableId)
            let tableTitle = self.tables.first { $0.id == tableId }?.title ?? ""

            // Delete table (this will cascade delete shares via foreign key)
            try await self.postgrest
                .from("tables")
                .delete()
                .eq("id", value: tableId.uuidString)
                .execute()

            // Cancel any scheduled notifications for this table
            await NotificationManager.shared.cancelTableReminder(tableId: tableId)

            // Update local state immediately
            self.tables.removeAll { $0.id == tableId }

            // Send broadcast notifications to all shared users
            for share in shares {
                await self.sendBroadcastNotification(
                    toUser: share.sharedWithUserId,
                    eventType: "table_deleted",
                    payload: [
                        "table_id": tableId.uuidString,
                        "table_title": tableTitle
                    ]
                )
            }
        }
    }

    // MARK: - Cards CRUD

    func fetchCards(for tableId: UUID) async throws -> [SupabaseCard] {
        try await executeWithTokenRefresh {
            let response = try await self.postgrest
                .from("cards")
                .select()
                .eq("table_id", value: tableId.uuidString)
                .order("created_at", ascending: false)
                .execute()

            return try JSONDecoder.supabaseDecoder.decode([SupabaseCard].self, from: response.data)
        }
    }

    func createCard(tableId: UUID, title: String?, body: String, linkUrl: String?) async throws -> SupabaseCard {
        try await executeWithTokenRefresh {
            let authorName = self.currentDisplayName ?? self.currentUserEmail ?? "Anonymous"

            let newCard = InsertCard(
                id: UUID(),
                tableId: tableId,
                title: title,
                body: body,
                linkUrl: linkUrl,
                authorName: authorName,
                status: "active"
            )

            let response = try await self.postgrest
                .from("cards")
                .insert(newCard)
                .select()
                .single()
                .execute()

            // Update the table's updated_at timestamp
            try await self.postgrest
                .from("tables")
                .update(["updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: tableId.uuidString)
                .execute()

            return try JSONDecoder.supabaseDecoder.decode(SupabaseCard.self, from: response.data)
        }
    }

    func updateCard(_ card: SupabaseCard) async throws {
        try await executeWithTokenRefresh {
            var updateData: [String: String] = [
                "body": card.body,
                "status": card.status
            ]

            if let title = card.title {
                updateData["title"] = title
            }
            if let linkUrl = card.linkUrl {
                updateData["link_url"] = linkUrl
            }

            try await self.postgrest
                .from("cards")
                .update(updateData)
                .eq("id", value: card.id.uuidString)
                .execute()
        }
    }

    func deleteCard(_ cardId: UUID) async throws {
        try await executeWithTokenRefresh {
            try await self.postgrest
                .from("cards")
                .delete()
                .eq("id", value: cardId.uuidString)
                .execute()
        }
    }

    func archiveTable(_ tableId: UUID) async throws {
        guard let userId = currentUserId else {
            print("❌ Archive failed: Not authenticated")
            throw SupabaseError.notAuthenticated
        }

        guard let table = tables.first(where: { $0.id == tableId }) else {
            print("❌ Archive failed: Table not found in local state")
            throw SupabaseError.tableNotFound
        }

        print("📋 Archive attempt - Table: '\(table.title)', Owner: \(table.ownerId), CurrentUser: \(userId)")

        if table.ownerId == userId {
            // Owner: update status on server
            try await executeWithTokenRefresh {
                print("🔄 Sending archive request to Supabase...")
                try await self.postgrest
                    .from("tables")
                    .update(["status": "archived"])
                    .eq("id", value: tableId.uuidString)
                    .execute()
                print("✅ Supabase archive request completed")

                // Cancel any scheduled notifications for archived tables
                await NotificationManager.shared.cancelTableReminder(tableId: tableId)

                if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                    var updatedTable = self.tables[index]
                    updatedTable.status = "archived"
                    self.tables[index] = updatedTable
                    print("✅ Local state updated - Table '\(updatedTable.title)' is now archived")
                }
            }
        } else {
            // Non-owner: archive locally only
            print("📦 Archiving shared table locally (non-owner)")
            addToLocalArchive(tableId)

            // Cancel any scheduled notifications
            await NotificationManager.shared.cancelTableReminder(tableId: tableId)

            // Update local state to reflect archived status
            if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                var updatedTable = self.tables[index]
                updatedTable.status = "archived"
                self.tables[index] = updatedTable
                print("✅ Local archive updated - Table '\(updatedTable.title)' is now archived locally")
            }
        }
    }

    // MARK: - Local Archive Management (for shared tables)

    private func getLocalArchivedTableIds() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: localArchivedTablesKey),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return []
        }
        return ids
    }

    private func saveLocalArchivedTableIds(_ ids: Set<UUID>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: localArchivedTablesKey)
        }
    }

    private func addToLocalArchive(_ tableId: UUID) {
        var ids = getLocalArchivedTableIds()
        ids.insert(tableId)
        saveLocalArchivedTableIds(ids)
    }

    private func removeFromLocalArchive(_ tableId: UUID) {
        var ids = getLocalArchivedTableIds()
        ids.remove(tableId)
        saveLocalArchivedTableIds(ids)
    }

    func isLocallyArchived(_ tableId: UUID) -> Bool {
        return getLocalArchivedTableIds().contains(tableId)
    }

    func unarchiveTable(_ tableId: UUID) async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        guard let table = tables.first(where: { $0.id == tableId }) else {
            throw SupabaseError.tableNotFound
        }

        if table.ownerId == userId {
            // Owner: update status on server
            try await executeWithTokenRefresh {
                try await self.postgrest
                    .from("tables")
                    .update(["status": "active"])
                    .eq("id", value: tableId.uuidString)
                    .execute()

                if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                    var updatedTable = self.tables[index]
                    updatedTable.status = "active"
                    self.tables[index] = updatedTable
                }
            }
        } else {
            // Non-owner: unarchive locally only
            print("📦 Unarchiving shared table locally (non-owner)")
            removeFromLocalArchive(tableId)

            // Update local state - restore to the server's actual status
            if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                // Fetch the actual status from server
                let response = try await self.postgrest
                    .from("tables")
                    .select()
                    .eq("id", value: tableId.uuidString)
                    .single()
                    .execute()

                let serverTable = try JSONDecoder.supabaseDecoder.decode(SupabaseTable.self, from: response.data)
                self.tables[index] = serverTable
                print("✅ Restored table '\(serverTable.title)' to server status: \(serverTable.status)")
            }
        }
    }

    // MARK: - Comments CRUD

    func fetchComments(for cardId: UUID) async throws -> [SupabaseComment] {
        try await executeWithTokenRefresh {
            let response = try await self.postgrest
                .from("comments")
                .select()
                .eq("card_id", value: cardId.uuidString)
                .order("created_at", ascending: true)
                .execute()

            return try JSONDecoder.supabaseDecoder.decode([SupabaseComment].self, from: response.data)
        }
    }

    func createComment(cardId: UUID, body: String) async throws -> SupabaseComment {
        try await executeWithTokenRefresh {
            let authorName = self.currentDisplayName ?? self.currentUserEmail ?? "Anonymous"

            let newComment = InsertComment(
                id: UUID(),
                cardId: cardId,
                body: body,
                authorName: authorName
            )

            let response = try await self.postgrest
                .from("comments")
                .insert(newComment)
                .select()
                .single()
                .execute()

            return try JSONDecoder.supabaseDecoder.decode(SupabaseComment.self, from: response.data)
        }
    }

    func deleteComment(_ commentId: UUID) async throws {
        try await executeWithTokenRefresh {
            try await self.postgrest
                .from("comments")
                .delete()
                .eq("id", value: commentId.uuidString)
                .execute()
        }
    }

    // MARK: - Nudges

    func createNudge(tableId: UUID, message: String?) async throws -> SupabaseNudge {
        try await executeWithTokenRefresh {
            let authorName = self.currentDisplayName ?? self.currentUserEmail ?? "Anonymous"

            let newNudge = InsertNudge(
                id: UUID(),
                tableId: tableId,
                authorName: authorName,
                message: message
            )

            let response = try await self.postgrest
                .from("nudges")
                .insert(newNudge)
                .select()
                .single()
                .execute()

            return try JSONDecoder.supabaseDecoder.decode(SupabaseNudge.self, from: response.data)
        }
    }

    func fetchNudges(for tableId: UUID) async throws -> [SupabaseNudge] {
        try await executeWithTokenRefresh {
            let response = try await self.postgrest
                .from("nudges")
                .select()
                .eq("table_id", value: tableId.uuidString)
                .order("created_at", ascending: false)
                .execute()

            return try JSONDecoder.supabaseDecoder.decode([SupabaseNudge].self, from: response.data)
        }
    }

    // MARK: - Reflections

    func fetchReflections() async {
        guard isAuthenticated, let userId = currentUserId else { return }

        do {
            try await executeWithTokenRefresh {
                let response = try await self.postgrest
                    .from("reflections")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()

                self.reflections = try JSONDecoder.supabaseDecoder.decode([SupabaseReflection].self, from: response.data)
                print("📋 Fetched \(self.reflections.count) reflections")
            }
        } catch {
            print("⚠️ Failed to fetch reflections: \(error)")
        }
    }

    func createReflection(body: String, prompt: String?, reflectionType: String) async throws -> SupabaseReflection {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        return try await executeWithTokenRefresh {
            let newReflection = InsertReflection(
                id: UUID(),
                userId: userId,
                body: body,
                prompt: prompt,
                reflectionType: reflectionType
            )

            let response = try await self.postgrest
                .from("reflections")
                .insert(newReflection)
                .select()
                .single()
                .execute()

            let created = try JSONDecoder.supabaseDecoder.decode(SupabaseReflection.self, from: response.data)
            self.reflections.insert(created, at: 0)
            print("✅ Created reflection: \(created.id)")
            return created
        }
    }

    func updateReflection(id: UUID, body: String) async throws {
        try await executeWithTokenRefresh {
            try await self.postgrest
                .from("reflections")
                .update([
                    "body": body,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: id.uuidString)
                .execute()

            if let index = self.reflections.firstIndex(where: { $0.id == id }) {
                self.reflections[index].body = body
                self.reflections[index].updatedAt = Date()
            }
            print("✅ Updated reflection: \(id)")
        }
    }

    func deleteReflection(_ reflectionId: UUID) async throws {
        try await executeWithTokenRefresh {
            try await self.postgrest
                .from("reflections")
                .delete()
                .eq("id", value: reflectionId.uuidString)
                .execute()

            self.reflections.removeAll { $0.id == reflectionId }
            print("✅ Deleted reflection: \(reflectionId)")
        }
    }

    func shareReflectionToTable(reflection: SupabaseReflection, tableId: UUID) async throws -> SupabaseCard {
        guard let displayName = currentDisplayName ?? currentUserEmail else {
            throw SupabaseError.notAuthenticated
        }

        return try await executeWithTokenRefresh {
            let card = InsertCard(
                id: UUID(),
                tableId: tableId,
                title: reflection.prompt,
                body: reflection.body,
                linkUrl: nil,
                authorName: displayName,
                status: "active",
                sourceReflectionId: reflection.id,
                sourcePrompt: reflection.prompt
            )

            let response = try await self.postgrest
                .from("cards")
                .insert(card)
                .select()
                .single()
                .execute()

            // Update the table's updated_at timestamp
            try await self.postgrest
                .from("tables")
                .update(["updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: tableId.uuidString)
                .execute()

            let createdCard = try JSONDecoder.supabaseDecoder.decode(SupabaseCard.self, from: response.data)
            print("✅ Shared reflection to table: \(tableId)")
            return createdCard
        }
    }

    func shareReflectionExcerptToTable(reflection: SupabaseReflection, tableId: UUID, excerptBody: String, title: String) async throws -> SupabaseCard {
        guard let displayName = currentDisplayName ?? currentUserEmail else {
            throw SupabaseError.notAuthenticated
        }

        return try await executeWithTokenRefresh {
            let card = InsertCard(
                id: UUID(),
                tableId: tableId,
                title: title,
                body: excerptBody,
                linkUrl: nil,
                authorName: displayName,
                status: "active",
                sourceReflectionId: reflection.id,
                sourcePrompt: reflection.prompt
            )

            let response = try await self.postgrest
                .from("cards")
                .insert(card)
                .select()
                .single()
                .execute()

            // Update the table's updated_at timestamp
            try await self.postgrest
                .from("tables")
                .update(["updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: tableId.uuidString)
                .execute()

            let createdCard = try JSONDecoder.supabaseDecoder.decode(SupabaseCard.self, from: response.data)
            print("✅ Shared reflection excerpt to table: \(tableId)")
            return createdCard
        }
    }

    // MARK: - Sharing

    func shareTable(tableId: UUID, withEmail email: String, permission: String = "write") async throws {
        try await executeWithTokenRefresh {
            print("🔍 shareTable called - tableId: \(tableId), email: \(email)")

            // Use RPC function to find user by email (bypasses RLS)
            let response = try await self.postgrest
                .rpc("find_user_by_email", params: ["search_email": email])
                .execute()

            struct UserSearchResult: Codable {
                let userId: UUID
                let userEmail: String?
                let displayName: String?

                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case userEmail = "user_email"
                    case displayName = "display_name"
                }
            }

            let results = try JSONDecoder.supabaseDecoder.decode([UserSearchResult].self, from: response.data)

            guard let targetUser = results.first else {
                print("❌ User not found: \(email)")
                throw SupabaseError.userNotFound
            }

            print("✅ Found user: \(targetUser.displayName ?? targetUser.userEmail ?? "unknown")")

            let sharedUserName = targetUser.displayName ?? targetUser.userEmail ?? email

            // OPTIMISTIC UPDATE: Update UI immediately for instant feedback
            if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                var optimisticTable = self.tables[index]
                if !optimisticTable.members.contains(sharedUserName) {
                    optimisticTable.members.append(sharedUserName)
                    self.tables[index] = optimisticTable
                    print("⚡️ Optimistic update applied - UI updated instantly")
                }
            }

            // Create share record
            let share = InsertTableShare(
                tableId: tableId,
                sharedWithUserId: targetUser.userId,
                permission: permission
            )

            try await self.postgrest
                .from("table_shares")
                .insert(share)
                .execute()

            print("✅ Created table_share record")

            // Use RPC function to add member atomically
            print("🔍 Adding member: \(sharedUserName)")

            try await self.postgrest
                .rpc(
                    "add_table_member",
                    params: [
                        "p_table_id": tableId.uuidString,
                        "p_member_name": sharedUserName
                    ]
                )
                .execute()

            print("✅ Member added via RPC")

            // Refresh the specific table to confirm server state
            let tableResponse = try await self.postgrest
                .from("tables")
                .select()
                .eq("id", value: tableId.uuidString)
                .single()
                .execute()

            let updatedTable = try JSONDecoder.supabaseDecoder.decode(SupabaseTable.self, from: tableResponse.data)

            print("✅ Server state confirmed - members count: \(updatedTable.members.count)")

            // Update local state with server confirmation
            if let index = self.tables.firstIndex(where: { $0.id == tableId }) {
                self.tables[index] = updatedTable
            } else {
                // Table not in local array yet - add it
                self.tables.append(updatedTable)
                self.tables.sort { $0.updatedAt > $1.updatedAt }
            }
        }
    }

    func removeShare(tableId: UUID, userId: UUID) async throws {
        try await executeWithTokenRefresh {
            try await self.postgrest
                .from("table_shares")
                .delete()
                .eq("table_id", value: tableId.uuidString)
                .eq("shared_with_user_id", value: userId.uuidString)
                .execute()
        }
    }

    /// Allows a user to leave a table that was shared with them
    func leaveSharedTable(_ tableId: UUID) async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        // Verify the user is NOT the owner (owners can't leave, they delete)
        guard let table = tables.first(where: { $0.id == tableId }) else {
            throw SupabaseError.tableNotFound
        }

        if table.ownerId == userId {
            throw SupabaseError.cannotLeaveOwnTable
        }

        try await executeWithTokenRefresh {
            // Delete the share record for this user
            try await self.postgrest
                .from("table_shares")
                .delete()
                .eq("table_id", value: tableId.uuidString)
                .eq("shared_with_user_id", value: userId.uuidString)
                .execute()

            // Remove the table from local state
            self.tables.removeAll { $0.id == tableId }
        }
    }

    func fetchShares(for tableId: UUID) async throws -> [SupabaseTableShare] {
        try await executeWithTokenRefresh {
            let response = try await self.postgrest
                .from("table_shares")
                .select()
                .eq("table_id", value: tableId.uuidString)
                .execute()

            return try JSONDecoder.supabaseDecoder.decode([SupabaseTableShare].self, from: response.data)
        }
    }

    // MARK: - User Search

    /// Search result for user lookup
    struct UserSearchResult: Identifiable {
        let id: UUID
        let email: String
        let displayName: String?
        let firstName: String?
        let lastName: String?

        var fullName: String? {
            if let first = firstName, !first.isEmpty {
                if let last = lastName, !last.isEmpty {
                    return "\(first) \(last)"
                }
                return first
            }
            return displayName
        }

        var displayText: String {
            fullName ?? displayName ?? email
        }
    }

    /// Searches for users by name or email
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        guard !query.isEmpty else { return [] }

        let searchTerm = query.lowercased()
        print("🔍 Searching users with query: '\(searchTerm)'")

        return try await executeWithTokenRefresh {
            // Build the OR filter for searching across multiple columns
            let orFilter = "email.ilike.*\(searchTerm)*,display_name.ilike.*\(searchTerm)*,first_name.ilike.*\(searchTerm)*,last_name.ilike.*\(searchTerm)*"

            let response = try await self.postgrest
                .from("profiles")
                .select()
                .or(orFilter)
                .limit(10)
                .execute()

            // Debug: Print raw response
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("🔍 Search response: \(jsonString)")
            }

            let profiles = try JSONDecoder.supabaseDecoder.decode([SupabaseProfile].self, from: response.data)
            print("🔍 Found \(profiles.count) profiles")

            // Filter out the current user
            let results = profiles
                .filter { $0.id != self.currentUserId }
                .map { profile in
                    UserSearchResult(
                        id: profile.id,
                        email: profile.email ?? "",
                        displayName: profile.displayName,
                        firstName: profile.firstName,
                        lastName: profile.lastName
                    )
                }

            print("🔍 Returning \(results.count) results (after filtering current user)")
            return results
        }
    }

    // MARK: - Realtime Subscriptions

    private func setupRealtimeSubscription() async {
        guard let userId = currentUserId else { return }

        await realtime.connect()

        // Subscribe to tables changes - filter to tables owned by this user
        let channel = realtime.channel("tables-changes-\(userId.uuidString)")
        let ownedChanges = channel.postgresChange(
            AnyAction.self,
            table: "tables",
            filter: "owner_id=eq.\(userId.uuidString)"
        )
        await channel.subscribe()

        Task {
            for await change in ownedChanges {
                print("🔔 Realtime: Owned table change detected - \(change)")
                await fetchTables()
            }
        }

        realtimeChannel = channel

        // Subscribe to table_shares changes - filter to shares for this user
        let sharesChannel = realtime.channel("table-shares-changes-\(userId.uuidString)")
        let sharesChanges = sharesChannel.postgresChange(
            AnyAction.self,
            table: "table_shares",
            filter: "shared_with_user_id=eq.\(userId.uuidString)"
        )
        await sharesChannel.subscribe()

        Task {
            for await _ in sharesChanges {
                print("🔔 Table share change detected - refreshing tables")
                await fetchTables()
            }
        }

        sharesRealtimeChannel = sharesChannel

        // Set up notification subscription for cross-user events
        await setupNotificationSubscription()

        // Start polling as a fallback mechanism
        startNotificationPolling()
    }

    private func removeRealtimeSubscription() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }

        if let sharesChannel = sharesRealtimeChannel {
            await sharesChannel.unsubscribe()
            sharesRealtimeChannel = nil
        }

        // Clean up notification channel
        if let notifChannel = notificationChannel {
            await notifChannel.unsubscribe()
            notificationChannel = nil
        }

        // Stop notification polling
        notificationPollingTask?.cancel()
        notificationPollingTask = nil
    }

    func subscribeToCardChanges(for tableId: UUID, onUpdate: @escaping () async -> Void) async {
        // Remove existing subscription if any
        await unsubscribeFromCardChanges(for: tableId)

        // Store the callback
        cardChangeCallbacks[tableId] = onUpdate

        let channel = realtime.channel("cards-\(tableId.uuidString)")

        let changes = channel.postgresChange(
            AnyAction.self,
            table: "cards",
            filter: "table_id=eq.\(tableId.uuidString)"
        )

        await channel.subscribe()

        Task {
            for await _ in changes {
                if let callback = cardChangeCallbacks[tableId] {
                    await callback()
                }
            }
        }

        cardsRealtimeChannels[tableId] = channel
    }

    func unsubscribeFromCardChanges(for tableId: UUID) async {
        if let channel = cardsRealtimeChannels[tableId] {
            await channel.unsubscribe()
            cardsRealtimeChannels.removeValue(forKey: tableId)
        }
        cardChangeCallbacks.removeValue(forKey: tableId)
    }

    func subscribeToCommentChanges(for cardId: UUID, onUpdate: @escaping () async -> Void) async {
        // Remove existing subscription if any
        await unsubscribeFromCommentChanges(for: cardId)

        // Store the callback
        commentChangeCallbacks[cardId] = onUpdate

        let channel = realtime.channel("comments-\(cardId.uuidString)")

        let changes = channel.postgresChange(
            AnyAction.self,
            table: "comments",
            filter: "card_id=eq.\(cardId.uuidString)"
        )

        await channel.subscribe()

        Task {
            for await _ in changes {
                if let callback = commentChangeCallbacks[cardId] {
                    await callback()
                }
            }
        }

        commentsRealtimeChannels[cardId] = channel
    }

    func unsubscribeFromCommentChanges(for cardId: UUID) async {
        if let channel = commentsRealtimeChannels[cardId] {
            await channel.unsubscribe()
            commentsRealtimeChannels.removeValue(forKey: cardId)
        }
        commentChangeCallbacks.removeValue(forKey: cardId)
    }

    // MARK: - Cross-User Notification System

    /// Sets up a broadcast channel subscription for receiving notifications from other users
    private func setupNotificationSubscription() async {
        guard let userId = currentUserId else { return }

        let channelName = "user-notifications-\(userId.uuidString)"
        let channel = realtime.channel(channelName)

        // Subscribe to the notification channel for database changes
        let notificationChanges = channel.postgresChange(
            AnyAction.self,
            table: "realtime_notifications",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        await channel.subscribe()

        Task {
            for await change in notificationChanges {
                await handleNotificationChange(change)
            }
        }

        notificationChannel = channel
        print("📡 Notification subscription established for user: \(userId.uuidString)")
    }

    /// Handles incoming notification changes from the database
    private func handleNotificationChange(_ change: AnyAction) async {
        // When a new notification is inserted, process it
        switch change {
        case .insert(let action):
            if let payload = action.record["payload"] as? [String: Any],
               let eventType = action.record["event_type"] as? String {
                await processNotificationEvent(eventType: eventType, payload: payload)

                // Mark notification as processed
                if let idString = action.record["id"] as? String,
                   let notificationId = UUID(uuidString: idString) {
                    await markNotificationProcessed(notificationId)
                }
            }
        default:
            break
        }
    }

    /// Processes a notification event based on its type
    private func processNotificationEvent(eventType: String, payload: [String: Any]) async {
        print("🔔 Processing notification: \(eventType)")

        switch eventType {
        case "table_deleted":
            if let tableIdString = payload["table_id"] as? String,
               let tableId = UUID(uuidString: tableIdString) {
                print("📤 Remote table deletion detected: \(tableId)")
                self.tables.removeAll { $0.id == tableId }
            }

        case "share_created":
            print("📥 New table share detected - refreshing tables")
            await fetchTables()

        case "member_added":
            print("👥 New member added - refreshing tables")
            await fetchTables()

        default:
            print("⚠️ Unknown notification type: \(eventType) - refreshing tables")
            await fetchTables()
        }
    }

    /// Marks a notification as processed in the database
    private func markNotificationProcessed(_ notificationId: UUID) async {
        do {
            try await postgrest
                .from("realtime_notifications")
                .update(["processed": true])
                .eq("id", value: notificationId.uuidString)
                .execute()
        } catch {
            print("⚠️ Failed to mark notification as processed: \(error)")
        }
    }

    /// Starts periodic polling for notifications as a fallback mechanism
    private func startNotificationPolling() {
        notificationPollingTask = Task {
            while !Task.isCancelled {
                await processNotificationQueue()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
        print("⏰ Notification polling started (30s interval)")
    }

    /// Processes any unprocessed notifications from the queue
    private func processNotificationQueue() async {
        guard isAuthenticated, currentUserId != nil else { return }

        do {
            let response = try await postgrest
                .from("realtime_notifications")
                .select()
                .eq("processed", value: false)
                .order("created_at", ascending: true)
                .execute()

            struct QueuedNotification: Codable {
                let id: UUID
                let eventType: String
                let payload: [String: String]

                enum CodingKeys: String, CodingKey {
                    case id
                    case eventType = "event_type"
                    case payload
                }
            }

            let notifications = try JSONDecoder().decode([QueuedNotification].self, from: response.data)

            if !notifications.isEmpty {
                print("📬 Processing \(notifications.count) queued notification(s)")
            }

            for notification in notifications {
                // Convert [String: String] to [String: Any] for processing
                let payload: [String: Any] = notification.payload.reduce(into: [:]) { $0[$1.key] = $1.value }
                await processNotificationEvent(eventType: notification.eventType, payload: payload)
                await markNotificationProcessed(notification.id)
            }
        } catch {
            // Silently handle errors during polling - this is a fallback mechanism
            // print("⚠️ Notification polling error: \(error)")
        }
    }

    /// Sends a broadcast notification to a specific user
    private func sendBroadcastNotification(toUser userId: UUID, eventType: String, payload: [String: String]) async {
        // Insert directly into notification queue - the recipient will receive it via their subscription
        do {
            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            let payloadJson = String(data: payloadData, encoding: .utf8) ?? "{}"

            try await postgrest
                .from("realtime_notifications")
                .insert([
                    "user_id": userId.uuidString,
                    "event_type": eventType,
                    "payload": payloadJson
                ])
                .execute()

            print("📤 Broadcast notification sent to user: \(userId.uuidString), event: \(eventType)")
        } catch {
            print("⚠️ Failed to send broadcast notification: \(error)")
        }
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case memberUpdateFailed(String)
    case tableNotFound
    case notTableOwner
    case cannotLeaveOwnTable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .userNotFound:
            return "User not found. Make sure they have an account."
        case .memberUpdateFailed(let reason):
            return "Failed to add member: \(reason)"
        case .tableNotFound:
            return "Table not found."
        case .notTableOwner:
            return "Only the table owner can archive or delete this table."
        case .cannotLeaveOwnTable:
            return "You cannot leave a table you own. Archive or delete it instead."
        }
    }
}

// MARK: - Auth Local Storage

final class AuthLocalStorageImpl: Auth.AuthLocalStorage, @unchecked Sendable {
    private let defaults = UserDefaults.standard
    private let keyPrefix = "supabase.auth.session"

    func retrieve(key: String) throws -> Data? {
        defaults.data(forKey: keyPrefix + "." + key)
    }

    func store(key: String, value: Data) throws {
        defaults.set(value, forKey: keyPrefix + "." + key)
    }

    func remove(key: String) throws {
        defaults.removeObject(forKey: keyPrefix + "." + key)
    }
}

// MARK: - JSON Coding Helpers

extension JSONDecoder {
    static let supabaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try standard ISO8601
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let supabaseEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
