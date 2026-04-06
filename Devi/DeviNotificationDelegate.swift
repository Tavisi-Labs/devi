// MARK: - DeviNotificationDelegate.swift
// Routes notification taps to the appropriate app state.

import UserNotifications

@MainActor
final class DeviNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var vm: PanchangViewModel?

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let category = response.notification.request.content.categoryIdentifier
        if category == NotificationService.ritualReminderCategory {
            Task { @MainActor [weak self] in
                self?.vm?.deepLinkToRitual()
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
