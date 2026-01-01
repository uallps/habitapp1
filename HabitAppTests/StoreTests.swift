//
//  StoreTests.swift
//  HabitAppTests
//
//  Tests for HabitStore and CompletionStore
//

import Testing
import Foundation
@testable import HabitApp

// MARK: - HabitStore Tests
struct HabitStoreTests {
    
    @MainActor
    @Test func testHabitStoreInitialization() async throws {
        let store = HabitStore.shared
        #expect(store.habits.count >= 0)
    }
    
    @MainActor
    @Test func testAddHabit() async throws {
        let store = HabitStore.shared
        let initialCount = store.habits.count
        
        let habit = Habit(
            name: "Test Store Habit \(UUID().uuidString.prefix(8))",
            description: "Test",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star.fill"
        )
        
        store.addHabit(habit)
        
        #expect(store.habits.count == initialCount + 1)
        #expect(store.habits.contains(where: { $0.id == habit.id }))
        
        // Clean up
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
    }
    
    @MainActor
    @Test func testRemoveHabit() async throws {
        let store = HabitStore.shared
        let initialCount = store.habits.count
        
        let habit = Habit(
            name: "To Be Removed \(UUID().uuidString.prefix(8))",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "trash"
        )
        
        store.addHabit(habit)
        #expect(store.habits.count == initialCount + 1)
        
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
        
        #expect(store.habits.count == initialCount)
        #expect(!store.habits.contains(where: { $0.id == habit.id }))
    }
    
    @MainActor
    @Test func testToggleCompletion() async throws {
        let store = HabitStore.shared
        
        let habit = Habit(
            name: "Toggle Test \(UUID().uuidString.prefix(8))",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "checkmark"
        )
        
        store.addHabit(habit)
        
        // Should not be completed initially
        guard let h = store.habits.first(where: { $0.id == habit.id }) else {
            throw TestError.habitNotFound
        }
        #expect(!store.isCompletedToday(h))
        
        // Toggle completion
        store.toggleHabitCompletion(h)
        
        guard let h2 = store.habits.first(where: { $0.id == habit.id }) else {
            throw TestError.habitNotFound
        }
        #expect(store.isCompletedToday(h2))
        
        // Toggle again to uncomplete
        store.toggleHabitCompletion(h2)
        
        guard let h3 = store.habits.first(where: { $0.id == habit.id }) else {
            throw TestError.habitNotFound
        }
        #expect(!store.isCompletedToday(h3))
        
        // Clean up
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
    }
    
    @MainActor
    @Test func testHabitNotes() async throws {
        let store = HabitStore.shared
        
        let habit = Habit(
            name: "Notes Test \(UUID().uuidString.prefix(8))",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "note"
        )
        
        store.addHabit(habit)
        
        store.setNote("Test note for today", for: habit, on: Date())
        
        let note = store.note(for: habit, on: Date())
        #expect(note == "Test note for today")
        
        // Clean up
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
    }
}

// MARK: - CompletionStore Tests
struct CompletionStoreTests {
    
    @MainActor
    @Test func testCompletionStoreInitialization() async throws {
        let store = CompletionStore.shared
        #expect(store.completions.count >= 0)
    }
    
    @MainActor
    @Test func testAddCompletion() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        
        let completion = HabitCompletion(
            habitId: habitId,
            date: Date(),
            note: "Test completion"
        )
        
        store.addCompletion(completion)
        
        #expect(store.completions.contains(where: { $0.habitId == habitId }))
        
        // Clean up
        store.removeCompletion(for: habitId, on: Date())
    }
    
    @MainActor
    @Test func testGetCompletionsForHabit() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        let calendar = Calendar.current
        let today = Date()
        
        // Add multiple completions
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let completion = HabitCompletion(
                habitId: habitId,
                date: date,
                note: "Day \(i)"
            )
            store.addCompletion(completion)
        }
        
        let habitCompletions = store.getCompletions(for: habitId)
        #expect(habitCompletions.count >= 5)
        
        // Clean up
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                store.removeCompletion(for: habitId, on: date)
            }
        }
    }
    
    @MainActor
    @Test func testCompletionWithMedia() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        
        var completion = HabitCompletion(
            habitId: habitId,
            date: Date()
        )
        completion.imagePath = "/test/image.jpg"
        completion.mediaType = .image
        
        store.addCompletion(completion)
        
        let saved = store.getCompletion(for: habitId, on: Date())
        #expect(saved?.imagePath == "/test/image.jpg")
        #expect(saved?.mediaType == .image)
        
        // Clean up
        store.removeCompletion(for: habitId, on: Date())
    }
    
    @MainActor
    @Test func testMediaCounting() async throws {
        let store = CompletionStore.shared
        let habitId = UUID()
        let calendar = Calendar.current
        let today = Date()
        
        // Add image completions
        for i in 0..<3 {
            var completion = HabitCompletion(
                habitId: habitId,
                date: calendar.date(byAdding: .day, value: -i, to: today)!
            )
            completion.imagePath = "/test/image\(i).jpg"
            completion.mediaType = .image
            store.addCompletion(completion)
        }
        
        // Add 3D model completions
        for i in 0..<2 {
            var completion = HabitCompletion(
                habitId: habitId,
                date: calendar.date(byAdding: .day, value: -(i + 10), to: today)!
            )
            completion.model3DPath = "/test/model\(i).usdz"
            completion.mediaType = .model3D
            store.addCompletion(completion)
        }
        
        let habitCompletions = store.getCompletions(for: habitId)
        let imageCount = habitCompletions.filter { $0.mediaType == .image }.count
        let modelCount = habitCompletions.filter { $0.mediaType == .model3D }.count
        
        #expect(imageCount >= 3)
        #expect(modelCount >= 2)
        
        // Clean up
        for i in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                store.removeCompletion(for: habitId, on: date)
            }
        }
        for i in 0..<2 {
            if let date = calendar.date(byAdding: .day, value: -(i + 10), to: today) {
                store.removeCompletion(for: habitId, on: date)
            }
        }
    }
}

