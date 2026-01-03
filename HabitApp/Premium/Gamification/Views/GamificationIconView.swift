//
//  GamificationIconView.swift
//  HabitApp
//
//  Componente reutilizable para mostrar iconos de logros y trofeos
//  con efecto de bloqueado/desbloqueado
//

import SwiftUI

// MARK: - Achievement Icon View
struct AchievementIconView: View {
    let achievement: Achievement
    let size: CGFloat
    
    init(achievement: Achievement, size: CGFloat = 80) {
        self.achievement = achievement
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Glow effect for unlocked (behind everything)
            if achievement.isUnlocked && achievement.rarity.glowIntensity > 0 {
                Circle()
                    .fill(achievement.rarity.color.opacity(0.4))
                    .frame(width: size + 10, height: size + 10)
                    .blur(radius: 12)
            }
            
            // Icon content - fills the entire circle
            Group {
                if let uiImage = loadCustomImage(named: achievement.imageName) {
                    // Custom image exists - occupies full circle
                    #if os(iOS)
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                    #else
                    Image(nsImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                    #endif
                } else {
                    // Fallback to SF Symbol with colored background
                    ZStack {
                        Circle()
                            .fill(
                                achievement.isUnlocked
                                    ? achievement.rarity.color.gradient
                                    : Color.gray.opacity(0.4).gradient
                            )
                            .frame(width: size, height: size)
                        
                        Image(systemName: achievement.iconName)
                            .font(.system(size: size * 0.45, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .saturation(achievement.isUnlocked ? 1 : 0.3)
            .opacity(achievement.isUnlocked ? 1 : 0.7)
            
            // Lock overlay for locked achievements
            if !achievement.isUnlocked {
                lockOverlay
            }
        }
        .frame(width: size, height: size)
    }
    
    private var lockOverlay: some View {
        ZStack {
            // Lighter darkening overlay
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: size, height: size)
            
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
    }
    
    #if os(iOS)
    private func loadCustomImage(named name: String) -> UIImage? {
        return UIImage(named: name)
    }
    #else
    private func loadCustomImage(named name: String) -> NSImage? {
        return NSImage(named: name)
    }
    #endif
}

// MARK: - Trophy Icon View
struct TrophyIconView: View {
    let trophy: Trophy
    let size: CGFloat
    
    init(trophy: Trophy, size: CGFloat = 80) {
        self.trophy = trophy
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Shine effect for unlocked trophies (behind)
            if trophy.isUnlocked {
                Circle()
                    .fill(trophy.tier.color.opacity(0.4))
                    .frame(width: size + 10, height: size + 10)
                    .blur(radius: 12)
            }
            
            // Icon content - fills the entire circle
            Group {
                if let uiImage = loadCustomImage(named: trophy.imageName) {
                    // Custom image exists - occupies full circle
                    #if os(iOS)
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                    #else
                    Image(nsImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                    #endif
                } else {
                    // Fallback to SF Symbol with tier gradient background
                    ZStack {
                        Circle()
                            .fill(
                                trophy.isUnlocked
                                    ? AnyShapeStyle(trophyGradient)
                                    : AnyShapeStyle(Color.gray.opacity(0.4))
                            )
                            .frame(width: size, height: size)
                        
                        // Shine effect on top
                        if trophy.isUnlocked {
                            shineEffect
                        }
                        
                        Image(systemName: trophy.iconName)
                            .font(.system(size: size * 0.45, weight: .bold))
                            .foregroundStyle(trophy.isUnlocked ? .white : .gray)
                    }
                }
            }
            .saturation(trophy.isUnlocked ? 1 : 0.3)
            .opacity(trophy.isUnlocked ? 1 : 0.7)
            
            // Lock overlay for locked trophies
            if !trophy.isUnlocked {
                lockOverlay
            }
            
            // Tier badge
            if trophy.isUnlocked {
                tierBadge
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
        .frame(width: size, height: size)
    }
    
    private var trophyGradient: LinearGradient {
        switch trophy.tier {
        case .bronze:
            return LinearGradient(
                colors: [Color(red: 0.9, green: 0.6, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .silver:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.85, blue: 0.9), Color(red: 0.65, green: 0.65, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .platinum:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.95, blue: 1.0), Color(red: 0.8, green: 0.8, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .diamond:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.9, blue: 1.0), Color(red: 0.4, green: 0.7, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shineEffect: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.4), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            .frame(width: size, height: size)
    }
    
    private var lockOverlay: some View {
        ZStack {
            // Lighter darkening overlay
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: size, height: size)
            
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
    }
    
    private var tierBadge: some View {
        ZStack {
            Circle()
                .fill(trophy.tier.color)
                .frame(width: size * 0.25, height: size * 0.25)
            
            Text(tierInitial)
                .font(.system(size: size * 0.12, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 2)
    }
    
    private var tierInitial: String {
        switch trophy.tier {
        case .bronze: return "B"
        case .silver: return "S"
        case .gold: return "G"
        case .platinum: return "P"
        case .diamond: return "D"
        }
    }
    
    #if os(iOS)
    private func loadCustomImage(named name: String) -> UIImage? {
        return UIImage(named: name)
    }
    #else
    private func loadCustomImage(named name: String) -> NSImage? {
        return NSImage(named: name)
    }
    #endif
}

// MARK: - Preview
#Preview("Achievements") {
    VStack(spacing: 20) {
        Text("Logros").font(.headline)
        
        HStack(spacing: 16) {
            // Unlocked example
            AchievementIconView(
                achievement: Achievement(
                    id: "test_unlocked",
                    name: "Test Unlocked",
                    description: "Test",
                    category: .streak,
                    rarity: .epic,
                    iconName: "flame.fill",
                    imageName: "achievement_streak_30",
                    requirement: 30,
                    xpReward: 100,
                    isUnlocked: true,
                    progress: 30
                ),
                size: 80
            )
            
            // Locked example
            AchievementIconView(
                achievement: Achievement(
                    id: "test_locked",
                    name: "Test Locked",
                    description: "Test",
                    category: .streak,
                    rarity: .epic,
                    iconName: "flame.fill",
                    imageName: "achievement_streak_30",
                    requirement: 30,
                    xpReward: 100,
                    isUnlocked: false,
                    progress: 10
                ),
                size: 80
            )
        }
    }
    .padding()
}

#Preview("Trophies") {
    VStack(spacing: 20) {
        Text("Trofeos").font(.headline)
        
        HStack(spacing: 16) {
            // Unlocked gold
            TrophyIconView(
                trophy: Trophy(
                    id: "test_gold",
                    name: "Test Gold",
                    description: "Test",
                    iconName: "trophy.fill",
                    imageName: "trophy_gold_master",
                    tier: .gold,
                    requirement: .totalCompletions(500),
                    isUnlocked: true
                ),
                size: 80
            )
            
            // Locked diamond
            TrophyIconView(
                trophy: Trophy(
                    id: "test_diamond",
                    name: "Test Diamond",
                    description: "Test",
                    iconName: "crown.fill",
                    imageName: "trophy_diamond_legend",
                    tier: .diamond,
                    requirement: .level(10),
                    isUnlocked: false
                ),
                size: 80
            )
        }
    }
    .padding()
}
