import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var appBlockManager: AppBlockManager
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tasks Tab
            TaskListView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks")
                }
                .tag(0)
            
            // Progress Tab
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Progress")
                }
                .tag(1)
            
            // Focus Tab
            FocusView()
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("Focus")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.purple)
        .onAppear {
            // Update app blocking based on current tasks
            appBlockManager.updateBlockingBasedOnTasks(taskManager.tasks)
        }
        .onChange(of: taskManager.tasks) { tasks in
            // Update blocking when tasks change
            appBlockManager.updateBlockingBasedOnTasks(tasks)
        }
    }
}

struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAddTask = false
    @State private var showingCompletedTasks = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                HeaderStatsView()
                    .padding()
                    .background(Color.purple.opacity(0.1))
                
                // Quick actions
                QuickActionsView(showingAddTask: $showingAddTask)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Task list
                if taskManager.pendingTasks.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskManager.pendingTasks) { task in
                                TaskRowView(task: task)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCompletedTasks = true }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .sheet(isPresented: $showingCompletedTasks) {
            CompletedTasksView()
        }
    }
}

struct HeaderStatsView: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Pending",
                value: "\(taskManager.pendingTasks.count)",
                color: .orange,
                icon: "clock.fill"
            )
            
            StatCard(
                title: "Completed",
                value: "\(taskManager.completedTasksCount)",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            
            StatCard(
                title: "Urgent",
                value: "\(taskManager.urgentTasks.count)",
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickActionsView: View {
    @Binding var showingAddTask: Bool
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingAddTask = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .cornerRadius(20)
            }
            
            if !taskManager.urgentTasks.isEmpty {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Urgent: \(taskManager.urgentTasks.count)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
            
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All caught up!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You have no pending tasks. Great job! 🎉")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TaskRowView: View {
    let task: Task
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Priority indicator
                Text(task.priority.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Complete button
                Button(action: {
                    withAnimation(.spring()) {
                        taskManager.completeTask(task)
                        notificationManager.scheduleCompletionCelebration(for: task)
                    }
                }) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Task metadata
            HStack {
                Text(task.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.priority.color.opacity(0.2))
                    .foregroundColor(task.priority.color)
                    .cornerRadius(8)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Details") {
                    showingDetail = true
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }
}

struct ProgressView: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Completion rate chart
                    CompletionRateChart()
                        .padding()
                    
                    // Weekly progress
                    WeeklyProgressView()
                        .padding()
                    
                    // Achievement badges
                    AchievementView()
                        .padding()
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct CompletionRateChart: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(taskManager.completionRate * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: taskManager.completionRate)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: taskManager.completionRate)
                    
                    Text("\(Int(taskManager.completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct WeeklyProgressView: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        Text(["M", "T", "W", "T", "F", "S", "S"][day])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day < 5 ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 30, height: CGFloat.random(in: 20...60))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AchievementView: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                AchievementBadge(
                    title: "First Task",
                    icon: "star.fill",
                    isUnlocked: taskManager.completedTasksCount > 0,
                    color: .yellow
                )
                
                AchievementBadge(
                    title: "Task Master",
                    icon: "crown.fill",
                    isUnlocked: taskManager.completedTasksCount >= 10,
                    color: .purple
                )
                
                AchievementBadge(
                    title: "Focus Hero",
                    icon: "shield.fill",
                    isUnlocked: taskManager.completionRate >= 0.8,
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isUnlocked ? color.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

struct FocusView: View {
    @EnvironmentObject var appBlockManager: AppBlockManager
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Focus mode status
                    FocusStatusCard()
                        .padding()
                    
                    // Blocked apps
                    BlockedAppsView()
                        .padding()
                    
                    // Focus tips
                    FocusTipsView()
                        .padding()
                }
            }
            .navigationTitle("Focus Mode")
        }
    }
}

struct FocusStatusCard: View {
    @EnvironmentObject var appBlockManager: AppBlockManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: appBlockManager.isBlockingActive ? "shield.fill" : "shield")
                    .font(.title)
                    .foregroundColor(appBlockManager.isBlockingActive ? .green : .gray)
                
                VStack(alignment: .leading) {
                    Text(appBlockManager.isBlockingActive ? "Focus Mode Active" : "Focus Mode Inactive")
                        .font(.headline)
                    
                    Text(appBlockManager.isBlockingActive ? "Distracting apps are blocked" : "All apps are accessible")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: {
                appBlockManager.toggleAppBlocking()
            }) {
                Text(appBlockManager.isBlockingActive ? "Disable Focus Mode" : "Enable Focus Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appBlockManager.isBlockingActive ? Color.red : Color.purple)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct BlockedAppsView: View {
    @EnvironmentObject var appBlockManager: AppBlockManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blocked Apps")
                .font(.headline)
            
            if appBlockManager.blockedApps.isEmpty {
                Text("No apps are currently blocked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(Array(appBlockManager.blockedApps), id: \.self) { bundleId in
                        VStack(spacing: 4) {
                            Text(appBlockManager.getAppIcon(for: bundleId))
                                .font(.title2)
                            
                            Text(appBlockManager.getAppName(for: bundleId))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct FocusTipsView: View {
    let tips = [
        "Break large tasks into smaller 5-minute chunks",
        "Use the Pomodoro Technique: 25 min work, 5 min break",
        "Remove distractions from your workspace",
        "Set specific times for checking social media",
        "Use body doubling - work alongside someone else",
        "Create a 'distraction list' for random thoughts"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADHD Focus Tips")
                .font(.headline)
            
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.purple)
                        .clipShape(Circle())
                    
                    Text(tip)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskManager())
        .environmentObject(NotificationManager())
        .environmentObject(AppBlockManager())
}