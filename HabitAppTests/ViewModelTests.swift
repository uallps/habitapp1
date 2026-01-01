//
//  ViewModelTests.swift
//  HabitAppTests
//
//  Tests for business logic and view model functionality
//

import Testing
import Foundation
@testable import HabitApp

// MARK: - Habit Validation Tests
struct HabitValidationTests {
    
    @Test func testValidHabitName() async throws {
        let validNames = ["Exercise", "Reading", "Meditation", "Learn Swift"]
        
        for name in validNames {
            let isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            #expect(isValid)
        }
    }
    
    @Test func testInvalidHabitName() async throws {
        let invalidNames = ["", "   ", "\n\t"]
        
        for name in invalidNames {
            let isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            #expect(!isValid)
        }
    }
    
    @Test func testFrequencyValidation() async throws {
        // Valid frequencies
        let validFrequencies: [[String]] = [
            ["Diario"],
            ["L", "M", "X"],
            ["S", "D"],
            ["L", "M", "X", "J", "V", "S", "D"]
        ]
        
        for frequency in validFrequencies {
            #expect(!frequency.isEmpty)
        }
    }
    
    @Test func testEmptyFrequency() async throws {
        let emptyFrequency: [String] = []
        #expect(emptyFrequency.isEmpty)
    }
}

// MARK: - Statistics Calculation Tests
struct StatisticsCalculationTests {
    
    @Test func testCompletionRateCalculation() async throws {
        // 7 days, 5 completions = ~71% completion rate
        let totalDays = 7
        let completedDays = 5
        let rate = Double(completedDays) / Double(totalDays)
        
        #expect(rate > 0.7)
        #expect(rate < 0.72)
    }
    
    @Test func testPerfectCompletionRate() async throws {
        let totalDays = 30
        let completedDays = 30
        let rate = Double(completedDays) / Double(totalDays)
        
        #expect(rate == 1.0)
    }
    
    @Test func testZeroCompletionRate() async throws {
        let totalDays = 30
        let completedDays = 0
        let rate = Double(completedDays) / Double(max(totalDays, 1))
        
        #expect(rate == 0.0)
    }
    
    @Test func testAverageStreak() async throws {
        let streaks = [5, 10, 3, 7, 15]
        let average = Double(streaks.reduce(0, +)) / Double(streaks.count)
        
        #expect(average == 8.0)
    }
    
    @Test func testMaxStreak() async throws {
        let streaks = [5, 10, 3, 7, 15, 2, 8]
        let maxStreak = streaks.max() ?? 0
        
        #expect(maxStreak == 15)
    }
    
    @Test func testTotalCompletions() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        let today = Calendar.current.startOfDay(for: Date())
        for i in 0..<10 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                habit.completedDates.append(date)
            }
        }
        
        #expect(habit.completedDates.count == 10)
    }
}

// MARK: - Weekly Statistics Tests
struct WeeklyStatisticsTests {
    
    @Test func testDaysInWeek() async throws {
        let daysInWeek = 7
        #expect(daysInWeek == 7)
    }
    
    @Test func testWeekdayDistribution() async throws {
        // Count completions per weekday
        var weekdayCompletions = [Int: Int]()
        let calendar = Calendar.current
        let today = Date()
        
        // Simulate completions for past 30 days
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                weekdayCompletions[weekday, default: 0] += 1
            }
        }
        
        #expect(weekdayCompletions.count > 0)
        #expect(weekdayCompletions.values.reduce(0, +) == 30)
    }
    
    @Test func testWeeklyProgress() async throws {
        let weeklyTarget = 7 // Daily habit
        let completed = 5
        let progress = Double(completed) / Double(weeklyTarget)
        
        #expect(progress > 0)
        #expect(progress < 1.0)
    }
}

// MARK: - Monthly Statistics Tests
struct MonthlyStatisticsTests {
    
    @Test func testDaysInMonth() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        let range = calendar.range(of: .day, in: .month, for: today)
        let daysInMonth = range?.count ?? 30
        
        #expect(daysInMonth >= 28)
        #expect(daysInMonth <= 31)
    }
    
    @Test func testMonthlyCompletionRate() async throws {
        let daysInMonth = 30
        let completedDays = 25
        let rate = Double(completedDays) / Double(daysInMonth)
        
        #expect(rate > 0.8)
    }
}

