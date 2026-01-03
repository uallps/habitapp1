//
//  GamificationModels.swift
//  HabitApp
//
//  Sistema de gamificación: Puntos, niveles, logros y recompensas
//  Solo disponible para usuarios Premium
//

import Foundation
import SwiftUI

// MARK: - User Level System
@MainActor
struct UserLevel: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let minXP: Int
    let maxXP: Int
    let iconName: String
    let color: String
    
    var xpRequired: Int {
        maxXP - minXP
    }
    
    static let levels: [UserLevel] = [
        UserLevel(id: 1, name: "Novato", minXP: 0, maxXP: 100, iconName: "star", color: "gray"),
        UserLevel(id: 2, name: "Aprendiz", minXP: 100, maxXP: 300, iconName: "star.fill", color: "green"),
        UserLevel(id: 3, name: "Dedicado", minXP: 300, maxXP: 600, iconName: "star.circle", color: "blue"),
        UserLevel(id: 4, name: "Constante", minXP: 600, maxXP: 1000, iconName: "star.circle.fill", color: "purple"),
        UserLevel(id: 5, name: "Experto", minXP: 1000, maxXP: 1500, iconName: "star.square", color: "orange"),
        UserLevel(id: 6, name: "Maestro", minXP: 1500, maxXP: 2200, iconName: "star.square.fill", color: "red"),
        UserLevel(id: 7, name: "Leyenda", minXP: 2200, maxXP: 3000, iconName: "crown", color: "yellow"),
        UserLevel(id: 8, name: "Héroe", minXP: 3000, maxXP: 4000, iconName: "crown.fill", color: "pink"),
        UserLevel(id: 9, name: "Campeón", minXP: 4000, maxXP: 5500, iconName: "trophy", color: "cyan"),
        UserLevel(id: 10, name: "Inmortal", minXP: 5500, maxXP: Int.max, iconName: "trophy.fill", color: "gold")
    ]
    
    static func level(for xp: Int) -> UserLevel {
        return levels.last { xp >= $0.minXP } ?? levels[0]
    }
}

// MARK: - Achievement Category
@MainActor
enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"           // Rachas
    case completion = "completion"   // Completados
    case consistency = "consistency" // Consistencia
    case explorer = "explorer"       // Explorador (probar funciones)
    case social = "social"           // Social
    case special = "special"         // Especiales
    
    var displayName: String {
        switch self {
        case .streak: return "Rachas"
        case .completion: return "Completados"
        case .consistency: return "Consistencia"
        case .explorer: return "Explorador"
        case .social: return "Social"
        case .special: return "Especiales"
        }
    }
    
    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .completion: return "checkmark.seal.fill"
        case .consistency: return "calendar.badge.checkmark"
        case .explorer: return "safari.fill"
        case .social: return "person.2.fill"
        case .special: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .streak: return .orange
        case .completion: return .green
        case .consistency: return .blue
        case .explorer: return .purple
        case .social: return .pink
        case .special: return .yellow
        }
    }
}

// MARK: - Achievement Rarity
@MainActor
enum AchievementRarity: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Común"
        case .uncommon: return "Poco común"
        case .rare: return "Raro"
        case .epic: return "Épico"
        case .legendary: return "Legendario"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var xpReward: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        }
    }
    
    var glowIntensity: Double {
        switch self {
        case .common: return 0
        case .uncommon: return 0.3
        case .rare: return 0.5
        case .epic: return 0.7
        case .legendary: return 1.0
        }
    }
}