// MARK: - Error Types
enum TestError: Error {
    case habitNotFound
    case storeError
}

// MARK: - Date Range Tests
struct DateRangeTests {
    
    @Test func testWeeklyCompletions() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get start of current week
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // Sunday = 1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            throw TestError.storeError
        }
        
        #expect(startOfWeek <= today)
        
        // End of week
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            throw TestError.storeError
        }
        
        #expect(endOfWeek >= startOfWeek)
    }
    
    @Test func testMonthlyCompletions() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of current month
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let startOfMonth = calendar.date(from: components) else {
            throw TestError.storeError
        }
        
        // Get end of current month
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            throw TestError.storeError
        }
        
        #expect(startOfMonth <= today)
        #expect(endOfMonth >= startOfMonth)
    }
}

// MARK: - Habit Filtering Tests
struct HabitFilteringTests {
    
    @Test func testFilterByFrequency() async throws {
        let habits = [
            Habit(name: "Daily", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Monday", description: "", frequency: ["L"], reminderTime: nil, iconName: "star"),
            Habit(name: "Weekend", description: "", frequency: ["S", "D"], reminderTime: nil, iconName: "star")
        ]
        
        let dailyHabits = habits.filter { $0.frequency.contains("Diario") }
        #expect(dailyHabits.count == 1)
        
        let weekendHabits = habits.filter { 
            $0.frequency.contains("S") || $0.frequency.contains("D")
        }
        #expect(weekendHabits.count == 1)
    }
    
    @Test func testFilterByCompletion() async throws {
        var habits = [
            Habit(name: "Completed", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Not Completed", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        habits[0].completedDates.append(Date())
        
        let completedToday = habits.filter { $0.wasCompleted(on: Date()) }
        let notCompletedToday = habits.filter { !$0.wasCompleted(on: Date()) }
        
        #expect(completedToday.count == 1)
        #expect(notCompletedToday.count == 1)
    }
    
    @Test func testSortByStreak() async throws {
        var habits = [
            Habit(name: "No Streak", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Long Streak", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Short Streak", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Add streak for "Long Streak"
        for i in 0..<10 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                habits[1].completedDates.append(date)
            }
        }
        
        // Add streak for "Short Streak"
        for i in 0..<3 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                habits[2].completedDates.append(date)
            }
        }
        
        let sorted = habits.sorted { $0.currentStreak > $1.currentStreak }
        
        #expect(sorted[0].name == "Long Streak")
        #expect(sorted[1].name == "Short Streak")
        #expect(sorted[2].name == "No Streak")
    }
}

// MARK: - Notification Tests
struct NotificationTests {
    
    @Test func testHabitWithReminder() async throws {
        let reminderTime = Date()
        let habit = Habit(
            name: "With Reminder",
            description: "",
            frequency: ["Diario"],
            reminderTime: reminderTime,
            iconName: "bell"
        )
        
        #expect(habit.reminderTime != nil)
    }
    
    @Test func testHabitWithoutReminder() async throws {
        let habit = Habit(
            name: "No Reminder",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "bell.slash"
        )
        
        #expect(habit.reminderTime == nil)
    }
}

// MARK: - Search Tests
struct SearchTests {
    
    @Test func testSearchByName() async throws {
        let habits = [
            Habit(name: "Morning Exercise", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Evening Reading", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Daily Meditation", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        let query = "morning"
        let results = habits.filter { $0.name.lowercased().contains(query.lowercased()) }
        
        #expect(results.count == 1)
        #expect(results[0].name == "Morning Exercise")
    }
    
    @Test func testSearchByDescription() async throws {
        let habits = [
            Habit(name: "Exercise", description: "30 minutes cardio", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Reading", description: "Read 20 pages", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Meditation", description: "10 minutes mindfulness", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        let query = "minutes"
        let results = habits.filter { $0.description.lowercased().contains(query.lowercased()) }
        
        #expect(results.count == 2)
    }
    
    @Test func testEmptySearch() async throws {
        let habits = [
            Habit(name: "Test", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        let query = ""
        let results = query.isEmpty ? habits : habits.filter { $0.name.contains(query) }
        
        #expect(results.count == habits.count)
    }
}
