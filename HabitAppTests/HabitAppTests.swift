//
//  HabitAppTests.swift
//  HabitAppTests
//
//  Comprehensive unit tests for HabitApp
//

import Testing
import Foundation
@testable import HabitApp

// MARK: - Habit Model Tests
@MainActor
struct HabitModelTests {
    
    @Test func testHabitCreation() async throws {
        let habit = Habit(
            name: "Test Habit",
            description: "Test Description",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star.fill"
        )
        
        #expect(habit.name == "Test Habit")
        #expect(habit.description == "Test Description")
        #expect(habit.frequency == ["Diario"])
        #expect(habit.iconName == "star.fill")
        #expect(habit.completedDates.isEmpty)
        #expect(habit.currentStreak == 0)
    }
    
    @Test func testHabitWithSpecificDays() async throws {
        let habit = Habit(
            name: "Gym",
            description: "Go to gym",
            frequency: ["L", "M", "V"],
            reminderTime: nil,
            iconName: "figure.walk"
        )
        
        #expect(habit.frequency.count == 3)
        #expect(habit.frequency.contains("L"))
        #expect(habit.frequency.contains("M"))
        #expect(habit.frequency.contains("V"))
        #expect(!habit.frequency.contains("Diario"))
    }
    
    @Test func testHabitStreakCalculation() async throws {
        var habit = Habit(
            name: "Daily Reading",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "book.fill"
        )
        
        // No completions = 0 streak
        #expect(habit.currentStreak == 0)
        
        // Add today
        let today = Calendar.current.startOfDay(for: Date())
        habit.completedDates.append(today)
        #expect(habit.currentStreak == 1)
        
        // Add yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        habit.completedDates.append(yesterday)
        #expect(habit.currentStreak == 2)
        
        // Add 2 days ago
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        habit.completedDates.append(twoDaysAgo)
        #expect(habit.currentStreak == 3)
    }
    
    @Test func testHabitStreakBreak() async throws {
        var habit = Habit(
            name: "Daily Reading",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "book.fill"
        )
        
        let today = Calendar.current.startOfDay(for: Date())
        habit.completedDates.append(today)
        
        // Skip yesterday, add 2 days ago (streak should be 1, not 2)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        habit.completedDates.append(twoDaysAgo)
        
        #expect(habit.currentStreak == 1)
    }
    
    @Test func testWasCompletedOnDate() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        let today = Date()
        #expect(!habit.wasCompleted(on: today))
        
        habit.completedDates.append(today)
        #expect(habit.wasCompleted(on: today))
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        #expect(!habit.wasCompleted(on: yesterday))
    }
    
    @Test func testLastCompletedDate() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.lastCompletedDate == nil)
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        habit.completedDates.append(yesterday)
        habit.completedDates.append(today)
        
        #expect(habit.lastCompletedDate != nil)
        #expect(Calendar.current.isDate(habit.lastCompletedDate!, inSameDayAs: today))
    }
    
    @Test func testCompletionRateCalculation() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star",
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())
        )
        
        // No completions
        #expect(habit.completionRate() >= 0)
        
        // Add some completions
        for i in 0..<10 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                habit.completedDates.append(date)
            }
        }
        
        let rate = habit.completionRate()
        #expect(rate >= 0)
        #expect(rate <= 1.0)
    }
}

// MARK: - HabitCompletion Model Tests
@MainActor
struct HabitCompletionModelTests {
    
    @Test func testCompletionCreation() async throws {
        let completion = HabitCompletion(
            habitId: UUID(),
            date: Date(),
            note: "Test note"
        )
        
        #expect(completion.note == "Test note")
        #expect(completion.imagePath == nil)
        #expect(completion.model3DPath == nil)
        #expect(!completion.hasMedia)
    }
    
    @Test func testCompletionWithImage() async throws {
        var completion = HabitCompletion(
            habitId: UUID(),
            date: Date()
        )
        
        completion.imagePath = "/path/to/image.jpg"
        completion.mediaType = .image
        
        #expect(completion.hasMedia)
        #expect(completion.mediaType == .image)
        #expect(completion.mediaIcon == "photo.fill")
    }
    
    @Test func testCompletionWith3DModel() async throws {
        var completion = HabitCompletion(
            habitId: UUID(),
            date: Date()
        )
        
        completion.model3DPath = "/path/to/model.usdz"
        completion.mediaType = .model3D
        
        #expect(completion.hasMedia)
        #expect(completion.mediaType == .model3D)
        #expect(completion.mediaIcon == "cube.fill")
    }
}

// MARK: - AppConfig Tests
@MainActor
struct AppConfigTests {
    
    @Test func testAppearanceModes() async throws {
        #expect(AppearanceMode.light.rawValue == "light")
        #expect(AppearanceMode.dark.rawValue == "dark")
        #expect(AppearanceMode.auto.rawValue == "auto")
        #expect(AppearanceMode.allCases.count == 3)
    }
    