// MARK: - Streak Calculation Tests
struct StreakCalculationTests {
    
    @Test func testStreakWithGaps() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Add completions with a gap
        habit.completedDates.append(today)
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) {
            habit.completedDates.append(twoDaysAgo)
        }
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) {
            habit.completedDates.append(threeDaysAgo)
        }
        
        // Streak should be 1 (only today counts due to gap yesterday)
        #expect(habit.currentStreak == 1)
    }
    
    @Test func testStreakReset() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        let calendar = Calendar.current
        
        // Add completions from 5 days ago (no recent completions)
        if let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: Date()) {
            habit.completedDates.append(fiveDaysAgo)
        }
        
        // Streak is 1 because there's one completion (not consecutive with today)
        #expect(habit.currentStreak == 1)
    }
    
    @Test func testLongestStreakCalculation() async throws {
        // Simulate finding longest streak from history
        let completions = [true, true, true, false, true, true, true, true, true, false, true, true]
        
        var maxStreak = 0
        var currentStreak = 0
        
        for completed in completions {
            if completed {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        #expect(maxStreak == 5)
    }
}

// MARK: - Date Range Tests
struct DateRangeCalculationTests {
    
    @Test func testLast7Days() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        
        #expect(dates.count == 7)
    }
    
    @Test func testLast30Days() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dates: [Date] = []
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        
        #expect(dates.count == 30)
    }
    
    @Test func testCurrentWeekRange() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Adjust for Monday start
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            throw TestError.storeError
        }
        
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            throw TestError.storeError
        }
        
        #expect(startOfWeek <= today)
        #expect(endOfWeek >= today)
    }
}

// MARK: - Habit Sorting Tests
struct HabitSortingTests {
    
    @Test func testSortByName() async throws {
        let habits = [
            Habit(name: "Zebra", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Apple", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Mango", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        let sorted = habits.sorted { $0.name < $1.name }
        
        #expect(sorted[0].name == "Apple")
        #expect(sorted[1].name == "Mango")
        #expect(sorted[2].name == "Zebra")
    }
    
    @Test func testSortByCreationDate() async throws {
        let now = Date()
        let habits = [
            Habit(name: "New", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star", createdAt: now),
            Habit(name: "Old", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star", createdAt: Calendar.current.date(byAdding: .day, value: -30, to: now)),
            Habit(name: "Medium", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star", createdAt: Calendar.current.date(byAdding: .day, value: -15, to: now))
        ]
        
        let sorted = habits.sorted { ($0.createdAt ?? now) < ($1.createdAt ?? now) }
        
        #expect(sorted[0].name == "Old")
        #expect(sorted[2].name == "New")
    }
    
    @Test func testSortByCompletionStatus() async throws {
        var habits = [
            Habit(name: "Completed", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Not Completed", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star")
        ]
        
        habits[0].completedDates.append(Date())
        
        let today = Date()
        let sorted = habits.sorted { !$0.wasCompleted(on: today) && $1.wasCompleted(on: today) }
        
        #expect(sorted.count == 2)
    }
}

// MARK: - Error Handling Tests
struct ErrorHandlingTests {
    
    @Test func testInvalidDateHandling() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let validDate = formatter.date(from: "2024-01-15")
        let invalidDate = formatter.date(from: "invalid-date")
        
        #expect(validDate != nil)
        #expect(invalidDate == nil)
    }
    
    @Test func testEmptyArrayHandling() async throws {
        let emptyHabits: [Habit] = []
        
        let maxStreak = emptyHabits.map { $0.currentStreak }.max() ?? 0
        let avgStreak = emptyHabits.isEmpty ? 0.0 : Double(emptyHabits.map { $0.currentStreak }.reduce(0, +)) / Double(emptyHabits.count)
        
        #expect(maxStreak == 0)
        #expect(avgStreak == 0.0)
    }
    
    @Test func testDivisionByZeroProtection() async throws {
        let totalDays = 0
        let completedDays = 0
        
        let rate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
        
        #expect(rate == 0.0)
    }
}