// MARK: - Achievement
@MainActor
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let iconName: String
    let imageName: String  // Placeholder para imagen personalizada
    let requirement: Int
    let xpReward: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Int
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - All Achievements
    static let allAchievements: [Achievement] = [
        // === STREAK ACHIEVEMENTS ===
        Achievement(
            id: "streak_3",
            name: "Primer Paso",
            description: "Completa una racha de 3 días",
            category: .streak,
            rarity: .common,
            iconName: "flame",
            imageName: "achievement_streak_3",
            requirement: 3,
            xpReward: 10,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "streak_7",
            name: "Semana Perfecta",
            description: "Mantén una racha de 7 días",
            category: .streak,
            rarity: .uncommon,
            iconName: "flame.fill",
            imageName: "achievement_streak_7",
            requirement: 7,
            xpReward: 30,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "streak_14",
            name: "Dos Semanas Fuertes",
            description: "Mantén una racha de 14 días",
            category: .streak,
            rarity: .rare,
            iconName: "flame.circle",
            imageName: "achievement_streak_14",
            requirement: 14,
            xpReward: 60,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "streak_30",
            name: "Mes Invicto",
            description: "Mantén una racha de 30 días",
            category: .streak,
            rarity: .epic,
            iconName: "flame.circle.fill",
            imageName: "achievement_streak_30",
            requirement: 30,
            xpReward: 150,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "streak_100",
            name: "Centenario",
            description: "Mantén una racha de 100 días",
            category: .streak,
            rarity: .legendary,
            iconName: "flame.fill",
            imageName: "achievement_streak_100",
            requirement: 100,
            xpReward: 500,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "streak_365",
            name: "Un Año Imparable",
            description: "Mantén una racha de 365 días",
            category: .streak,
            rarity: .legendary,
            iconName: "flame.fill",
            imageName: "achievement_streak_365",
            requirement: 365,
            xpReward: 1000,
            isUnlocked: false,
            progress: 0
        ),
        
        // === COMPLETION ACHIEVEMENTS ===
        Achievement(
            id: "complete_1",
            name: "Primer Hábito",
            description: "Completa un hábito por primera vez",
            category: .completion,
            rarity: .common,
            iconName: "checkmark.circle",
            imageName: "achievement_complete_1",
            requirement: 1,
            xpReward: 5,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "complete_10",
            name: "Empezando Fuerte",
            description: "Completa 10 hábitos en total",
            category: .completion,
            rarity: .common,
            iconName: "checkmark.circle.fill",
            imageName: "achievement_complete_10",
            requirement: 10,
            xpReward: 15,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "complete_50",
            name: "En Racha",
            description: "Completa 50 hábitos en total",
            category: .completion,
            rarity: .uncommon,
            iconName: "checkmark.seal",
            imageName: "achievement_complete_50",
            requirement: 50,
            xpReward: 40,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "complete_100",
            name: "Centurión",
            description: "Completa 100 hábitos en total",
            category: .completion,
            rarity: .rare,
            iconName: "checkmark.seal.fill",
            imageName: "achievement_complete_100",
            requirement: 100,
            xpReward: 75,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "complete_500",
            name: "Medio Millar",
            description: "Completa 500 hábitos en total",
            category: .completion,
            rarity: .epic,
            iconName: "checkmark.shield",
            imageName: "achievement_complete_500",
            requirement: 500,
            xpReward: 200,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "complete_1000",
            name: "Mil Victorias",
            description: "Completa 1000 hábitos en total",
            category: .completion,
            rarity: .legendary,
            iconName: "checkmark.shield.fill",
            imageName: "achievement_complete_1000",
            requirement: 1000,
            xpReward: 500,
            isUnlocked: false,
            progress: 0
        ),
        
        // === CONSISTENCY ACHIEVEMENTS ===
        Achievement(
            id: "weekly_perfect",
            name: "Semana Perfecta",
            description: "Completa todos los hábitos durante una semana",
            category: .consistency,
            rarity: .rare,
            iconName: "calendar.badge.checkmark",
            imageName: "achievement_weekly_perfect",
            requirement: 1,
            xpReward: 75,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "monthly_80",
            name: "Mes Productivo",
            description: "Logra 80% de completados en un mes",
            category: .consistency,
            rarity: .epic,
            iconName: "calendar.circle.fill",
            imageName: "achievement_monthly_80",
            requirement: 1,
            xpReward: 150,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "early_bird",
            name: "Madrugador",
            description: "Completa un hábito antes de las 7 AM",
            category: .consistency,
            rarity: .uncommon,
            iconName: "sunrise.fill",
            imageName: "achievement_early_bird",
            requirement: 1,
            xpReward: 25,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "night_owl",
            name: "Noctámbulo",
            description: "Completa un hábito después de las 11 PM",
            category: .consistency,
            rarity: .uncommon,
            iconName: "moon.stars.fill",
            imageName: "achievement_night_owl",
            requirement: 1,
            xpReward: 25,
            isUnlocked: false,
            progress: 0
        ),
        
        // === EXPLORER ACHIEVEMENTS ===
        Achievement(
            id: "first_photo",
            name: "Fotógrafo",
            description: "Añade una foto a un hábito completado",
            category: .explorer,
            rarity: .common,
            iconName: "camera.fill",
            imageName: "achievement_first_photo",
            requirement: 1,
            xpReward: 15,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "first_3d",
            name: "Explorador 3D",
            description: "Crea tu primer modelo 3D",
            category: .explorer,
            rarity: .rare,
            iconName: "cube.fill",
            imageName: "achievement_first_3d",
            requirement: 1,
            xpReward: 50,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "ai_habit",
            name: "Visionario AI",
            description: "Crea un hábito usando la cámara AI",
            category: .explorer,
            rarity: .rare,
            iconName: "brain.head.profile",
            imageName: "achievement_ai_habit",
            requirement: 1,
            xpReward: 50,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "five_habits",
            name: "Organizador",
            description: "Crea 5 hábitos diferentes",
            category: .explorer,
            rarity: .uncommon,
            iconName: "square.grid.2x2.fill",
            imageName: "achievement_five_habits",
            requirement: 5,
            xpReward: 30,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "all_categories",
            name: "Explorador Total",
            description: "Crea hábitos en todas las categorías",
            category: .explorer,
            rarity: .epic,
            iconName: "globe",
            imageName: "achievement_all_categories",
            requirement: 11,
            xpReward: 100,
            isUnlocked: false,
            progress: 0
        ),
        
        // === SPECIAL ACHIEVEMENTS ===
        Achievement(
            id: "first_day",
            name: "Bienvenido",
            description: "Completa tu primer día en la app",
            category: .special,
            rarity: .common,
            iconName: "hand.wave.fill",
            imageName: "achievement_first_day",
            requirement: 1,
            xpReward: 10,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "comeback",
            name: "Regreso Triunfal",
            description: "Vuelve después de 7 días sin usar la app",
            category: .special,
            rarity: .rare,
            iconName: "arrow.counterclockwise.circle.fill",
            imageName: "achievement_comeback",
            requirement: 1,
            xpReward: 40,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "new_year",
            name: "Año Nuevo",
            description: "Completa un hábito el 1 de enero",
            category: .special,
            rarity: .epic,
            iconName: "party.popper.fill",
            imageName: "achievement_new_year",
            requirement: 1,
            xpReward: 100,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "level_5",
            name: "Subiendo de Nivel",
            description: "Alcanza el nivel 5",
            category: .special,
            rarity: .rare,
            iconName: "arrow.up.circle.fill",
            imageName: "achievement_level_5",
            requirement: 5,
            xpReward: 75,
            isUnlocked: false,
            progress: 0
        ),
        Achievement(
            id: "level_10",
            name: "Inmortal",
            description: "Alcanza el nivel máximo",
            category: .special,
            rarity: .legendary,
            iconName: "crown.fill",
            imageName: "achievement_level_10",
            requirement: 10,
            xpReward: 500,
            isUnlocked: false,
            progress: 0
        )
    ]
}