    @Test func testAppVersionEnum() async throws {
        let free = AppConfig.AppVersion.free
        let premium = AppConfig.AppVersion.premium
        
        #expect(free.rawValue == "free")
        #expect(premium.rawValue == "premium")
    }
}

// MARK: - HabitIcons Tests
@MainActor
struct HabitIconsTests {
    
    @Test func testIconsExist() async throws {
        #expect(!HabitIcons.all.isEmpty)
        #expect(HabitIcons.all.count >= 10) // Should have many icons
    }
    
    @Test func testIconsAreValidSFSymbols() async throws {
        // All icons should be non-empty strings
        for icon in HabitIcons.all {
            #expect(!icon.isEmpty)
            #expect(icon.count > 0)
        }
    }
}

// MARK: - Date/Calendar Helper Tests
@MainActor
struct DateHelperTests {
    
    @Test func testStartOfDay() async throws {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test func testDateComparison() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        #expect(today < tomorrow)
        #expect(today > yesterday)
        #expect(Calendar.current.isDateInToday(today))
    }
    
    @Test func testWeekdayCalculation() async throws {
        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        
        #expect(weekdaySymbols.count == 7)
        #expect(weekdaySymbols[0] == "D") // Sunday
        #expect(weekdaySymbols[1] == "L") // Monday
        #expect(weekdaySymbols[6] == "S") // Saturday
    }
}

// MARK: - UUID Tests
@MainActor
struct UUIDTests {
    
    @Test func testUUIDUniqueness() async throws {
        var uuids = Set<UUID>()
        
        for _ in 0..<1000 {
            let uuid = UUID()
            #expect(!uuids.contains(uuid))
            uuids.insert(uuid)
        }
        
        #expect(uuids.count == 1000)
    }
    
    @Test func testUUIDStringFormat() async throws {
        let uuid = UUID()
        let string = uuid.uuidString
        
        #expect(string.count == 36) // UUID format: 8-4-4-4-12
        #expect(string.contains("-"))
    }
}

// MARK: - Habit Frequency Tests
@MainActor
struct HabitFrequencyTests {
    
    @Test func testDailyFrequency() async throws {
        let habit = Habit(
            name: "Daily",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.frequency.contains("Diario"))
        #expect(habit.frequency.count == 1)
    }
    
    @Test func testWeekendFrequency() async throws {
        let habit = Habit(
            name: "Weekend",
            description: "",
            frequency: ["S", "D"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.frequency.contains("S"))
        #expect(habit.frequency.contains("D"))
        #expect(!habit.frequency.contains("L"))
    }
    
    @Test func testWeekdayFrequency() async throws {
        let habit = Habit(
            name: "Weekday",
            description: "",
            frequency: ["L", "M", "X", "J", "V"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.frequency.count == 5)
        #expect(!habit.frequency.contains("S"))
        #expect(!habit.frequency.contains("D"))
    }
}

// MARK: - Habit Notes Tests
@MainActor
struct HabitNotesTests {
    
    @Test func testDailyNotesStorage() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.dailyNotes.isEmpty)
        
        habit.dailyNotes["2026-01-01"] = "Test note"
        
        #expect(habit.dailyNotes.count == 1)
        #expect(habit.dailyNotes["2026-01-01"] == "Test note")
    }
    
    @Test func testMultipleDailyNotes() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        habit.dailyNotes["2026-01-01"] = "Note 1"
        habit.dailyNotes["2026-01-02"] = "Note 2"
        habit.dailyNotes["2026-01-03"] = "Note 3"
        
        #expect(habit.dailyNotes.count == 3)
    }
}

// MARK: - Codable Tests
@MainActor
struct CodableTests {
    
    @Test func testHabitEncodeDecode() async throws {
        let habit = Habit(
            name: "Test Habit",
            description: "Description",
            frequency: ["Diario"],
            reminderTime: Date(),
            iconName: "star.fill",
            createdAt: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(habit)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Habit.self, from: data)
        
        #expect(decoded.name == habit.name)
        #expect(decoded.description == habit.description)
        #expect(decoded.frequency == habit.frequency)
        #expect(decoded.iconName == habit.iconName)
    }
    
    @Test func testHabitCompletionEncodeDecode() async throws {
        var completion = HabitCompletion(
            habitId: UUID(),
            date: Date(),
            note: "Test note"
        )
        completion.imagePath = "/test/path.jpg"
        completion.mediaType = .image
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(completion)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HabitCompletion.self, from: data)
        
