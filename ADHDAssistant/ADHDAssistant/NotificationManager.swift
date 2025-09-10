import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var invasiveMode = true
    @Published var reminderInterval: TimeInterval = 300 // 5 minutes
    @Published var maxRemindersPerTask = 10
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var reminderTimers: [String: Timer] = [:]
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupNotificationCategories()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories
    private func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark as Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 min",
            options: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([taskCategory])
    }
    
    // MARK: - Invasive Reminders
    func scheduleInvasiveReminders(for task: Task) {
        guard invasiveMode && isAuthorized else { return }
        
        let taskId = task.id.uuidString
        var reminderCount = 0
        
        func scheduleNextReminder() {
            guard reminderCount < maxRemindersPerTask else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "🚨 Task Reminder"
            content.body = getInvasiveMessage(for: task, reminderCount: reminderCount)
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "TASK_REMINDER"
            content.userInfo = [
                "taskId": taskId,
                "taskTitle": task.title,
                "reminderCount": reminderCount
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: reminderInterval,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "\(taskId)_\(reminderCount)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
            
            reminderCount += 1
            
            // Schedule the next reminder
            DispatchQueue.main.asyncAfter(deadline: .now() + reminderInterval) {
                scheduleNextReminder()
            }
        }
        
        // Start the reminder cycle
        scheduleNextReminder()
    }
    
    private func getInvasiveMessage(for task: Task, reminderCount: Int) -> String {
        let messages = [
            "Hey! Don't forget: \(task.title)",
            "Still need to do: \(task.title) - You got this! 💪",
            "Task alert: \(task.title) - Time to focus! 🎯",
            "Reminder: \(task.title) - Break it down into smaller steps! ✨",
            "Don't let this slip: \(task.title) - You're capable! 🌟",
            "Task: \(task.title) - Set a 5-minute timer and start! ⏰",
            "Hey there! \(task.title) is waiting - You can do this! 🚀",
            "Friendly nudge: \(task.title) - One step at a time! 👣",
            "Task reminder: \(task.title) - Your future self will thank you! 🙏",
            "Last call: \(task.title) - You're stronger than you think! 💎"
        ]
        
        let index = min(reminderCount, messages.count - 1)
        return messages[index]
    }
    
    // MARK: - Task Completion Notifications
    func scheduleCompletionCelebration(for task: Task) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Task Completed!"
        content.body = "Great job finishing '\(task.title)'! You're making progress! 🌟"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "completion_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Daily Motivation
    func scheduleDailyMotivation() {
        guard isAuthorized else { return }
        
        let motivationalMessages = [
            "Good morning! Today is a fresh start. What's one thing you want to accomplish? ☀️",
            "You've got this! Remember: progress, not perfection. 🌱",
            "Your ADHD brain is a superpower - let's channel it today! ⚡",
            "Small steps lead to big changes. What's your first move? 👣",
            "You're not behind, you're exactly where you need to be. 💫",
            "Today's challenge: Pick one task and give it your full attention for 10 minutes. 🎯",
            "Your brain works differently, and that's your strength! 🧠✨",
            "Remember: done is better than perfect. Let's get something done! ✅"
        ]
        
        let randomMessage = motivationalMessages.randomElement() ?? motivationalMessages[0]
        
        let content = UNMutableNotificationContent()
        content.title = "Daily ADHD Support"
        content.body = randomMessage
        content.sound = .default
        content.badge = 1
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_motivation",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Cleanup
    func cancelReminders(for taskId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let taskRequests = requests.filter { request in
                request.identifier.contains(taskId)
            }
            
            let identifiers = taskRequests.map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Settings
    func updateReminderInterval(_ interval: TimeInterval) {
        reminderInterval = interval
        UserDefaults.standard.set(interval, forKey: "reminder_interval")
    }
    
    func updateInvasiveMode(_ enabled: Bool) {
        invasiveMode = enabled
        UserDefaults.standard.set(enabled, forKey: "invasive_mode")
    }
    
    func updateMaxReminders(_ count: Int) {
        maxRemindersPerTask = count
        UserDefaults.standard.set(count, forKey: "max_reminders")
    }
}