// MARK: - Trophy
@MainActor
struct Trophy: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let imageName: String
    let tier: TrophyTier
    let requirement: TrophyRequirement
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    static func == (lhs: Trophy, rhs: Trophy) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
enum TrophyTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var displayName: String {
        switch self {
        case .bronze: return "Bronce"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platino"
        case .diamond: return "Diamante"
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .diamond: return Color(red: 0.4, green: 0.8, blue: 1.0)
        }
    }
    
    var xpBonus: Int {
        switch self {
        case .bronze: return 50
        case .silver: return 100
        case .gold: return 200
        case .platinum: return 400
        case .diamond: return 1000
        }
    }
}

@MainActor
enum TrophyRequirement: Codable, Equatable {
    case totalCompletions(Int)
    case maxStreak(Int)
    case monthlyPerfect(Int)
    case totalXP(Int)
    case level(Int)
    case achievements(Int)
    
    var description: String {
        switch self {
        case .totalCompletions(let count):
            return "Completa \(count) hábitos en total"
        case .maxStreak(let days):
            return "Alcanza una racha de \(days) días"
        case .monthlyPerfect(let months):
            return "Logra \(months) meses perfectos"
        case .totalXP(let xp):
            return "Acumula \(xp) XP"
        case .level(let level):
            return "Alcanza el nivel \(level)"
        case .achievements(let count):
            return "Desbloquea \(count) logros"
        }
    }
}

