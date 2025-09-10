import SwiftUI
import UserNotifications

@main
struct ADHDAssistantApp: App {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var appBlockManager = AppBlockManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(notificationManager)
                .environmentObject(appBlockManager)
                .onAppear {
                    notificationManager.requestPermission()
                    appBlockManager.requestScreenTimePermission()
                }
        }
    }
}