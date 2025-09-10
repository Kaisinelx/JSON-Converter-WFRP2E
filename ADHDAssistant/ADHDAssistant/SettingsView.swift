import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var appBlockManager: AppBlockManager
    @State private var showingAppSelection = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // Notification Settings
                Section("Notifications") {
                    Toggle("Invasive Mode", isOn: $notificationManager.invasiveMode)
                        .onChange(of: notificationManager.invasiveMode) { value in
                            notificationManager.updateInvasiveMode(value)
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Interval")
                        Text("\(formatTimeInterval(notificationManager.reminderInterval))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $notificationManager.reminderInterval, in: 60...3600, step: 60) {
                            Text("Reminder interval")
                        }
                        .onChange(of: notificationManager.reminderInterval) { value in
                            notificationManager.updateReminderInterval(value)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Reminders per Task")
                        Text("\(notificationManager.maxRemindersPerTask) reminders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(notificationManager.maxRemindersPerTask) },
                            set: { notificationManager.updateMaxReminders(Int($0)) }
                        ), in: 1...20, step: 1) {
                            Text("Max reminders")
                        }
                    }
                }
                
                // App Blocking Settings
                Section("App Blocking") {
                    Toggle("Block Until All Tasks Complete", isOn: $appBlockManager.blockUntilAllTasksComplete)
                        .onChange(of: appBlockManager.blockUntilAllTasksComplete) { value in
                            UserDefaults.standard.set(value, forKey: "block_until_tasks_complete")
                        }
                    
                    Button("Select Apps to Block") {
                        showingAppSelection = true
                    }
                    
                    if !appBlockManager.blockedApps.isEmpty {
                        Button("Clear All Blocked Apps") {
                            appBlockManager.clearBlockedApps()
                        }
                        .foregroundColor(.red)
                    }
                    
                    if !appBlockManager.isAuthorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Screen Time Permission Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("To block apps, you need to grant Screen Time permissions in Settings > Screen Time > App Limits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Request Permission") {
                                appBlockManager.requestScreenTimePermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Accessibility Settings
                Section("Accessibility") {
                    NavigationLink("ADHD-Friendly Features") {
                        AccessibilitySettingsView()
                    }
                    
                    NavigationLink("Focus Techniques") {
                        FocusTechniquesView()
                    }
                }
                
                // Data Management
                Section("Data") {
                    NavigationLink("Export Tasks") {
                        ExportView()
                    }
                    
                    Button("Clear All Data") {
                        // This would need to be implemented with confirmation
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section("About") {
                    Button("About ADHD Assistant") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAppSelection) {
            AppSelectionView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

struct AppSelectionView: View {
    @EnvironmentObject var appBlockManager: AppBlockManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Common Distracting Apps") {
                    ForEach(Array(appBlockManager.distractingApps.keys.sorted()), id: \.self) { bundleId in
                        AppSelectionRow(
                            bundleId: bundleId,
                            appName: appBlockManager.distractingApps[bundleId] ?? bundleId,
                            icon: appBlockManager.getAppIcon(for: bundleId),
                            isSelected: appBlockManager.blockedApps.contains(bundleId)
                        ) {
                            appBlockManager.toggleAppBlocking(bundleId)
                        }
                    }
                }
                
                Section {
                    Button("Select All Common Apps") {
                        appBlockManager.selectCommonDistractingApps()
                    }
                    
                    Button("Clear Selection") {
                        appBlockManager.clearBlockedApps()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Select Apps to Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppSelectionRow: View {
    let bundleId: String
    let appName: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            
            Text(appName)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .green : .gray)
                .font(.title2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct AccessibilitySettingsView: View {
    @AppStorage("highContrastMode") private var highContrastMode = false
    @AppStorage("largeTextMode") private var largeTextMode = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        List {
            Section("Visual Accessibility") {
                Toggle("High Contrast Mode", isOn: $highContrastMode)
                
                Toggle("Large Text Mode", isOn: $largeTextMode)
                
                Toggle("Reduce Motion", isOn: $reduceMotion)
            }
            
            Section("Interaction") {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
            }
            
            Section("ADHD-Specific Features") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("These features are designed specifically for ADHD users:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    FeatureRow(
                        icon: "bell.fill",
                        title: "Invasive Notifications",
                        description: "Persistent reminders that won't let you forget"
                    )
                    
                    FeatureRow(
                        icon: "shield.fill",
                        title: "App Blocking",
                        description: "Block distracting apps until tasks are done"
                    )
                    
                    FeatureRow(
                        icon: "chart.bar.fill",
                        title: "Progress Tracking",
                        description: "Visual progress to maintain motivation"
                    )
                    
                    FeatureRow(
                        icon: "star.fill",
                        title: "Achievement System",
                        description: "Celebrate small wins to build momentum"
                    )
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FocusTechniquesView: View {
    let techniques = [
        FocusTechnique(
            name: "Pomodoro Technique",
            description: "Work for 25 minutes, then take a 5-minute break",
            steps: [
                "Set a timer for 25 minutes",
                "Focus on one task until the timer rings",
                "Take a 5-minute break",
                "Repeat 4 times, then take a longer break"
            ],
            icon: "timer"
        ),
        FocusTechnique(
            name: "Body Doubling",
            description: "Work alongside someone else to stay accountable",
            steps: [
                "Find a study or work partner",
                "Work on separate tasks in the same space",
                "Check in with each other periodically",
                "Use video calls if in-person isn't possible"
            ],
            icon: "person.2.fill"
        ),
        FocusTechnique(
            name: "Time Blocking",
            description: "Schedule specific times for specific tasks",
            steps: [
                "Plan your day in advance",
                "Assign specific time slots to tasks",
                "Include buffer time between tasks",
                "Stick to the schedule as much as possible"
            ],
            icon: "calendar"
        ),
        FocusTechnique(
            name: "Two-Minute Rule",
            description: "If it takes less than 2 minutes, do it now",
            steps: [
                "When you think of a small task",
                "Ask: 'Can I do this in 2 minutes?'",
                "If yes, do it immediately",
                "If no, add it to your task list"
            ],
            icon: "clock.fill"
        ),
        FocusTechnique(
            name: "Distraction List",
            description: "Write down random thoughts to clear your mind",
            steps: [
                "Keep a notepad nearby while working",
                "When random thoughts pop up, write them down",
                "Don't act on them immediately",
                "Review the list during breaks"
            ],
            icon: "list.bullet"
        )
    ]
    
    var body: some View {
        List {
            ForEach(techniques) { technique in
                FocusTechniqueRow(technique: technique)
            }
        }
        .navigationTitle("Focus Techniques")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FocusTechnique: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let steps: [String]
    let icon: String
}

struct FocusTechniqueRow: View {
    let technique: FocusTechnique
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: technique.icon)
                    .foregroundColor(.purple)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(technique.name)
                        .font(.headline)
                    
                    Text(technique.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(technique.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.purple)
                                .clipShape(Circle())
                            
                            Text(step)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExportView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingShareSheet = false
    @State private var exportData = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Your Tasks")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Export your tasks as a text file to backup or share your progress.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Generate Export") {
                generateExport()
            }
            .buttonStyle(.borderedProminent)
            .disabled(taskManager.tasks.isEmpty && taskManager.completedTasks.isEmpty)
            
            if !exportData.isEmpty {
                Button("Share Export") {
                    showingShareSheet = true
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [exportData])
        }
    }
    
    private func generateExport() {
        var data = "ADHD Assistant - Task Export\n"
        data += "Generated: \(Date().formatted())\n\n"
        
        data += "PENDING TASKS (\(taskManager.tasks.count))\n"
        data += "=" * 50 + "\n"
        
        for task in taskManager.tasks {
            data += "• \(task.title)\n"
            if !task.description.isEmpty {
                data += "  \(task.description)\n"
            }
            data += "  Priority: \(task.priority.rawValue)\n"
            if let dueDate = task.dueDate {
                data += "  Due: \(dueDate.formatted())\n"
            }
            data += "\n"
        }
        
        data += "\nCOMPLETED TASKS (\(taskManager.completedTasks.count))\n"
        data += "=" * 50 + "\n"
        
        for task in taskManager.completedTasks {
            data += "✓ \(task.title)\n"
            if let completedAt = task.completedAt {
                data += "  Completed: \(completedAt.formatted())\n"
            }
            data += "\n"
        }
        
        exportData = data
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and name
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("ADHD Assistant")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This App")
                            .font(.headline)
                        
                        Text("ADHD Assistant is designed specifically for people with ADHD to help manage tasks, stay focused, and build productive habits. The app uses invasive notifications and app blocking to provide the accountability and structure that ADHD brains often need.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(
                                icon: "bell.fill",
                                title: "Invasive Notifications",
                                description: "Persistent reminders that adapt to your needs"
                            )
                            
                            FeatureRow(
                                icon: "shield.fill",
                                title: "App Blocking",
                                description: "Block distracting apps until tasks are completed"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Progress Tracking",
                                description: "Visual progress and achievement system"
                            )
                            
                            FeatureRow(
                                icon: "heart.fill",
                                title: "ADHD-Friendly Design",
                                description: "Built with ADHD challenges in mind"
                            )
                        }
                    }
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Credits")
                            .font(.headline)
                        
                        Text("This app was created with love and understanding for the ADHD community. Every feature is designed to work with your brain, not against it.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager())
        .environmentObject(AppBlockManager())
}