// MARK: - Trophy Collection
@MainActor
struct TrophyCollection {
    static let allTrophies: [Trophy] = [
        // Bronze Trophies
        Trophy(
            id: "bronze_beginner",
            name: "Iniciado",
            description: "Tus primeros pasos en el camino del hábito",
            iconName: "trophy.fill",
            imageName: "trophy_bronze_beginner",
            tier: .bronze,
            requirement: .totalCompletions(25),
            isUnlocked: false
        ),
        Trophy(
            id: "bronze_streak",
            name: "Persistente",
            description: "Demuestras que puedes mantener el ritmo",
            iconName: "trophy.fill",
            imageName: "trophy_bronze_streak",
            tier: .bronze,
            requirement: .maxStreak(7),
            isUnlocked: false
        ),
        
        // Silver Trophies
        Trophy(
            id: "silver_dedicated",
            name: "Dedicado",
            description: "Tu compromiso es admirable",
            iconName: "trophy.fill",
            imageName: "trophy_silver_dedicated",
            tier: .silver,
            requirement: .totalCompletions(100),
            isUnlocked: false
        ),
        Trophy(
            id: "silver_streak",
            name: "Inquebrantable",
            description: "Un mes sin fallar, impresionante",
            iconName: "trophy.fill",
            imageName: "trophy_silver_streak",
            tier: .silver,
            requirement: .maxStreak(30),
            isUnlocked: false
        ),
        
        // Gold Trophies
        Trophy(
            id: "gold_master",
            name: "Maestro de Hábitos",
            description: "Has dominado el arte de la constancia",
            iconName: "trophy.fill",
            imageName: "trophy_gold_master",
            tier: .gold,
            requirement: .totalCompletions(500),
            isUnlocked: false
        ),
        Trophy(
            id: "gold_streak",
            name: "Leyenda Viviente",
            description: "100 días de pura determinación",
            iconName: "trophy.fill",
            imageName: "trophy_gold_streak",
            tier: .gold,
            requirement: .maxStreak(100),
            isUnlocked: false
        ),
        
        // Platinum Trophies
        Trophy(
            id: "platinum_elite",
            name: "Élite",
            description: "Solo los más dedicados llegan aquí",
            iconName: "trophy.fill",
            imageName: "trophy_platinum_elite",
            tier: .platinum,
            requirement: .totalCompletions(1000),
            isUnlocked: false
        ),
        Trophy(
            id: "platinum_achiever",
            name: "Coleccionista",
            description: "Has desbloqueado la mayoría de logros",
            iconName: "trophy.fill",
            imageName: "trophy_platinum_achiever",
            tier: .platinum,
            requirement: .achievements(20),
            isUnlocked: false
        ),
        
        // Diamond Trophies
        Trophy(
            id: "diamond_legend",
            name: "Inmortal",
            description: "Has alcanzado la cima. Eres una leyenda.",
            iconName: "crown.fill",
            imageName: "trophy_diamond_legend",
            tier: .diamond,
            requirement: .level(10),
            isUnlocked: false
        ),
        Trophy(
            id: "diamond_perfect",
            name: "Perfección",
            description: "Un año completo de hábitos perfectos",
            iconName: "star.circle.fill",
            imageName: "trophy_diamond_perfect",
            tier: .diamond,
            requirement: .maxStreak(365),
            isUnlocked: false
        )
    ]
}

// MARK: - Daily Reward
@MainActor
struct DailyReward: Identifiable, Codable {
    let id: UUID
    let day: Int
    let xpReward: Int
    let iconName: String
    let bonusType: BonusType?
    var isClaimed: Bool
    var claimedDate: Date?
    
