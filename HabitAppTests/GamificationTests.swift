//
//  GamificationTests.swift
//  HabitAppTests
//
//  Tests for Gamification Module: XP, Levels, Achievements, Trophies
//

import Testing
import Foundation
import SwiftUI
@testable import HabitApp

// MARK: - Test Errors
enum GamificationTestError: Error {
    case levelNotFound
    case achievementNotFound
    case trophyNotFound
}

// MARK: - UserLevel Tests
@MainActor
struct UserLevelTests {
    
    @MainActor
    @Test func testLevelCount() async throws {
        #expect(UserLevel.levels.count == 10)
    }
    
    @MainActor
    @Test func testLevelOrder() async throws {
        let levels = UserLevel.levels
        
        for i in 0..<levels.count - 1 {
            #expect(levels[i].id < levels[i + 1].id)
            #expect(levels[i].maxXP <= levels[i + 1].minXP)
        }
    }
    
    @MainActor
    @Test func testLevelForXP_Novato() async throws {
        LanguageManager.shared.setLanguage("es")
        let level = UserLevel.level(for: 0)
        #expect(level.id == 1)
        #expect(level.name == "Novato")
    }
    
    @MainActor
    @Test func testLevelForXP_Aprendiz() async throws {
        LanguageManager.shared.setLanguage("es")
        let level = UserLevel.level(for: 100)
        #expect(level.id == 2)
        #expect(level.name == "Aprendiz")
    }
    
    @MainActor
    @Test func testLevelForXP_HighXP() async throws {
        LanguageManager.shared.setLanguage("es")
        let level = UserLevel.level(for: 6000)
        #expect(level.id == 10)
        #expect(level.name == "Inmortal")
    }
    
    @MainActor
    @Test func testLevelForXP_EdgeCase() async throws {
        // Test XP at exact boundary
        let levelAt99 = UserLevel.level(for: 99)
        #expect(levelAt99.id == 1)
        
        let levelAt100 = UserLevel.level(for: 100)
        #expect(levelAt100.id == 2)
    }
    
    @MainActor
    @Test func testLevelNames() async throws {
        LanguageManager.shared.setLanguage("es")
        let expectedNames = ["Novato", "Aprendiz", "Dedicado", "Constante", "Experto", 
                            "Maestro", "Leyenda", "Héroe", "Campeón", "Inmortal"]
        
        for (index, level) in UserLevel.levels.enumerated() {
            #expect(level.name == expectedNames[index])
        }
    }
}

// MARK: - Achievement Category Tests
@MainActor
struct AchievementCategoryTests {
    
    @MainActor
    @Test func testCategoryCount() async throws {
        #expect(AchievementCategory.allCases.count == 6)
    }
    
    @MainActor
    @Test func testCategoryDisplayNames() async throws {
        LanguageManager.shared.setLanguage("es")
        #expect(AchievementCategory.streak.displayName == "Rachas")
        #expect(AchievementCategory.completion.displayName == "Completados")
        #expect(AchievementCategory.consistency.displayName == "Consistencia")
        #expect(AchievementCategory.explorer.displayName == "Explorador")
        #expect(AchievementCategory.social.displayName == "Social")
        #expect(AchievementCategory.special.displayName == "Especiales")
    }
    
    @MainActor
    @Test func testCategoryIcons() async throws {
        #expect(AchievementCategory.streak.icon == "flame.fill")
        #expect(AchievementCategory.completion.icon == "checkmark.seal.fill")
        #expect(AchievementCategory.consistency.icon == "calendar.badge.checkmark")
    }
}

// MARK: - Achievement Rarity Tests
@MainActor
struct AchievementRarityTests {
    
    @MainActor
    @Test func testRarityCount() async throws {
        #expect(AchievementRarity.allCases.count == 5)
    }
    
    @MainActor
    @Test func testRarityXPRewards() async throws {
        #expect(AchievementRarity.common.xpReward == 10)
        #expect(AchievementRarity.uncommon.xpReward == 25)
        #expect(AchievementRarity.rare.xpReward == 50)
        #expect(AchievementRarity.epic.xpReward == 100)
        #expect(AchievementRarity.legendary.xpReward == 250)
    }
    
