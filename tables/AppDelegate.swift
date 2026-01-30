import UIKit
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()

        // Request local notification permissions
        Task { @MainActor in
            await NotificationManager.shared.requestAuthorization()
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // CloudKit automatically uses this token when registered
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Silent failure - app still works without push notifications
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Check if this is a CloudKit notification
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        // SwiftData with .automatic handles syncing automatically when it receives
        // CloudKit push notifications, so we just need to acknowledge receipt
        if notification.subscriptionID != nil {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            do {
                try await CKContainer.default().accept(cloudKitShareMetadata)
            } catch {
                // Share acceptance failed - user can try accepting again via the share link
            }
        }
    }
}