    enum BonusType: String, Codable {
        case doubleXP = "doubleXP"
        case badge = "badge"
        case specialItem = "specialItem"
    }
    
    static let weeklyRewards: [DailyReward] = [
        DailyReward(id: UUID(), day: 1, xpReward: 5, iconName: "gift.fill", bonusType: nil, isClaimed: false),
        DailyReward(id: UUID(), day: 2, xpReward: 10, iconName: "gift.fill", bonusType: nil, isClaimed: false),
        DailyReward(id: UUID(), day: 3, xpReward: 15, iconName: "gift.fill", bonusType: nil, isClaimed: false),
        DailyReward(id: UUID(), day: 4, xpReward: 20, iconName: "gift.fill", bonusType: nil, isClaimed: false),
        DailyReward(id: UUID(), day: 5, xpReward: 25, iconName: "star.fill", bonusType: .doubleXP, isClaimed: false),
        DailyReward(id: UUID(), day: 6, xpReward: 30, iconName: "gift.fill", bonusType: nil, isClaimed: false),
        DailyReward(id: UUID(), day: 7, xpReward: 50, iconName: "crown.fill", bonusType: .specialItem, isClaimed: false)
    ]
}

// MARK: - Gamification Profile
@MainActor
struct GamificationProfile: Codable {
    var totalXP: Int
    var currentLevel: Int
    var totalCompletions: Int
    var maxStreak: Int
    var currentStreak: Int
    var unlockedAchievements: [String]
    var unlockedTrophies: [String]
    var dailyLoginStreak: Int
    var lastLoginDate: Date?
    var joinDate: Date
    var perfectMonths: Int
    var photosAdded: Int
    var models3DCreated: Int
    var aiHabitsCreated: Int
    var categoriesUsed: Set<String>
    
    init() {
        self.totalXP = 0
        self.currentLevel = 1
        self.totalCompletions = 0
        self.maxStreak = 0
        self.currentStreak = 0
        self.unlockedAchievements = []
        self.unlockedTrophies = []
        self.dailyLoginStreak = 0
        self.lastLoginDate = nil
        self.joinDate = Date()
        self.perfectMonths = 0
        self.photosAdded = 0
        self.models3DCreated = 0
        self.aiHabitsCreated = 0
        self.categoriesUsed = []
    }
    
    var level: UserLevel {
        UserLevel.level(for: totalXP)
    }
    
    /// Alias para dailyLoginStreak
    var loginStreak: Int {
        dailyLoginStreak
    }
    
    var xpToNextLevel: Int {
        let currentLevelInfo = level
        return max(0, currentLevelInfo.maxXP - totalXP)
    }
    
    var xpProgress: Double {
        let currentLevelInfo = level
        let xpInLevel = totalXP - currentLevelInfo.minXP
        let xpNeeded = currentLevelInfo.maxXP - currentLevelInfo.minXP
        guard xpNeeded > 0 else { return 1.0 }
        return Double(xpInLevel) / Double(xpNeeded)
    }
}

// MARK: - XP Event
@MainActor
struct XPEvent: Identifiable {
    let id = UUID()
    let amount: Int
    let reason: String
    let timestamp: Date
    let isBonus: Bool
    
    static func habitCompleted() -> XPEvent {
        XPEvent(amount: 5, reason: "Hábito completado", timestamp: Date(), isBonus: false)
    }
    
    static func streakBonus(days: Int) -> XPEvent {
        let bonus = min(days, 10) * 2  // Max 20 XP bonus
        return XPEvent(amount: bonus, reason: "Bonus racha \(days) días", timestamp: Date(), isBonus: true)
    }
    
    static func achievementUnlocked(name: String, xp: Int) -> XPEvent {
        XPEvent(amount: xp, reason: "Logro: \(name)", timestamp: Date(), isBonus: true)
    }
    
    static func dailyLogin(day: Int) -> XPEvent {
        XPEvent(amount: 5 + day, reason: "Login diario día \(day)", timestamp: Date(), isBonus: false)
    }
}
