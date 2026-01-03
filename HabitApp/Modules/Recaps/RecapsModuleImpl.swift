//
//  RecapsModuleImpl.swift
//  HabitApp
//
//  Módulo de Recaps/Resúmenes - Implementación
//  Autor: Jorge
//  
//  Este módulo genera resúmenes visuales del progreso de hábitos
//  en formato stories. Se inyecta mediante Protocol + DI.
//

import SwiftUI
import Combine

// MARK: - Recaps Module Implementation
@MainActor
final class RecapsModuleImpl: RecapsModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.recaps"
    static var moduleName: String = "Recaps Module"
    static var moduleAuthor: String = "Jorge"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    
    // MARK: - Dependencies
    private let habitStore = HabitStore.shared
    private let completionStore = CompletionStore.shared
    
    // MARK: - Protocol Properties
    var availablePeriods: [String] {
        return ["daily", "weekly", "monthly"]
    }
    
    // MARK: - Initialization
    init() {
        print("[\(Self.moduleName)] Module instance created")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        isEnabled = false
    }
    
    // MARK: - Recap Generation
    func generateRecapData(for period: String) -> RecapData {
        let calendar = Calendar.current
        let now = Date()
        
        // Determinar rango de fechas según el periodo
        let dateRange: DateInterval
        switch period {
        case "daily":
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            dateRange = DateInterval(start: start, end: end)
        case "weekly":
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            dateRange = DateInterval(start: start, end: end)
        case "monthly":
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            dateRange = DateInterval(start: start, end: end)
        default:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            dateRange = DateInterval(start: start, end: end)
        }
        
        // Calcular estadísticas
        let totalHabits = habitStore.habits.count
        let completions = completionStore.completions.filter { completion in
            dateRange.contains(completion.date)
        }
        let completedHabits = Set(completions.map { $0.habitId }).count
        let completionRate = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) : 0
        
        // Encontrar mejor racha
        let bestStreak = calculateBestStreak()
        
        // Encontrar hábito más completado
        let habitCompletionCounts = Dictionary(grouping: completions, by: { $0.habitId })
            .mapValues { $0.count }
        let mostCompletedHabitId = habitCompletionCounts.max(by: { $0.value < $1.value })?.key
        let mostCompletedHabit = habitStore.habits.first { $0.id == mostCompletedHabitId }?.name
        
        return RecapData(
            period: period,
            totalHabits: totalHabits,
            completedHabits: completedHabits,
            completionRate: completionRate,
            bestStreak: bestStreak,
            mostCompletedHabit: mostCompletedHabit
        )
    }
    
    private func calculateBestStreak() -> Int {
        var bestStreak = 0
        
        for habit in habitStore.habits {
            let streak = habitStore.calculateStreak(for: habit)
            if streak > bestStreak {
                bestStreak = streak
            }
        }
        
        return bestStreak
    }
    
    // MARK: - View Factory
    func recapView(for period: String) -> AnyView {
        let recapPeriod: RecapPeriod
        switch period {
        case "daily":
            recapPeriod = .daily
        case "weekly":
            recapPeriod = .weekly
        case "monthly":
            recapPeriod = .monthly
        default:
            recapPeriod = .daily
        }
        
        return AnyView(
            RecapViewWrapper(period: recapPeriod)
        )
    }
}

// MARK: - View Wrapper
struct RecapViewWrapper: View {
    let period: RecapPeriod
    
    var body: some View {
        RecapView(period: period)
    }
}

// MARK: - Factory
struct RecapsModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = RecapsModuleImpl
    
    static func create() -> RecapsModuleImpl {
        return RecapsModuleImpl()
    }
}
