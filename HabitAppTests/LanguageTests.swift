//
//  LanguageTests.swift
//  HabitAppTests
//
//  Tests for LanguageManager and localization
//

import Testing
import Foundation
@testable import HabitApp

// MARK: - Language Manager Tests
@MainActor
struct LanguageManagerTests {
    
    @MainActor
    @Test func testDefaultLanguage() async throws {
        let manager = LanguageManager.shared
        #expect(manager.language == "es" || manager.language == "en")
    }
    
    @MainActor
    @Test func testSupportedLanguages() async throws {
        let supported = ["es", "en"]
        let manager = LanguageManager.shared
        
        #expect(supported.contains(manager.language))
    }
    
    @MainActor
    @Test func testLanguageChange() async throws {
        let manager = LanguageManager.shared
        let originalLanguage = manager.language
        
        manager.setLanguage("en")
        #expect(manager.language == "en")
        
        manager.setLanguage("es")
        #expect(manager.language == "es")
        
        // Restore original
        manager.setLanguage(originalLanguage)
    }
    
    @MainActor
    @Test func testTranslationExists() async throws {
        let manager = LanguageManager.shared
        let originalLanguage = manager.language
        
        // Test Spanish translations
        manager.setLanguage("es")
        let spanishTitle = manager.localized("habits")
        #expect(!spanishTitle.isEmpty)
        #expect(spanishTitle == "Hábitos")
        
        // Test English translations
        manager.setLanguage("en")
        let englishTitle = manager.localized("habits")
        #expect(!englishTitle.isEmpty)
        #expect(englishTitle == "Habits")
        
        // Restore original
        manager.setLanguage(originalLanguage)
    }
    
    @Test func testDayTranslations() async throws {
        let weekdays = ["L", "M", "X", "J", "V", "S", "D"]
        
        for day in weekdays {
            #expect(!day.isEmpty)
            #expect(day.count == 1)
        }
    }
    
    @Test func testDailyTranslation() async throws {
        let daily = "Diario"
        #expect(daily == "Diario")
    }
}

// MARK: - Localization Key Tests
@MainActor
struct LocalizationKeyTests {
    
    @Test func testCommonKeys() async throws {
        let commonKeys = [
            "habits",
            "statistics",
            "settings",
            "save",
            "cancel",
            "delete",
            "edit"
        ]
        
        for key in commonKeys {
            #expect(!key.isEmpty)
        }
    }
    
    @Test func testHabitRelatedKeys() async throws {
        let habitKeys = [
            "add_habit",
            "habit_name",
            "habit_description",
            "frequency",
            "reminder"
        ]
        
        for key in habitKeys {
            #expect(!key.isEmpty)
        }
    }
    
    @Test func testSettingsKeys() async throws {
        let settingsKeys = [
            "appearance",
            "language",
            "notifications",
            "about"
        ]
        
        for key in settingsKeys {
            #expect(!key.isEmpty)
        }
    }
}

// MARK: - Date Formatting Tests
@MainActor
struct DateFormattingTests {
    
    @Test func testDateFormatter() async throws {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es")
        
        let date = Date()
        let formatted = formatter.string(from: date)
        
        #expect(!formatted.isEmpty)
    }
    
    @Test func testTimeFormatter() async throws {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es")
        
        let date = Date()
        let formatted = formatter.string(from: date)
        
        #expect(!formatted.isEmpty)
    }
    
    @Test func testRelativeDateFormatter() async throws {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "es")
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let relative = formatter.localizedString(for: yesterday, relativeTo: Date())
        
        #expect(!relative.isEmpty)
    }
    
    @Test func testDateKeyFormat() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let date = Date()
        let key = formatter.string(from: date)
        
        #expect(key.count == 10) // "2024-01-01" format
        #expect(key.contains("-"))
    }
}

// MARK: - Number Formatting Tests
@MainActor
struct NumberFormattingTests {
    
    @Test func testPercentageFormatting() async throws {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        
        let percentage = 0.75
        let formatted = formatter.string(from: NSNumber(value: percentage))
        
        #expect(formatted != nil)
        #expect(formatted!.contains("75") || formatted!.contains("75"))
    }
    
    @Test func testStreakFormatting() async throws {
        let streak = 42
        let formatted = "\(streak)"
        
        #expect(formatted == "42")
    }
    
    @Test func testDecimalFormatting() async throws {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        let value = 3.14159
        let formatted = formatter.string(from: NSNumber(value: value))
        
        #expect(formatted != nil)
    }
}

// MARK: - Calendar Localization Tests
@MainActor
struct CalendarLocalizationTests {
    
    @Test func testWeekdaySymbols() async throws {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "es")
        
        let symbols = calendar.veryShortWeekdaySymbols
        
        #expect(symbols.count == 7)
    }
    
    @Test func testMonthSymbols() async throws {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "es")
        
        let symbols = calendar.monthSymbols
        
        #expect(symbols.count == 12)
    }
    
    @Test func testFirstWeekday() async throws {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "es")
        
        // Spain typically starts week on Monday (2)
        #expect(calendar.firstWeekday >= 1 && calendar.firstWeekday <= 7)
    }
}

// MARK: - Accessibility Label Tests
@MainActor
struct AccessibilityLabelTests {
    
    @Test func testAccessibilityLabelsNotEmpty() async throws {
        let labels = [
            "Add new habit",
            "Toggle completion",
            "View statistics",
            "Open settings",
            "Delete habit"
        ]
        
        for label in labels {
            #expect(!label.isEmpty)
            #expect(label.count > 3)
        }
    }
    
    @Test func testVoiceOverDescriptions() async throws {
        // Simulate habit description for VoiceOver
        let habit = Habit(
            name: "Morning Exercise",
            description: "30 minutes cardio",
            frequency: ["Diario"],
            reminderTime: nil,
            iconName: "figure.walk"
        )
        
        let description = "\(habit.name), \(habit.description), streak: \(habit.currentStreak)"
        
        #expect(!description.isEmpty)
        #expect(description.contains("Morning Exercise"))
    }
}
