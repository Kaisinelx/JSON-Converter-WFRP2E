import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

class AppBlockManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var blockedApps: Set<String> = []
    @Published var isBlockingActive = false
    @Published var blockUntilAllTasksComplete = true
    
    private let managedSettingsStore = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // Common distracting apps
    let distractingApps = [
        "com.burbn.instagram": "Instagram",
        "com.google.ios.youtube": "YouTube",
        "com.twitter.ios": "Twitter/X",
        "com.facebook.Facebook": "Facebook",
        "com.tiktok": "TikTok",
        "com.reddit.Reddit": "Reddit",
        "com.netflix.Netflix": "Netflix",
        "com.spotify.client": "Spotify",
        "com.snapchat.snapchat": "Snapchat",
        "com.pinterest": "Pinterest"
    ]
    
    init() {
        loadSettings()
    }
    
    // MARK: - Permission Management
    func requestScreenTimePermission() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    self.isAuthorized = true
                }
            } catch {
                print("Failed to request Screen Time permission: \(error)")
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - App Blocking
    func toggleAppBlocking() {
        if isBlockingActive {
            disableAppBlocking()
        } else {
            enableAppBlocking()
        }
    }
    
    func enableAppBlocking() {
        guard isAuthorized else {
            requestScreenTimePermission()
            return
        }
        
        // Block selected apps
        let tokens = Set(blockedApps.compactMap { bundleId in
            ApplicationToken(application: BundleIdentifier(bundleId))
        })
        
        managedSettingsStore.application.blockedApplications = tokens
        
        // Block categories if needed
        managedSettingsStore.application.blockedApplicationCategories = [
            .socialNetworking,
            .entertainment,
            .games
        ]
        
        isBlockingActive = true
        saveSettings()
        
        // Schedule device activity monitoring
        scheduleDeviceActivityMonitoring()
    }
    
    func disableAppBlocking() {
        managedSettingsStore.application.blockedApplications = Set()
        managedSettingsStore.application.blockedApplicationCategories = Set()
        
        isBlockingActive = false
        saveSettings()
        
        // Cancel device activity monitoring
        cancelDeviceActivityMonitoring()
    }
    
    // MARK: - App Selection
    func toggleAppBlocking(_ bundleId: String) {
        if blockedApps.contains(bundleId) {
            blockedApps.remove(bundleId)
        } else {
            blockedApps.insert(bundleId)
        }
        saveSettings()
    }
    
    func selectCommonDistractingApps() {
        blockedApps = Set(distractingApps.keys)
        saveSettings()
    }
    
    func clearBlockedApps() {
        blockedApps.removeAll()
        saveSettings()
    }
    
    // MARK: - Device Activity Monitoring
    private func scheduleDeviceActivityMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("TaskFocusMode")
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("Failed to start device activity monitoring: \(error)")
        }
    }
    
    private func cancelDeviceActivityMonitoring() {
        let activityName = DeviceActivityName("TaskFocusMode")
        deviceActivityCenter.stopMonitoring([activityName])
    }
    
    // MARK: - Task-Based Blocking
    func updateBlockingBasedOnTasks(_ tasks: [Task]) {
        guard blockUntilAllTasksComplete else { return }
        
        let hasIncompleteTasks = tasks.contains { !$0.isCompleted }
        
        if hasIncompleteTasks && !isBlockingActive {
            enableAppBlocking()
        } else if !hasIncompleteTasks && isBlockingActive {
            // Optionally disable blocking when all tasks are complete
            // For now, we'll keep it active and let user manually disable
        }
    }
    
    // MARK: - Settings Persistence
    private func saveSettings() {
        UserDefaults.standard.set(Array(blockedApps), forKey: "blocked_apps")
        UserDefaults.standard.set(isBlockingActive, forKey: "blocking_active")
        UserDefaults.standard.set(blockUntilAllTasksComplete, forKey: "block_until_tasks_complete")
    }
    
    private func loadSettings() {
        if let savedApps = UserDefaults.standard.array(forKey: "blocked_apps") as? [String] {
            blockedApps = Set(savedApps)
        } else {
            // Default to blocking common distracting apps
            selectCommonDistractingApps()
        }
        
        isBlockingActive = UserDefaults.standard.bool(forKey: "blocking_active")
        blockUntilAllTasksComplete = UserDefaults.standard.bool(forKey: "block_until_tasks_complete")
    }
    
    // MARK: - App Information
    func getAppName(for bundleId: String) -> String {
        return distractingApps[bundleId] ?? bundleId
    }
    
    func getAppIcon(for bundleId: String) -> String {
        // Return emoji icons for common apps
        let appIcons: [String: String] = [
            "com.burbn.instagram": "📷",
            "com.google.ios.youtube": "📺",
            "com.twitter.ios": "🐦",
            "com.facebook.Facebook": "👥",
            "com.tiktok": "🎵",
            "com.reddit.Reddit": "🤖",
            "com.netflix.Netflix": "🎬",
            "com.spotify.client": "🎧",
            "com.snapchat.snapchat": "👻",
            "com.pinterest": "📌"
        ]
        
        return appIcons[bundleId] ?? "📱"
    }
    
    // MARK: - Statistics
    var blockedAppsCount: Int {
        blockedApps.count
    }
    
    var isAnyAppBlocked: Bool {
        !blockedApps.isEmpty
    }
}