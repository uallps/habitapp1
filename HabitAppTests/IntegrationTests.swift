//
//  IntegrationTests.swift
//  HabitAppTests
//
//  Integration tests for complete workflows
//

import Testing
import Foundation
@testable import HabitApp

// MARK: - Complete Workflow Tests
struct WorkflowTests {
    
    @MainActor
    @Test func testCompleteHabitCreationWorkflow() async throws {
        let store = HabitStore.shared
        let initialCount = store.habits.count
        
        // 1. Create habit
        let habit = Habit(
            name: "Integration Test Habit \(UUID().uuidString.prefix(8))",
            description: "Testing complete workflow",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star.fill"
        )
        
        // 2. Add to store
        store.addHabit(habit)
        
        // 3. Verify it was added
        let found = store.habits.first(where: { $0.id == habit.id })
        #expect(found != nil)
        #expect(found?.name == habit.name)
        
        // 4. Complete the habit
        if let foundHabit = found {
            store.toggleHabitCompletion(foundHabit)
        }
        
        // 5. Verify completion
        let updated = store.habits.first(where: { $0.id == habit.id })
        #expect(updated != nil)
        #expect(store.isCompletedToday(updated!))
        
        // 6. Check streak
        #expect(updated?.currentStreak == 1)
        
        // 7. Clean up
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
        #expect(store.habits.count == initialCount)
    }
    
    @MainActor
    @Test func testHabitLifecycle() async throws {
        let store = HabitStore.shared
        let initialCount = store.habits.count
        
        // Create
        let habit = Habit(
            name: "Lifecycle Test \(UUID().uuidString.prefix(8))",
            description: "",
            frequency: ["L", "M", "X", "J", "V"],
            reminderTime: nil,
            iconName: "figure.walk"
        )
        store.addHabit(habit)
        
        // Verify added
        #expect(store.habits.count == initialCount + 1)
        
        // Add note
        store.setNote("Test note", for: habit, on: Date())
        
        let withNotes = store.habits.first(where: { $0.id == habit.id })
        let note = store.note(for: withNotes!, on: Date())
        #expect(note == "Test note")
        
        // Delete
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
        let deleted = store.habits.first(where: { $0.id == habit.id })
        #expect(deleted == nil)
        #expect(store.habits.count == initialCount)
    }
    
    @MainActor
    @Test func testMultipleHabitsWorkflow() async throws {
        let store = HabitStore.shared
        let initialCount = store.habits.count
        
        // Add 3 habits
        var addedHabits: [Habit] = []
        for i in 0..<3 {
            let habit = Habit(
                name: "Multi Habit \(i) - \(UUID().uuidString.prefix(8))",
                description: "",
                frequency: ["Diario"],
                reminderTime: nil,
                iconName: "star"
            )
            store.addHabit(habit)
            addedHabits.append(habit)
        }
        
        #expect(store.habits.count == initialCount + 3)
        
        // Complete some
        if let h0 = store.habits.first(where: { $0.id == addedHabits[0].id }) {
            store.toggleHabitCompletion(h0)
        }
        if let h2 = store.habits.first(where: { $0.id == addedHabits[2].id }) {
            store.toggleHabitCompletion(h2)
        }
        
        // Verify completions
        let h0Updated = store.habits.first(where: { $0.id == addedHabits[0].id })
        let h2Updated = store.habits.first(where: { $0.id == addedHabits[2].id })
        #expect(h0Updated != nil && store.isCompletedToday(h0Updated!))
        #expect(h2Updated != nil && store.isCompletedToday(h2Updated!))
        
        // Remove all added habits
        for habit in addedHabits {
            if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
                store.removeHabit(at: IndexSet(integer: index))
            }
        }
        
        #expect(store.habits.count == initialCount)
    }
}

// MARK: - Data Persistence Tests
struct DataPersistenceTests {
    
    @MainActor
    @Test func testHabitPersistence() async throws {
        let store = HabitStore.shared
        let testId = UUID()
        let habit = Habit(
            id: testId,
            name: "Persistence Test \(UUID().uuidString.prefix(8))",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        store.addHabit(habit)
        
        // Verify it exists
        let found = store.habits.first(where: { $0.id == testId })
        #expect(found != nil)
        #expect(found?.name.contains("Persistence Test") == true)
        
        // Clean up
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
    }
    
    @MainActor
    @Test func testCompletionPersistence() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        
        let completion = HabitCompletion(
            habitId: habitId,
            date: Date(),
            note: "Persistence test note"
        )
        store.addCompletion(completion)
        
        // Verify it exists
        let found = store.getCompletion(for: habitId, on: Date())
        #expect(found != nil)
        #expect(found?.note == "Persistence test note")
        
        // Clean up
        store.removeCompletion(for: habitId, on: Date())
    }
}

// MARK: - Recap Workflow Tests
struct RecapWorkflowTests {
    
    @MainActor
    @Test func testDailyRecapData() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        let today = Date()
        
        // Add completion with media
        var completion = HabitCompletion(
            habitId: habitId,
            date: today,
            note: "Daily recap test"
        )
        completion.imagePath = "/test/image.jpg"
        completion.mediaType = .image
        
        store.addCompletion(completion)
        
        // Get today's completions for this habit
        let todayCompletions = store.getCompletions(for: today).filter { $0.habitId == habitId }
        
