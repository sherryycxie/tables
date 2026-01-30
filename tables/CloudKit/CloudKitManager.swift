import CloudKit
import Combine
import UserNotifications

@MainActor
final class CloudKitManager: ObservableObject {
    private var container: CKContainer?
    private var hasConfigured = false
    private var isCloudKitAvailable = false

    // SwiftData prefixes record types with "CD_"
    private let recordTypes = [
        "CD_TableModel",
        "CD_CardModel",
        "CD_CommentModel",
        "CD_NudgeModel"
    ]

    func configureIfNeeded() async {
        guard !hasConfigured else { return }
        hasConfigured = true

        // Check if CloudKit is available before proceeding
        await checkCloudKitAvailability()

        await requestNotificationPermission()

        if isCloudKitAvailable {
            await registerAllSubscriptions()
        }
    }

    private func checkCloudKitAvailability() async {
        let tempContainer = CKContainer.default()

        do {
            let status = try await tempContainer.accountStatus()
            if status == .available {
                container = tempContainer
                isCloudKitAvailable = true
            }
        } catch {
            // CloudKit not available - app will work in local-only mode
            isCloudKitAvailable = false
        }
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // User can still use the app without notifications.
        }
    }

    private func registerAllSubscriptions() async {
        guard let container = container else { return }

        // Subscribe to both private database (cross-device sync)
        // and shared database (collaborator changes)
        await registerSubscriptions(for: container.privateCloudDatabase, databaseScope: "private")
        await registerSubscriptions(for: container.sharedCloudDatabase, databaseScope: "shared")
    }

    private func registerSubscriptions(for database: CKDatabase, databaseScope: String) async {
        // Check existing subscriptions to avoid duplicates
        let existingIDs = await fetchExistingSubscriptionIDs(from: database)

        for recordType in recordTypes {
            let subscriptionID = "\(recordType)-\(databaseScope)-subscription"

            // Skip if subscription already exists
            guard !existingIDs.contains(subscriptionID) else {
                continue
            }

            await createSubscription(
                for: recordType,
                subscriptionID: subscriptionID,
                in: database
            )
        }
    }

    private func fetchExistingSubscriptionIDs(from database: CKDatabase) async -> Set<String> {
        do {
            let subscriptions = try await database.allSubscriptions()
            return Set(subscriptions.map { $0.subscriptionID })
        } catch {
            return []
        }
    }

    private func createSubscription(
        for recordType: String,
        subscriptionID: String,
        in database: CKDatabase
    ) async {
        let predicate = NSPredicate(value: true)

        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [
                .firesOnRecordCreation,
                .firesOnRecordUpdate,
                .firesOnRecordDeletion
            ]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        // Only show visible notifications for nudges
        if recordType == "CD_NudgeModel" {
            notificationInfo.alertBody = "You have a new nudge to revisit a Table."
            notificationInfo.soundName = "default"
        }

        subscription.notificationInfo = notificationInfo

        do {
            _ = try await database.save(subscription)
        } catch {
            // Ignore errors (already exists, unavailable, etc.).
        }
    }

    // MARK: - Share Acceptance

    func acceptShare(from metadata: CKShare.Metadata) async throws {
        guard let container = container else {
            throw CloudKitError.notAvailable
        }
        try await container.accept(metadata)
    }
}

enum CloudKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        }
    }
}
