import Foundation
import Combine
import SwiftUI
import UserNotifications

@MainActor
final class HabitStore: ObservableObject {
    static let shared = HabitStore()
    
    @Published var habits: [Habit] = [] {
        didSet { saveHabits() }
    }
    
    private let fileName = "habits.json"
    private let fileURL: URL
    
    // MARK: - Inicialización Singleton
    private init() {
        #if os(iOS)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #elseif os(macOS)
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #endif
        
        fileURL = directory.appendingPathComponent(fileName)
        loadHabits()
    }
    
    private let noteDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func noteKey(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        return noteDateFormatter.string(from: day)
    }
    
    func note(for habit: Habit, on date: Date) -> String? {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return nil }
        let key = noteKey(for: date)
        return habits[index].dailyNotes[key]
    }

    func setNote(_ text: String, for habit: Habit, on date: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = noteKey(for: date)
        habits[index].dailyNotes[key] = text
    }

    func clearNote(for habit: Habit, on date: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = noteKey(for: date)
        habits[index].dailyNotes.removeValue(forKey: key)
    }

    // MARK: - CRUD
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        scheduleNotification(for: habit)
    }
    
    func removeHabit(at offsets: IndexSet) {
        offsets.forEach { index in
            let habit = habits[index]
            cancelNotification(for: habit)
            
            // Delete all completions and media for this habit
            let completions = CompletionStore.shared.getCompletions(for: habit.id)
            for completion in completions {
                CompletionStore.shared.deleteCompletion(completion)
            }
        }
        habits.remove(atOffsets: offsets)
        saveHabits()
    }
    
    func toggleHabitCompletion(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        
        if isCompletedToday(habit) {
            habits[index].completedDates.removeAll {
                Calendar.current.isDate($0, inSameDayAs: today)
            }
            let key = noteKey(for: today)
            habits[index].dailyNotes.removeValue(forKey: key)
            
            CompletionStore.shared.removeCompletion(for: habit.id, on: today)
        } else {
            habits[index].completedDates.append(today)
        }
        saveHabits()
    }

    func isCompletedToday(_ habit: Habit) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains { Calendar.current.isDate($0, inSameDayAs: today) }
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        return habit.completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    func uncompleteHabit(_ habit: Habit, on date: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        habits[index].completedDates.removeAll {
            Calendar.current.isDate($0, inSameDayAs: date)
        }
        
        let key = noteKey(for: date)
        habits[index].dailyNotes.removeValue(forKey: key)
        
        // Delete completion and media
        CompletionStore.shared.removeCompletion(for: habit.id, on: date)
        
        saveHabits()
    }
    
    // MARK: - JSON Persistence
    private func saveHabits() {
        do {
            let data = try JSONEncoder().encode(habits)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error guardando hábitos: \(error.localizedDescription)")
        }
    }
    
    private func loadHabits() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Habit].self, from: data)
            habits = decoded
        } catch {
            print("No se pudieron cargar los hábitos: \(error.localizedDescription)")
            habits = []
        }
    }
    
    // MARK: - Notificaciones locales
    func scheduleNotification(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }
        
        let lang = LanguageManager.shared

        let content = UNMutableNotificationContent()
        content.title = String(format: lang.localized("notification_title"), habit.name)
        content.body = habit.description.isEmpty ? lang.localized("notification_body") : habit.description
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error programando notificación: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    }

    func rescheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for habit in habits {
            scheduleNotification(for: habit)
        }
    }
    
    func resetAllData() {
        // Delete all completions and media
        CompletionStore.shared.deleteAllCompletions()
        
        habits.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
