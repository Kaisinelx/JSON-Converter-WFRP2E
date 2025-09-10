# ADHD Assistant - iOS App

A comprehensive iOS app designed specifically for people with ADHD to help manage tasks, stay focused, and build productive habits. The app uses invasive notifications and app blocking to provide the accountability and structure that ADHD brains often need.

## Features

### 🚨 Invasive Notification System
- **Persistent Reminders**: Customizable reminder intervals that won't let you forget
- **Adaptive Messages**: Different motivational messages for each reminder
- **Completion Celebrations**: Positive reinforcement when tasks are completed
- **Daily Motivation**: Morning motivational messages to start the day right

### 🛡️ App Blocking
- **Distraction Prevention**: Block Instagram, YouTube, and other distracting apps
- **Task-Based Blocking**: Apps remain blocked until all tasks are completed
- **Screen Time Integration**: Uses iOS Screen Time API for effective blocking
- **Customizable App Selection**: Choose which apps to block

### 📊 Progress Tracking
- **Visual Progress**: Completion rate charts and statistics
- **Achievement System**: Unlock badges for milestones
- **Weekly Progress**: Track your productivity over time
- **Task History**: View completed tasks and restore if needed

### 🎯 ADHD-Friendly Design
- **Priority System**: Color-coded task priorities (Low, Medium, High, Urgent)
- **Simple Interface**: Clean, distraction-free design
- **Quick Actions**: Easy task creation and completion
- **Focus Techniques**: Built-in ADHD focus strategies and tips

### ⚙️ Customization
- **Reminder Intervals**: Adjust how often you get reminded (1 minute to 1 hour)
- **Max Reminders**: Set maximum reminders per task (1-20)
- **App Selection**: Choose which apps to block
- **Accessibility Options**: High contrast, large text, and motion reduction

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Apple Developer Account (for device testing)

### Installation

1. **Clone or Download the Project**
   ```bash
   # If using git
   git clone <repository-url>
   cd ADHDAssistant
   ```

2. **Open in Xcode**
   - Open `ADHDAssistant.xcodeproj` in Xcode
   - Select your development team in project settings
   - Update the bundle identifier if needed

3. **Configure Permissions**
   - The app requires notification permissions for reminders
   - Screen Time permissions are needed for app blocking
   - These will be requested when the app first launches

4. **Build and Run**
   - Select your target device or simulator
   - Press Cmd+R to build and run

### Required Permissions

The app requires the following permissions to function properly:

1. **Notifications** (`NSUserNotificationsUsageDescription`)
   - Used for task reminders and completion celebrations
   - Can be granted through the app's settings

2. **Screen Time** (`NSScreenTimeUsageDescription`)
   - Required for app blocking functionality
   - Must be granted in iOS Settings > Screen Time > App Limits

## Usage Guide

### Getting Started

1. **First Launch**
   - Grant notification permissions when prompted
   - Grant Screen Time permissions in iOS Settings
   - The app will guide you through initial setup

2. **Adding Tasks**
   - Tap the "+" button on the Tasks tab
   - Fill in task details (title, description, priority)
   - Set due date and reminder interval
   - Save the task

3. **Managing Tasks**
   - View all pending tasks on the main screen
   - Tap the checkmark to complete a task
   - Tap "Details" to edit or view task information
   - View completed tasks in the progress tab

4. **Focus Mode**
   - Enable Focus Mode to block distracting apps
   - Select which apps to block in Settings
   - Apps will be blocked until all tasks are completed

### Tips for ADHD Users

1. **Start Small**: Begin with 1-2 tasks and gradually increase
2. **Use Priorities**: Mark urgent tasks as high priority
3. **Set Short Reminders**: Use 5-10 minute reminder intervals initially
4. **Enable Invasive Mode**: Let the app be persistent with reminders
5. **Block Distractions**: Enable app blocking for maximum focus

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **UserNotifications**: Local notification system
- **FamilyControls**: Screen Time integration for app blocking
- **UserDefaults**: Local data persistence

### Key Components

- **TaskManager**: Handles task CRUD operations and persistence
- **NotificationManager**: Manages invasive reminders and notifications
- **AppBlockManager**: Controls app blocking functionality
- **ContentView**: Main app interface with tab navigation
- **TaskView**: Task creation, editing, and detail views
- **SettingsView**: App configuration and customization

### Data Storage
- Tasks are stored locally using UserDefaults
- No cloud sync (privacy-focused)
- Export functionality for data backup

## Customization

### Adding New Distracting Apps
Edit the `distractingApps` dictionary in `AppBlockManager.swift`:

```swift
let distractingApps = [
    "com.burbn.instagram": "Instagram",
    "com.google.ios.youtube": "YouTube",
    // Add your app here
    "com.your.app": "Your App Name"
]
```

### Modifying Reminder Messages
Edit the `getInvasiveMessage` function in `NotificationManager.swift` to customize reminder messages.

### Changing App Colors
Update the accent color in the project settings or modify the color scheme in the SwiftUI views.

## Privacy & Security

- **No Data Collection**: All data stays on your device
- **No Analytics**: No tracking or analytics are included
- **Local Storage Only**: Tasks are stored locally using UserDefaults
- **No Network Requests**: App works completely offline

## Troubleshooting

### Common Issues

1. **Notifications Not Working**
   - Check notification permissions in iOS Settings
   - Ensure "Do Not Disturb" is not enabled
   - Verify the app has notification access

2. **App Blocking Not Working**
   - Grant Screen Time permissions in iOS Settings
   - Go to Settings > Screen Time > App Limits
   - Ensure the app is authorized to manage app limits

3. **Tasks Not Saving**
   - Check available storage space
   - Restart the app
   - Check UserDefaults permissions

### Support

For issues or questions:
1. Check the troubleshooting section above
2. Review iOS Settings for permission issues
3. Ensure you're running iOS 17.0 or later

## Future Enhancements

Potential features for future versions:
- Cloud sync for task backup
- Widget support for quick task access
- Apple Watch companion app
- Integration with calendar apps
- Voice-to-text task creation
- Custom notification sounds
- Task templates and recurring tasks

## License

This project is created for educational and personal use. Please respect Apple's guidelines and terms of service when using Screen Time APIs.

## Acknowledgments

This app is designed with love and understanding for the ADHD community. Every feature is crafted to work with ADHD brains, not against them. Special thanks to the ADHD community for their insights and feedback.

---

**Note**: This app is designed to be supportive and helpful. If you find any features too overwhelming, you can adjust the settings or disable invasive mode. The goal is to provide structure and accountability while respecting your needs and boundaries.