//
//  GamificationStore.swift
//  HabitApp
//
//  Store central para el sistema de gamificación
//  Gestiona XP, niveles, logros, trofeos y recompensas
//

import Foundation
import SwiftUI
import Combine

// MARK: - Claimed Reward Helper
@MainActor
struct ClaimedReward: Identifiable {
    let id: UUID
    let date: Date
    let xpEarned: Int
    let streakDay: Int
    let bonusMultiplier: Int
}

@MainActor
class GamificationStore: ObservableObject {
    static let shared = GamificationStore()
    
    // MARK: - Published Properties
    @Published var profile: GamificationProfile
    @Published var achievements: [Achievement]
    @Published var trophies: [Trophy]
    @Published var recentXPEvents: [XPEvent] = []
    @Published var dailyRewards: [DailyReward]
    @Published var showLevelUpAlert: Bool = false
    @Published var showAchievementAlert: Bool = false
    @Published var showTrophyAlert: Bool = false
    @Published var lastUnlockedAchievement: Achievement?
    @Published var lastUnlockedTrophy: Trophy?
    @Published var newLevel: UserLevel?
    
    // MARK: - Private Properties
    private let profileKey = "gamification_profile"
    private let achievementsKey = "gamification_achievements"
    private let trophiesKey = "gamification_trophies"
    private let dailyRewardsKey = "gamification_daily_rewards"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - XP Constants
    private let xpPerCompletion = 5
    private let xpPerStreakDay = 2
    private let maxStreakBonus = 20
    
    // MARK: - Initialization
    private init() {
        self.profile = GamificationProfile()
        self.achievements = Achievement.allAchievements
        self.trophies = TrophyCollection.allTrophies
        self.dailyRewards = DailyReward.weeklyRewards
        loadData()
        checkDailyLogin()
    }
    
    // MARK: - Public Methods
    
    /// Registra un hábito completado y otorga XP
    func habitCompleted(streak: Int, category: String) {
        print("[GamificationStore] 🎮 habitCompleted called - streak: \(streak), category: \(category)")
        print("[GamificationStore] Current stats - totalCompletions: \(profile.totalCompletions), maxStreak: \(profile.maxStreak)")
        
        // XP base por completar
        addXP(amount: xpPerCompletion, reason: "Hábito completado")
        
        // Bonus por racha
        if streak > 1 {
            let streakBonus = min(streak * xpPerStreakDay, maxStreakBonus)
            addXP(amount: streakBonus, reason: "Bonus racha \(streak) días", isBonus: true)
        }
        
        // Actualizar estadísticas
        profile.totalCompletions += 1
        profile.currentStreak = streak
        if streak > profile.maxStreak {
            profile.maxStreak = streak
        }
        
        // Registrar categoría usada
        profile.categoriesUsed.insert(category)
        
        print("[GamificationStore] Updated stats - totalCompletions: \(profile.totalCompletions), maxStreak: \(profile.maxStreak), totalXP: \(profile.totalXP)")
        
        // Verificar logros
        checkAchievements()
        checkTrophies()
        
        saveData()
        print("[GamificationStore] ✅ Data saved")
    }
    
    /// Registra una foto añadida
    func photoAdded() {
        print("[GamificationStore] 📷 Photo added")
        profile.photosAdded += 1
        checkAchievements()
        saveData()
    }
    
    /// Registra un modelo 3D creado
    func model3DCreated() {
        print("[GamificationStore] 🧊 3D Model created")
        profile.models3DCreated += 1
        checkAchievements()
        saveData()
    }
    
    /// Registra un hábito creado con AI
    func aiHabitCreated() {
        profile.aiHabitsCreated += 1
        checkAchievements()
        saveData()
    }
    