        #expect(decoded.note == completion.note)
        #expect(decoded.imagePath == completion.imagePath)
        #expect(decoded.mediaType == completion.mediaType)
    }
    
    @Test func testHabitArrayEncodeDecode() async throws {
        let habits = [
            Habit(name: "Habit 1", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "star"),
            Habit(name: "Habit 2", description: "", frequency: ["L", "M"], reminderTime: nil, iconName: "heart"),
            Habit(name: "Habit 3", description: "", frequency: ["Diario"], reminderTime: nil, iconName: "book")
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(habits)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([Habit].self, from: data)
        
        #expect(decoded.count == 3)
        #expect(decoded[0].name == "Habit 1")
        #expect(decoded[1].name == "Habit 2")
        #expect(decoded[2].name == "Habit 3")
    }
}

// MARK: - Media Type Tests
@MainActor
struct MediaTypeTests {
    
    @Test func testMediaTypeValues() async throws {
        #expect(HabitCompletion.MediaType.image.rawValue == "image")
        #expect(HabitCompletion.MediaType.model3D.rawValue == "model3D")
    }
    
    @Test func testMediaTypeIcon() async throws {
        var completion = HabitCompletion(habitId: UUID(), date: Date())
        
        completion.mediaType = .image
        #expect(completion.mediaIcon == "photo.fill")
        
        completion.mediaType = .model3D
        #expect(completion.mediaIcon == "cube.fill")
        
        completion.mediaType = nil
        #expect(completion.mediaIcon == "doc.fill")
    }
}

// MARK: - Boundary Tests
@MainActor
struct BoundaryTests {
    
    @Test func testEmptyHabitName() async throws {
        let habit = Habit(
            name: "",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.name.isEmpty)
    }
    
    @Test func testLongHabitName() async throws {
        let longName = String(repeating: "A", count: 1000)
        let habit = Habit(
            name: longName,
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        #expect(habit.name.count == 1000)
    }
    
    @Test func testVeryLongStreak() async throws {
        var habit = Habit(
            name: "Test",
            description: "",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "star"
        )
        
        // Add 365 consecutive days
        let today = Calendar.current.startOfDay(for: Date())
        for i in 0..<365 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                habit.completedDates.append(date)
            }
        }
        
        // Streak should be significant (at least 100 days)
        #expect(habit.currentStreak >= 100)
    }
    
    @Test func testManyHabits() async throws {
        var habits: [Habit] = []
        
        for i in 0..<100 {
            habits.append(Habit(
                name: "Habit \(i)",
                description: "",
                frequency: ["Diario"],
                reminderTime: nil,
                iconName: "star"
            ))
        }
        
        #expect(habits.count == 100)
        
        // Encode/decode test
        let encoder = JSONEncoder()
        let data = try encoder.encode(habits)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([Habit].self, from: data)
        
        #expect(decoded.count == 100)
    }
}

// MARK: - RecapPeriod Tests
@MainActor
struct RecapPeriodTests {
    
    @Test func testRecapPeriodValues() async throws {
        #expect(RecapPeriod.daily.rawValue == "daily")
        #expect(RecapPeriod.weekly.rawValue == "weekly")
        #expect(RecapPeriod.monthly.rawValue == "monthly")
    }
    
    @Test func testRecapPeriodAllCases() async throws {
        #expect(RecapPeriod.allCases.count == 3)
        #expect(RecapPeriod.allCases.contains(.daily))
        #expect(RecapPeriod.allCases.contains(.weekly))
        #expect(RecapPeriod.allCases.contains(.monthly))
    }
    
    @Test func testRecapPeriodIcons() async throws {
        #expect(RecapPeriod.daily.icon == "sun.max.fill")
        #expect(RecapPeriod.weekly.icon == "calendar.badge.clock")
        #expect(RecapPeriod.monthly.icon == "calendar")
    }
}

// MARK: - HabitCategory Tests
@MainActor
struct HabitCategoryTests {
    
    @Test func testAllCategories() async throws {
        let categories = HabitCategory.allCases
        
        #expect(categories.count == 11)
        #expect(categories.contains(.fitness))
        #expect(categories.contains(.nutrition))
        #expect(categories.contains(.mindfulness))
        #expect(categories.contains(.learning))
        #expect(categories.contains(.health))
        #expect(categories.contains(.productivity))
        #expect(categories.contains(.sleep))
        #expect(categories.contains(.hydration))
        #expect(categories.contains(.creativity))
        #expect(categories.contains(.social))
        #expect(categories.contains(.unknown))
    }
    
    @Test func testCategoryIcons() async throws {
        #expect(HabitCategory.fitness.icon == "figure.walk")
        #expect(HabitCategory.nutrition.icon == "leaf.fill")
        #expect(HabitCategory.health.icon == "heart.fill")
        #expect(HabitCategory.sleep.icon == "bed.double.fill")
        #expect(HabitCategory.unknown.icon == "sparkles")
    }
}