        #expect(todayCompletions.count >= 1)
        
        // Count media
        let withMedia = todayCompletions.filter { $0.hasMedia }
        #expect(withMedia.count >= 1)
        
        // Clean up
        store.removeCompletion(for: habitId, on: today)
    }
    
    @MainActor
    @Test func testWeeklyRecapData() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        let calendar = Calendar.current
        let today = Date()
        
        // Add completions for past week
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let completion = HabitCompletion(
                    habitId: habitId,
                    date: date,
                    note: "Day \(i)"
                )
                store.addCompletion(completion)
            }
        }
        
        // Get week's completions
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let weekCompletions = store.getCompletionsInRange(from: weekAgo, to: today).filter { $0.habitId == habitId }
        
        #expect(weekCompletions.count >= 7)
        
        // Clean up
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                store.removeCompletion(for: habitId, on: date)
            }
        }
    }
    
    @MainActor
    @Test func testMonthlyRecapData() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        let calendar = Calendar.current
        let today = Date()
        
        // Add completions for past 10 days (reduced for test speed)
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let completion = HabitCompletion(
                    habitId: habitId,
                    date: date,
                    note: "Day \(i)"
                )
                store.addCompletion(completion)
            }
        }
        
        // Get completions
        let pastCompletions = store.getCompletions(for: habitId)
        #expect(pastCompletions.count >= 10)
        
        // Clean up
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                store.removeCompletion(for: habitId, on: date)
            }
        }
    }
}

// MARK: - Media Management Tests
struct MediaManagementTests {
    
    @Test func testImagePathGeneration() async throws {
        let habitId = UUID()
        let date = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = formatter.string(from: date)
        
        let imagePath = "media/\(habitId.uuidString)/\(dateString).jpg"
        
        #expect(imagePath.contains(habitId.uuidString))
        #expect(imagePath.hasSuffix(".jpg"))
    }
    
    @Test func testModel3DPathGeneration() async throws {
        let habitId = UUID()
        let date = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let dateString = formatter.string(from: date)
        
        let modelPath = "media/\(habitId.uuidString)/\(dateString).usdz"
        
        #expect(modelPath.contains(habitId.uuidString))
        #expect(modelPath.hasSuffix(".usdz"))
    }
    
    @Test func testMediaTypeDetection() async throws {
        let imageExtensions = ["jpg", "jpeg", "png", "heic"]
        let modelExtensions = ["usdz", "reality"]
        
        for ext in imageExtensions {
            let path = "test/image.\(ext)"
            let isImage = imageExtensions.contains(where: { path.hasSuffix($0) })
            #expect(isImage)
        }
        
        for ext in modelExtensions {
            let path = "test/model.\(ext)"
            let isModel = modelExtensions.contains(where: { path.hasSuffix($0) })
            #expect(isModel)
        }
    }
}

// MARK: - Notification Workflow Tests
struct NotificationWorkflowTests {
    
    @Test func testReminderTimeExtraction() async throws {
        let calendar = Calendar.current
        let reminderTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!
        
        let habit = Habit(
            name: "Morning Habit",
            description: "",
            frequency: ["Diario"],
            reminderTime: reminderTime,
            iconName: "bell"
        )
        
        #expect(habit.reminderTime != nil)
        
        let components = calendar.dateComponents([.hour, .minute], from: habit.reminderTime!)
        #expect(components.hour == 9)
        #expect(components.minute == 30)
    }
    
    @Test func testWeekdayNotificationSchedule() async throws {
        let habit = Habit(
            name: "Weekday Only",
            description: "",
            frequency: ["L", "M", "X", "J", "V"],
            reminderTime: Date(),
            iconName: "bell"
        )
        
        // Should schedule for 5 days
        #expect(habit.frequency.count == 5)
        #expect(!habit.frequency.contains("S"))
        #expect(!habit.frequency.contains("D"))
    }
}

// MARK: - Edge Case Tests
struct EdgeCaseTests {
    
    @Test func testMidnightBoundary() async throws {
        let calendar = Calendar.current
        
        // Just before midnight
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        let justBeforeMidnight = calendar.date(from: components)!
        let dayBefore = calendar.startOfDay(for: justBeforeMidnight)
        
        #expect(calendar.isDate(justBeforeMidnight, inSameDayAs: dayBefore))
    }
    
    @Test func testYearBoundary() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dec31 = formatter.date(from: "2024-12-31")!
        let jan1 = formatter.date(from: "2025-01-01")!
        
        #expect(!Calendar.current.isDate(dec31, inSameDayAs: jan1))
    }
    
    @Test func testLeapYear() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 2024 is a leap year
        let feb29 = formatter.date(from: "2024-02-29")
        #expect(feb29 != nil)
        
        // 2023 is not a leap year
        let invalidFeb29 = formatter.date(from: "2023-02-29")
        #expect(invalidFeb29 == nil)
    }
    
    @Test func testTimezoneHandling() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of day in current timezone
        let startOfDay = calendar.startOfDay(for: now)
        
        // Should be at midnight
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test func testVeryOldDate() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let oldDate = formatter.date(from: "2000-01-01")
        #expect(oldDate != nil)
        #expect(oldDate! < Date())
    }
    
    @Test func testFutureDate() async throws {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .year, value: 10, to: Date())!
        
        #expect(futureDate > Date())
    }
}