    /// Verifica y reclama recompensa diaria
    func claimDailyReward() -> DailyReward? {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Verificar si ya se reclamó hoy
        let alreadyClaimedToday = dailyRewards.contains { reward in
            if let claimedDate = reward.claimedDate {
                return Calendar.current.isDate(claimedDate, inSameDayAs: today)
            }
            return false
        }
        
        if alreadyClaimedToday {
            print("[GamificationStore] Daily reward already claimed today")
            return nil
        }
        
        // Calcular qué recompensa toca (basado en el día de la semana dentro de la racha)
        // Si loginStreak es 0, dar la primera recompensa
        let dayIndex = max(0, (profile.dailyLoginStreak - 1)) % 7
        
        print("[GamificationStore] Claiming daily reward - loginStreak: \(profile.dailyLoginStreak), dayIndex: \(dayIndex)")
        
        guard dayIndex < dailyRewards.count else {
            print("[GamificationStore] Invalid day index: \(dayIndex)")
            return nil
        }
        
        // Crear una copia actualizada de la recompensa
        var reward = dailyRewards[dayIndex]
        
        // Marcar como reclamada con fecha de hoy
        reward.isClaimed = true
        reward.claimedDate = today
        dailyRewards[dayIndex] = reward
        
        // Calcular XP con bonus por racha
        let streakMultiplier = max(1, (profile.dailyLoginStreak / 7) + 1)
        let totalXP = reward.xpReward * streakMultiplier
        
        print("[GamificationStore] Giving XP: \(totalXP) (base: \(reward.xpReward) x \(streakMultiplier))")
        
        addXP(amount: totalXP, reason: "Recompensa diaria día \(profile.dailyLoginStreak)", isBonus: true)
        
        saveData()
        return reward
    }
    
    /// Obtiene el progreso de un logro específico
    func getAchievementProgress(_ achievementId: String) -> Double {
        guard let achievement = achievements.first(where: { $0.id == achievementId }) else {
            return 0
        }
        return achievement.progressPercentage
    }
    
    /// Obtiene logros por categoría
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
    
    /// Obtiene trofeos por tier
    func trophies(for tier: TrophyTier) -> [Trophy] {
        trophies.filter { $0.tier == tier }
    }
    
    /// Estadísticas de logros
    var achievementStats: (unlocked: Int, total: Int) {
        let unlocked = achievements.filter { $0.isUnlocked }.count
        return (unlocked, achievements.count)
    }
    
    /// Estadísticas de trofeos
    var trophyStats: (unlocked: Int, total: Int) {
        let unlocked = trophies.filter { $0.isUnlocked }.count
        return (unlocked, trophies.count)
    }
    