    @MainActor
    @Test func testRarityDisplayNames() async throws {
        LanguageManager.shared.setLanguage("es")
        #expect(AchievementRarity.common.displayName == "Común")
        #expect(AchievementRarity.legendary.displayName == "Legendario")
    }
    
    @MainActor
    @Test func testRarityGlowIntensity() async throws {
        #expect(AchievementRarity.common.glowIntensity == 0)
        #expect(AchievementRarity.legendary.glowIntensity == 1.0)
    }
}

// MARK: - Achievement Tests
@MainActor
struct AchievementTests {
    
    @MainActor
    @Test func testAllAchievementsExist() async throws {
        let achievements = Achievement.allAchievements
        #expect(achievements.count >= 20) // Al menos 20 logros
    }
    
    @MainActor
    @Test func testAchievementUniqueIds() async throws {
        let achievements = Achievement.allAchievements
        let ids = achievements.map { $0.id }
        let uniqueIds = Set(ids)
        
        #expect(ids.count == uniqueIds.count)
    }
    
    @MainActor
    @Test func testAchievementCategories() async throws {
        let achievements = Achievement.allAchievements
        
        // Verify achievements exist and have valid categories
        #expect(achievements.count >= 1)
        
        // Check that at least some categories have achievements
        let categoriesWithAchievements = Set(achievements.map { $0.category })
        #expect(categoriesWithAchievements.count >= 1)
    }
    
    @MainActor
    @Test func testFirstAchievementStructure() async throws {
        let achievement = Achievement.allAchievements.first!
        
        #expect(!achievement.id.isEmpty)
        #expect(!achievement.name.isEmpty)
        #expect(!achievement.description.isEmpty)
        #expect(!achievement.iconName.isEmpty)
        #expect(achievement.requirement > 0)
        #expect(achievement.xpReward > 0)
    }
    
    @MainActor
    @Test func testAchievementProgress() async throws {
        // Create a test achievement
        var achievement = Achievement(
            id: "test_progress",
            nameKey: "test_progress_name",
            descriptionKey: "test_progress_desc",
            category: .streak,
            rarity: .common,
            iconName: "star",
            imageName: "test",
            requirement: 10,
            xpReward: 50,
            isUnlocked: false,
            progress: 5
        )
        
        #expect(achievement.progressPercentage == 0.5)
        
        achievement.progress = 10
        #expect(achievement.progressPercentage == 1.0)
    }
}

// MARK: - Trophy Tier Tests
@MainActor
struct TrophyTierTests {
    
    @MainActor
    @Test func testTierCount() async throws {
        #expect(TrophyTier.allCases.count == 5)
    }
    
    @MainActor
    @Test func testTierXPBonus() async throws {
        #expect(TrophyTier.bronze.xpBonus == 50)
        #expect(TrophyTier.silver.xpBonus == 100)
        #expect(TrophyTier.gold.xpBonus == 200)
        #expect(TrophyTier.platinum.xpBonus == 400)
        #expect(TrophyTier.diamond.xpBonus == 1000)
    }
    
    @MainActor
    @Test func testTierDisplayNames() async throws {
        LanguageManager.shared.setLanguage("es")
        #expect(TrophyTier.bronze.displayName == "Bronce")
        #expect(TrophyTier.silver.displayName == "Plata")
        #expect(TrophyTier.gold.displayName == "Oro")
        #expect(TrophyTier.platinum.displayName == "Platino")
        #expect(TrophyTier.diamond.displayName == "Diamante")
    }
}

// MARK: - Trophy Collection Tests
@MainActor
struct TrophyCollectionTests {
    
    @MainActor
    @Test func testAllTrophiesExist() async throws {
        let trophies = TrophyCollection.allTrophies
        #expect(trophies.count >= 10) // Al menos 10 trofeos
    }
    
