//
//  GamificationModuleImpl.swift
//  HabitApp
//
//  Módulo de Gamificación y Recompensas - Implementación
//  Autor: Lucas
//  
//  Este módulo implementa un sistema completo de gamificación con:
//  - Sistema de XP y niveles
//  - Logros/Achievements con raridades
//  - Trofeos coleccionables
//  - Recompensas diarias
//  Solo disponible para usuarios Premium
//

import SwiftUI
import Combine

// MARK: - Gamification Module Implementation
@MainActor
final class GamificationModuleImpl: GamificationModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.gamification"
    static var moduleName: String = "Gamification Module"
    static var moduleAuthor: String = "Lucas"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    
    // MARK: - Dependencies
    private let store = GamificationStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Protocol Properties
    var isPremiumUser: Bool {
        PremiumFeatures.isEnabled
    }
    
    var currentLevel: Int {
        store.profile.currentLevel
    }
    
    var totalXP: Int {
        store.profile.totalXP
    }
    
    var unlockedAchievements: Int {
        store.achievementStats.unlocked
    }
    
    var unlockedTrophies: Int {
        store.trophyStats.unlocked
    }
    
    var loginStreak: Int {
        store.profile.loginStreak
    }
    
    // MARK: - Initialization
    init() {
        print("[\(Self.moduleName)] Module instance created")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        
        // Solo activar para usuarios premium
        if PremiumFeatures.isEnabled {
            isEnabled = true
            print("[\(Self.moduleName)] Initialized successfully (Premium user)")
        } else {
            print("[\(Self.moduleName)] Not enabled (Non-premium user)")
        }
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        isEnabled = false
    }
    
    // MARK: - Habit Tracking
    func recordHabitCompletion(streak: Int, category: String) {
        print("[Gamification] Recording habit completion - streak: \(streak), category: \(category)")
        store.habitCompleted(streak: streak, category: category)
    }
    
    func recordPhotoAdded() {
        print("[Gamification] Recording photo added")
        store.photoAdded()
    }
    
    func recordModel3DCreated() {
        print("[Gamification] Recording 3D model created")
        store.model3DCreated()
    }
    
    func recordAIHabitCreated() {
        print("[Gamification] Recording AI habit created")
        store.aiHabitCreated()
    }
    
    // MARK: - Daily Rewards
    func claimDailyReward() -> Int? {
        print("[Gamification] Claiming daily reward")
        return store.claimDailyReward()?.xpReward
    }
    
    // MARK: - Views
    func gamificationHubView() -> AnyView {
        AnyView(
            GamificationHubView()
        )
    }
    
    // MARK: - Profile Data
    func getProfileData() -> GamificationProfileData {
        let profile = store.profile
        let currentLevelInfo = profile.level  // This is the computed UserLevel
        let nextLevel = UserLevel.levels.first { $0.id == currentLevelInfo.id + 1 }
        
        let xpInCurrentLevel = profile.totalXP - currentLevelInfo.minXP
        let xpForNextLevel = nextLevel != nil ? nextLevel!.minXP - currentLevelInfo.minXP : 0
        let progress = xpForNextLevel > 0 ? Double(xpInCurrentLevel) / Double(xpForNextLevel) : 1.0
        
        return GamificationProfileData(
            totalXP: profile.totalXP,
            currentLevel: currentLevelInfo.id,
            levelName: currentLevelInfo.name,
            xpForNextLevel: xpForNextLevel,
            currentLevelProgress: progress,
            totalCompletions: profile.totalCompletions,
            maxStreak: profile.maxStreak,
            unlockedAchievements: store.achievementStats.unlocked,
            totalAchievements: store.achievementStats.total,
            unlockedTrophies: store.trophyStats.unlocked,
            totalTrophies: store.trophyStats.total,
            loginStreak: profile.loginStreak
        )
    }
}

// MARK: - Module Factory
extension GamificationModuleImpl {
    static func create() -> GamificationModuleImpl {
        return GamificationModuleImpl()
    }
}
