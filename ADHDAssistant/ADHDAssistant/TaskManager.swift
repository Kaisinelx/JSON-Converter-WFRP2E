import Foundation
import SwiftUI

// MARK: - Task Model
struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool = false
    var priority: TaskPriority
    var dueDate: Date?
    var reminderInterval: TimeInterval = 300 // 5 minutes default
    var createdAt: Date = Date()
    var completedAt: Date?
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .urgent: return .red
            }
        }
        
        var emoji: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .urgent: return "🔴"
            }
        }
    }
}

// MARK: - Task Manager
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedTasks: [Task] = []
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "saved_tasks"
    private let completedTasksKey = "completed_tasks"
    
    init() {
        loadTasks()
    }
    
    // MARK: - Task Management
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func completeTask(_ task: Task) {
        var completedTask = task
        completedTask.isCompleted = true
        completedTask.completedAt = Date()
        
        tasks.removeAll { $0.id == task.id }
        completedTasks.append(completedTask)
        
        saveTasks()
        saveCompletedTasks()
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func restoreTask(_ task: Task) {
        var restoredTask = task
        restoredTask.isCompleted = false
        restoredTask.completedAt = nil
        
        completedTasks.removeAll { $0.id == task.id }
        tasks.append(restoredTask)
        
        saveTasks()
        saveCompletedTasks()
    }
    
    // MARK: - Data Persistence
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    private func saveCompletedTasks() {
        if let encoded = try? JSONEncoder().encode(completedTasks) {
            userDefaults.set(encoded, forKey: completedTasksKey)
        }
    }
    
    private func loadCompletedTasks() {
        if let data = userDefaults.data(forKey: completedTasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            completedTasks = decoded
        }
    }
    
    // MARK: - Statistics
    var totalTasks: Int {
        tasks.count + completedTasks.count
    }
    
    var completedTasksCount: Int {
        completedTasks.count
    }
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasks)
    }
    
    var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    var overdueTasks: [Task] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && !task.isCompleted
        }
    }
    
    var urgentTasks: [Task] {
        tasks.filter { $0.priority == .urgent && !$0.isCompleted }
    }
}