    @MainActor
    @Test func testTrophyUniqueIds() async throws {
        let trophies = TrophyCollection.allTrophies
        let ids = trophies.map { $0.id }
        let uniqueIds = Set(ids)
        
        #expect(ids.count == uniqueIds.count)
    }
    
    @MainActor
    @Test func testTrophyTiersExist() async throws {
        let trophies = TrophyCollection.allTrophies
        
        // Verify at least one trophy per tier (except maybe diamond which is very rare)
        let bronze = trophies.filter { $0.tier == .bronze }
        let silver = trophies.filter { $0.tier == .silver }
        let gold = trophies.filter { $0.tier == .gold }
        
        #expect(bronze.count >= 1)
        #expect(silver.count >= 1)
        #expect(gold.count >= 1)
    }
    
    @MainActor
    @Test func testTrophyStructure() async throws {
        let trophy = TrophyCollection.allTrophies.first!
        
        #expect(!trophy.id.isEmpty)
        #expect(!trophy.name.isEmpty)
        #expect(!trophy.description.isEmpty)
        #expect(!trophy.iconName.isEmpty)
    }
}

// MARK: - GamificationProfile Tests
@MainActor
struct GamificationProfileTests {
    
    @MainActor
    @Test func testProfileInitialization() async throws {
        let profile = GamificationProfile()
        
        #expect(profile.totalXP == 0)
        #expect(profile.currentLevel == 1)
        #expect(profile.totalCompletions == 0)
        #expect(profile.currentStreak == 0)
        #expect(profile.maxStreak == 0)
        #expect(profile.loginStreak == 0)
    }
    
    @MainActor
    @Test func testProfileCurrentLevel() async throws {
        var profile = GamificationProfile()
        
        profile.totalXP = 150
        #expect(profile.level.id == 2) // Aprendiz
        
        profile.totalXP = 1500
        #expect(profile.level.id == 6) // Maestro
    }
    
    @MainActor
    @Test func testProfileCategoriesUsed() async throws {
        var profile = GamificationProfile()
        
        #expect(profile.categoriesUsed.isEmpty)
        
        profile.categoriesUsed.insert("health")
        profile.categoriesUsed.insert("fitness")
        
        #expect(profile.categoriesUsed.count == 2)
    }
}

// MARK: - GamificationStore Tests
@MainActor
struct GamificationStoreTests {
    
    @MainActor
    @Test func testStoreSharedInstance() async throws {
        let store1 = GamificationStore.shared
        let store2 = GamificationStore.shared
        
        #expect(store1 === store2)
    }
    
    @MainActor
    @Test func testStoreHasAchievements() async throws {
        let store = GamificationStore.shared
        
        #expect(store.achievements.count > 0)
    }
    
    @MainActor
    @Test func testStoreHasTrophies() async throws {
        let store = GamificationStore.shared
        
        #expect(store.trophies.count > 0)
    }
    
    @MainActor
    @Test func testAchievementStats() async throws {
        let store = GamificationStore.shared
        let stats = store.achievementStats
        
        #expect(stats.total > 0)
        #expect(stats.unlocked >= 0)
        #expect(stats.unlocked <= stats.total)
    }
    
    @MainActor
    @Test func testTrophyStats() async throws {
        let store = GamificationStore.shared
        let stats = store.trophyStats
        
        #expect(stats.total > 0)
        #expect(stats.unlocked >= 0)
        #expect(stats.unlocked <= stats.total)
    }
    
    @MainActor
    @Test func testAchievementsByCategory() async throws {
        let store = GamificationStore.shared
        
        for category in AchievementCategory.allCases {
            let categoryAchievements = store.achievements(for: category)
            #expect(categoryAchievements.count >= 0)
        }
    }
    
    @MainActor
    @Test func testTrophiesByTier() async throws {
        let store = GamificationStore.shared
        
        for tier in TrophyTier.allCases {
            let tierTrophies = store.trophies(for: tier)
            #expect(tierTrophies.count >= 0)
        }
    }
}

// MARK: - XP Event Tests
@MainActor
struct XPEventTests {
    
