import SwiftUI

struct TaskDetailView: View {
    let task: Task
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTask = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(task.priority.emoji)
                                .font(.largeTitle)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(task.priority.rawValue + " Priority")
                                    .font(.subheadline)
                                    .foregroundColor(task.priority.color)
                            }
                            
                            Spacer()
                        }
                        
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Task details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Task Details")
                            .font(.headline)
                        
                        DetailRow(
                            icon: "calendar",
                            title: "Created",
                            value: task.createdAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        
                        if let dueDate = task.dueDate {
                            DetailRow(
                                icon: "clock",
                                title: "Due Date",
                                value: dueDate.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                        
                        DetailRow(
                            icon: "bell",
                            title: "Reminder Interval",
                            value: formatTimeInterval(task.reminderInterval)
                        )
                        
                        if let completedAt = task.completedAt {
                            DetailRow(
                                icon: "checkmark.circle.fill",
                                title: "Completed",
                                value: completedAt.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if !task.isCompleted {
                            Button(action: {
                                withAnimation(.spring()) {
                                    taskManager.completeTask(task)
                                    notificationManager.scheduleCompletionCelebration(for: task)
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Complete")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { showingEditTask = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Task")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            taskManager.deleteTask(task)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Task")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task)
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

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Task.TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var reminderInterval: TimeInterval = 300 // 5 minutes
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Information") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priority.emoji)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Reminders") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder interval: \(formatTimeInterval(reminderInterval))")
                            .font(.subheadline)
                        
                        Slider(value: $reminderInterval, in: 60...3600, step: 60) {
                            Text("Reminder interval")
                        }
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let newTask = Task(
            title: title,
            description: description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            reminderInterval: reminderInterval
        )
        
        taskManager.addTask(newTask)
        notificationManager.scheduleInvasiveReminders(for: newTask)
        dismiss()
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

struct EditTaskView: View {
    let task: Task
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: Task.TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var reminderInterval: TimeInterval
    
    init(task: Task) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._priority = State(initialValue: task.priority)
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._reminderInterval = State(initialValue: task.reminderInterval)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Information") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priority.emoji)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Reminders") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder interval: \(formatTimeInterval(reminderInterval))")
                            .font(.subheadline)
                        
                        Slider(value: $reminderInterval, in: 60...3600, step: 60) {
                            Text("Reminder interval")
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.priority = priority
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.reminderInterval = reminderInterval
        
        taskManager.updateTask(updatedTask)
        dismiss()
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

struct CompletedTasksView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if taskManager.completedTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("No completed tasks yet")
                            .font(.headline)
                        
                        Text("Complete some tasks to see them here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(taskManager.completedTasks.reversed()) { task in
                        CompletedTaskRow(task: task)
                    }
                }
            }
            .navigationTitle("Completed Tasks")
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

struct CompletedTaskRow: View {
    let task: Task
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough()
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
                
                if let completedAt = task.completedAt {
                    Text("Completed: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: {
                taskManager.restoreTask(task)
            }) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TaskDetailView(task: Task(
        title: "Sample Task",
        description: "This is a sample task description",
        priority: .high,
        dueDate: Date().addingTimeInterval(3600)
    ))
    .environmentObject(TaskManager())
    .environmentObject(NotificationManager())
}