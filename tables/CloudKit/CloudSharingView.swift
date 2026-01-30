import SwiftUI
import CloudKit
import UIKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onSaveShare: ((CKShare) -> Void)?
    var onStopSharing: (() -> Void)?
    var onError: ((Error) -> Void)?

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSaveShare: onSaveShare,
            onStopSharing: onStopSharing,
            onError: onError
        )
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        var onSaveShare: ((CKShare) -> Void)?
        var onStopSharing: (() -> Void)?
        var onError: ((Error) -> Void)?

        init(
            onSaveShare: ((CKShare) -> Void)?,
            onStopSharing: (() -> Void)?,
            onError: ((Error) -> Void)?
        ) {
            self.onSaveShare = onSaveShare
            self.onStopSharing = onStopSharing
            self.onError = onError
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            onError?(error)
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            if let share = csc.share {
                onSaveShare?(share)
            }
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onStopSharing?()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Tables"
        }
    }
}

extension CKShare: @retroactive Identifiable {
    public var id: CKRecord.ID { recordID }
}