    @MainActor
    @Test func testXPEventCreation() async throws {
        let event = XPEvent(
            amount: 100,
            reason: "Test XP",
            timestamp: Date(),
            isBonus: false
        )
        
        #expect(event.amount == 100)
        #expect(event.reason == "Test XP")
        #expect(!event.isBonus)
    }
    
    @MainActor
    @Test func testXPEventWithBonus() async throws {
        let event = XPEvent(
            amount: 50,
            reason: "Bonus",
            timestamp: Date(),
            isBonus: true
        )
        
        #expect(event.isBonus)
    }
}

// MARK: - Daily Reward Tests
@MainActor
struct DailyRewardTests {
    
    @MainActor
    @Test func testWeeklyRewardsExist() async throws {
        let rewards = DailyReward.weeklyRewards
        
        #expect(rewards.count == 7)
    }
    
    @MainActor
    @Test func testWeeklyRewardsProgression() async throws {
        let rewards = DailyReward.weeklyRewards
        
        // Check XP increases throughout the week
        for i in 0..<rewards.count - 1 {
            #expect(rewards[i].xpReward <= rewards[i + 1].xpReward)
        }
    }
    
    @MainActor
    @Test func testDailyRewardStructure() async throws {
        let reward = DailyReward.weeklyRewards.first!
        
        #expect(reward.day >= 1)
        #expect(reward.xpReward > 0)
        #expect(!reward.iconName.isEmpty)
    }
}

// MARK: - Gamification Module Tests
@MainActor
struct GamificationModuleImplTests {
    
    @MainActor
    @Test func testModuleMetadata() async throws {
        #expect(GamificationModuleImpl.moduleId == "com.habitapp.module.gamification")
        #expect(GamificationModuleImpl.moduleName == "Gamification Module")
        #expect(GamificationModuleImpl.moduleAuthor == "Lucas")
        #expect(!GamificationModuleImpl.moduleVersion.isEmpty)
    }
    
    @MainActor
    @Test func testModuleCreation() async throws {
        let module = GamificationModuleImpl.create()
        
        #expect(module.currentLevel >= 1)
        #expect(module.totalXP >= 0)
        #expect(module.unlockedAchievements >= 0)
        #expect(module.unlockedTrophies >= 0)
    }
    
    @MainActor
    @Test func testModuleInitialization() async throws {
        let module = GamificationModuleImpl()
        
        #expect(!module.isEnabled) // Not enabled before initialize()
        
        module.initialize()
        // Will be enabled only for premium users
    }
    
    @MainActor
    @Test func testModuleCleanup() async throws {
        let module = GamificationModuleImpl()
        
        module.initialize()
        module.cleanup()
        
        #expect(!module.isEnabled)
    }
    
    @MainActor
    @Test func testGetProfileData() async throws {
        let module = GamificationModuleImpl()
        let profileData = module.getProfileData()
        
        #expect(profileData.currentLevel >= 1)
        #expect(!profileData.levelName.isEmpty)
        #expect(profileData.totalAchievements > 0)
        #expect(profileData.totalTrophies > 0)
    }
    
    @MainActor
    @Test func testGamificationHubView() async throws {
        let module = GamificationModuleImpl()
        let view = module.gamificationHubView()
        
        // Just verify it returns a view without crashing
        #expect(type(of: view) == AnyView.self)
    }
}

// MARK: - Module Registry Integration Tests
@MainActor
struct GamificationModuleRegistryTests {
    
    @MainActor
    @Test func testModuleRegistration() async throws {
        let registry = ModuleRegistry.shared
        let module = GamificationModuleImpl()
        
        registry.registerGamificationModule(module)
        
        #expect(registry.hasGamificationModule)
        #expect(registry.gamificationModule != nil)
    }
    
    @MainActor
    @Test func testRegisteredModuleProperties() async throws {
        let registry = ModuleRegistry.shared
        
        if let module = registry.gamificationModule {
            #expect(module.totalXP >= 0)
            #expect(module.currentLevel >= 1)
        }
    }
}