    /// Indica si puede reclamar recompensa diaria
    var canClaimDailyReward: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return !dailyRewards.contains { reward in
            if let claimedDate = reward.claimedDate {
                return Calendar.current.isDate(claimedDate, inSameDayAs: today)
            }
            return false
        }
    }
    
    /// Historial de recompensas reclamadas
    var recentRewards: [ClaimedReward] {
        var claimed: [ClaimedReward] = []
        for (index, reward) in dailyRewards.enumerated() where reward.isClaimed {
            if let date = reward.claimedDate {
                let multiplier = max(1, (index / 7) + 1)
                claimed.append(ClaimedReward(
                    id: reward.id,
                    date: date,
                    xpEarned: reward.xpReward * multiplier,
                    streakDay: index + 1,
                    bonusMultiplier: multiplier
                ))
            }
        }
        return claimed.sorted { $0.date > $1.date }
    }
    
    /// Verifica si se ha reclamado recompensa para una fecha
    func hasClaimedReward(for date: Date) -> Bool {
        let targetDay = Calendar.current.startOfDay(for: date)
        return dailyRewards.contains { reward in
            if let claimedDate = reward.claimedDate {
                return Calendar.current.isDate(claimedDate, inSameDayAs: targetDay)
            }
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func addXP(amount: Int, reason: String, isBonus: Bool = false) {
        let oldLevel = profile.level
        profile.totalXP += amount
        let newLevelInfo = profile.level
        
        // Registrar evento XP
        let event = XPEvent(amount: amount, reason: reason, timestamp: Date(), isBonus: isBonus)
        recentXPEvents.insert(event, at: 0)
        if recentXPEvents.count > 50 {
            recentXPEvents.removeLast()
        }
        
        // Verificar subida de nivel
        if newLevelInfo.id > oldLevel.id {
            profile.currentLevel = newLevelInfo.id
            newLevel = newLevelInfo
            showLevelUpAlert = true
            
            // Verificar logros de nivel
            checkLevelAchievements()
        }
    }
    
    private func checkAchievements() {
        print("[GamificationStore] 🏆 Checking achievements...")
        var newlyUnlocked: [Achievement] = []
        
        for i in 0..<achievements.count {
            guard !achievements[i].isUnlocked else { continue }
            
            var shouldUnlock = false
            var newProgress = 0
            
            switch achievements[i].id {
            // Streak achievements
            case "streak_3", "streak_7", "streak_14", "streak_30", "streak_100", "streak_365":
                newProgress = profile.maxStreak
                shouldUnlock = profile.maxStreak >= achievements[i].requirement
                
            // Completion achievements
            case "complete_1", "complete_10", "complete_50", "complete_100", "complete_500", "complete_1000":
                newProgress = profile.totalCompletions
                shouldUnlock = profile.totalCompletions >= achievements[i].requirement
                
            // Explorer achievements
            case "first_photo":
                newProgress = profile.photosAdded
                shouldUnlock = profile.photosAdded >= 1
                
            case "first_3d":
                newProgress = profile.models3DCreated
                shouldUnlock = profile.models3DCreated >= 1
                
            case "ai_habit":
                newProgress = profile.aiHabitsCreated
                shouldUnlock = profile.aiHabitsCreated >= 1
                
            case "five_habits":
                // Este se actualizaría desde HabitStore
                break
                
            case "all_categories":
                newProgress = profile.categoriesUsed.count
                shouldUnlock = profile.categoriesUsed.count >= 11
                
            // Special achievements
            case "first_day":
                newProgress = profile.totalCompletions > 0 ? 1 : 0
                shouldUnlock = profile.totalCompletions >= 1
                
            case "new_year":
                let calendar = Calendar.current
                let now = Date()
                let isNewYear = calendar.component(.month, from: now) == 1 && 
                               calendar.component(.day, from: now) == 1
                if isNewYear && profile.totalCompletions > 0 {
                    newProgress = 1
                    shouldUnlock = true
                }
                
            default:
                break
            }
            
            achievements[i].progress = newProgress
            
            if shouldUnlock {
                print("[GamificationStore] 🎉 UNLOCKED: \(achievements[i].name) (+\(achievements[i].xpReward) XP)")
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = Date()
                profile.unlockedAchievements.append(achievements[i].id)
                
                // Dar XP por el logro
                addXP(amount: achievements[i].xpReward, reason: "Logro: \(achievements[i].name)", isBonus: true)
                
                newlyUnlocked.append(achievements[i])
            }
        }
        
        print("[GamificationStore] Checked \(achievements.count) achievements, unlocked \(newlyUnlocked.count) new ones")
        
        // Mostrar alerta para el primer logro nuevo
        if let first = newlyUnlocked.first {
            lastUnlockedAchievement = first
            showAchievementAlert = true
        }
    }
    
    private func checkLevelAchievements() {
        for i in 0..<achievements.count {
            guard !achievements[i].isUnlocked else { continue }
            
            switch achievements[i].id {
            case "level_5":
                if profile.currentLevel >= 5 {
                    unlockAchievement(at: i)
                }
            case "level_10":
                if profile.currentLevel >= 10 {
                    unlockAchievement(at: i)
                }
            default:
                break
            }
        }
    }
    
    private func unlockAchievement(at index: Int) {
        guard !achievements[index].isUnlocked else { return }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        profile.unlockedAchievements.append(achievements[index].id)
        
        addXP(amount: achievements[index].xpReward, reason: "Logro: \(achievements[index].name)", isBonus: true)
        
        lastUnlockedAchievement = achievements[index]
        showAchievementAlert = true
    }
    
    private func checkTrophies() {
        print("[GamificationStore] 🏅 Checking trophies...")
        var newlyUnlocked: [Trophy] = []
        
        for i in 0..<trophies.count {
            guard !trophies[i].isUnlocked else { continue }
            
            var shouldUnlock = false
            
            switch trophies[i].requirement {
            case .totalCompletions(let required):
                shouldUnlock = profile.totalCompletions >= required
                
            case .maxStreak(let required):
                shouldUnlock = profile.maxStreak >= required
                
            case .monthlyPerfect(let required):
                shouldUnlock = profile.perfectMonths >= required
                
            case .totalXP(let required):
                shouldUnlock = profile.totalXP >= required
                
            case .level(let required):
                shouldUnlock = profile.currentLevel >= required
                
            case .achievements(let required):
                shouldUnlock = profile.unlockedAchievements.count >= required
            }
            
            if shouldUnlock {
                print("[GamificationStore] 🏆 TROPHY UNLOCKED: \(trophies[i].name)")
                trophies[i].isUnlocked = true
                trophies[i].unlockedDate = Date()
                profile.unlockedTrophies.append(trophies[i].id)
                
                // Dar XP bonus por el trofeo
                addXP(amount: trophies[i].tier.xpBonus, reason: "Trofeo: \(trophies[i].name)", isBonus: true)
                
                newlyUnlocked.append(trophies[i])
            }
        }
        
        print("[GamificationStore] Checked \(trophies.count) trophies, unlocked \(newlyUnlocked.count) new ones")
        
        // Mostrar alerta para el primer trofeo nuevo
        if let first = newlyUnlocked.first {
            lastUnlockedTrophy = first
            showTrophyAlert = true
        }
    }
    
    private func checkDailyLogin() {
        let today = Calendar.current.startOfDay(for: Date())
        
        print("[GamificationStore] 📅 Checking daily login...")
        print("[GamificationStore] Current loginStreak before check: \(profile.dailyLoginStreak)")
        
        if let lastLogin = profile.lastLoginDate {
            let lastLoginDay = Calendar.current.startOfDay(for: lastLogin)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastLoginDay, to: today).day ?? 0
            
            print("[GamificationStore] Last login: \(lastLogin), days diff: \(daysDiff)")
            
            if daysDiff == 1 {
                // Login consecutivo
                profile.dailyLoginStreak += 1
                print("[GamificationStore] Consecutive login! New streak: \(profile.dailyLoginStreak)")
            } else if daysDiff > 1 {
                // Racha rota
                profile.dailyLoginStreak = 1
                print("[GamificationStore] Streak broken! Reset to 1")
                
                // Verificar logro comeback
                if daysDiff >= 7 {
                    checkComebackAchievement()
                }
            } else {
                print("[GamificationStore] Same day login, no change")
            }
        } else {
            // Primer login
            profile.dailyLoginStreak = 1
            print("[GamificationStore] First login ever! Streak: 1")
        }
        
        profile.lastLoginDate = today
        saveData()
        print("[GamificationStore] Final loginStreak: \(profile.dailyLoginStreak)")
    }
    
    private func checkComebackAchievement() {
        for i in 0..<achievements.count {
            if achievements[i].id == "comeback" && !achievements[i].isUnlocked {
                unlockAchievement(at: i)
                break
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        let encoder = JSONEncoder()
        
        if let profileData = try? encoder.encode(profile) {
            UserDefaults.standard.set(profileData, forKey: profileKey)
        }
        
        if let achievementsData = try? encoder.encode(achievements) {
            UserDefaults.standard.set(achievementsData, forKey: achievementsKey)
        }
        
        if let trophiesData = try? encoder.encode(trophies) {
            UserDefaults.standard.set(trophiesData, forKey: trophiesKey)
        }
        
        if let rewardsData = try? encoder.encode(dailyRewards) {
            UserDefaults.standard.set(rewardsData, forKey: dailyRewardsKey)
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        print("[GamificationStore] 📂 Loading saved data...")
        
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? decoder.decode(GamificationProfile.self, from: profileData) {
            self.profile = savedProfile
            print("[GamificationStore] Loaded profile - XP: \(profile.totalXP), Level: \(profile.currentLevel), Completions: \(profile.totalCompletions)")
        }
        
        if let achievementsData = UserDefaults.standard.data(forKey: achievementsKey),
           let savedAchievements = try? decoder.decode([Achievement].self, from: achievementsData) {
            self.achievements = savedAchievements
            print("[GamificationStore] Loaded \(achievements.count) achievements")
        }
        
        if let trophiesData = UserDefaults.standard.data(forKey: trophiesKey),
           let savedTrophies = try? decoder.decode([Trophy].self, from: trophiesData) {
            self.trophies = savedTrophies
            print("[GamificationStore] Loaded \(trophies.count) trophies")
        }
        
        if let rewardsData = UserDefaults.standard.data(forKey: dailyRewardsKey),
           let savedRewards = try? decoder.decode([DailyReward].self, from: rewardsData) {
            // Verificar que los rewards tengan valores válidos
            let hasValidRewards = savedRewards.allSatisfy { $0.xpReward > 0 }
            if hasValidRewards && savedRewards.count == 7 {
                self.dailyRewards = savedRewards
                print("[GamificationStore] Loaded \(dailyRewards.count) daily rewards")
            } else {
                print("[GamificationStore] ⚠️ Daily rewards corrupted, resetting to defaults")
                self.dailyRewards = DailyReward.weeklyRewards
            }
        }
        
        print("[GamificationStore] ✅ Data loaded successfully")
    }
    
    /// Reinicia todos los datos de gamificación (para testing)
    func resetAllData() {
        profile = GamificationProfile()
        achievements = Achievement.allAchievements
        trophies = TrophyCollection.allTrophies
        dailyRewards = DailyReward.weeklyRewards
        recentXPEvents.removeAll()
        saveData()
    }
}
