// Services/Notification/NotificationManager.swift
// KrishiDrishti — Handles local alert schedules, permissions, and background push notifications

import UserNotifications

protocol NotificationManagerProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleAdvisoryNotification(title: String, body: String, hour: Int, minute: Int) async throws
    func cancelAllNotifications()
}

final class NotificationManager: NotificationManagerProtocol {
    init() {}

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleAdvisoryNotification(title: String, body: String, hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "kd_advisory_daily",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
