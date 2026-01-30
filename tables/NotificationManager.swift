import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Permission Management

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Notifications

    func scheduleTableReminder(
        tableId: UUID,
        tableTitle: String,
        message: String?,
        date: Date
    ) async throws {
        // Check authorization
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else {
                throw NotificationError.notAuthorized
            }
        }

        // Cancel any existing notification for this table
        cancelTableReminder(tableId: tableId)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to revisit: \(tableTitle)"

        if let message = message, !message.isEmpty {
            content.body = message
        } else {
            content.body = "It's time to check in on this table with your collaborators."
        }

        content.sound = .default
        content.badge = 1

        // Add table ID to userInfo for deep linking
        content.userInfo = [
            "tableId": tableId.uuidString,
            "type": "tableReminder"
        ]

        // Create trigger from date components
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let identifier = notificationIdentifier(for: tableId)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        try await notificationCenter.add(request)

        print("✅ Scheduled notification for table '\(tableTitle)' at \(date)")
    }

    // MARK: - Cancel Notifications

    func cancelTableReminder(tableId: UUID) {
        let identifier = notificationIdentifier(for: tableId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled notification for table: \(tableId)")
    }

    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all pending notifications")
    }

    // MARK: - Query Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    func hasPendingReminder(for tableId: UUID) async -> Bool {
        let pending = await getPendingNotifications()
        let identifier = notificationIdentifier(for: tableId)
        return pending.contains { $0.identifier == identifier }
    }

    // MARK: - Helpers

    private func notificationIdentifier(for tableId: UUID) -> String {
        "table-reminder-\(tableId.uuidString)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle table reminder notifications
        if let tableIdString = userInfo["tableId"] as? String,
           let tableId = UUID(uuidString: tableIdString) {

            // Post notification for deep linking
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .openTable,
                    object: nil,
                    userInfo: ["tableId": tableId]
                )
            }

            print("📱 User tapped notification for table: \(tableId)")
        }

        completionHandler()
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not enabled. Please enable them in Settings."
        case .schedulingFailed:
            return "Failed to schedule notification. Please try again."
        }
    }
}

// MARK: - Deep Linking Support

extension Notification.Name {
    static let openTable = Notification.Name("openTable")
}
