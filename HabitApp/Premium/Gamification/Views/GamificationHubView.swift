//
//  GamificationHubView.swift
//  HabitApp
//
//  Vista principal del sistema de gamificación - El centro de juego
//

import SwiftUI

@MainActor
struct GamificationHubView: View {
    @StateObject private var store = GamificationStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var selectedTab: GamificationTab = .profile
    @State private var showDailyReward = false
    @State private var claimedReward: DailyReward?
    @Namespace private var animation
    @Environment(\.dismiss) private var dismiss
    
    enum GamificationTab: String, CaseIterable {
        case profile
        case achievements
        case trophies
        case rewards
        
        var icon: String {
            switch self {
            case .profile: return "person.crop.circle.fill"
            case .achievements: return "medal.fill"
            case .trophies: return "trophy.fill"
            case .rewards: return "gift.fill"
            }
        }
        
        var localizationKey: String {
            switch self {
            case .profile: return "profile"
            case .achievements: return "achievements"
            case .trophies: return "trophies"
            case .rewards: return "rewards"
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }
    
    // MARK: - iOS Body
    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        ProfileTabView(store: store)
                            .tag(GamificationTab.profile)
                        
                        AchievementsTabView(store: store)
                            .tag(GamificationTab.achievements)
                        
                        TrophyRoomView(store: store)
                            .tag(GamificationTab.trophies)
                        
                        DailyRewardsView(store: store)
                            .tag(GamificationTab.rewards)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("🎮 \(lang.localized("game_center"))")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    xpIndicator
                }
            }
        }
        .modifier(GamificationAlertModifier(store: store))
    }
    #endif
    
    // MARK: - macOS Body
    #if os(macOS)
    private var macOSBody: some View {
        ZStack {
            // Solid gradient background for better visibility
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle accent overlay
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.08),
                    Color.indigo.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar with tabs
                macOSSidebar
                
                Divider()
                
                // Main content area
                VStack(spacing: 0) {
                    // Header bar
                    macOSHeader
                    
                    Divider()
                    
                    // Content
                    Group {
                        switch selectedTab {
                        case .profile:
                            ProfileTabView(store: store)
                        case .achievements:
                            AchievementsTabView(store: store)
                        case .trophies:
                            TrophyRoomView(store: store)
                        case .rewards:
                            DailyRewardsView(store: store)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, minHeight: 650, idealHeight: 700)
        .modifier(GamificationAlertModifier(store: store))
    }
    
    private var macOSSidebar: some View {
        VStack(spacing: 0) {
            // Logo/Title
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                
                Text(lang.localized("game_center"))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Navigation items
            VStack(spacing: 8) {
                ForEach(GamificationTab.allCases, id: \.self) { tab in
                    macOSSidebarButton(tab)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // XP Display at bottom
            VStack(spacing: 8) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("\(store.profile.level.id)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                Text("\(lang.localized("level")) \(store.profile.level.name)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                // XP
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(store.profile.totalXP)")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.purple)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 200)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.08), Color.indigo.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func macOSSidebarButton(_ tab: GamificationTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(lang.localized(tab.localizationKey))
                    .font(.subheadline.weight(.medium))
                
                Spacer()
            }
            .foregroundStyle(selectedTab == tab ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .matchedGeometryEffect(id: "sidebar", in: animation)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var macOSHeader: some View {
        HStack {
            // Tab title with icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(lang.localized(selectedTab.localizationKey))
                    .font(.title2.weight(.bold))
            }
            
            Spacer()
            
            // XP indicator with better styling
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.callout)
                
                Text("\(store.profile.totalXP)")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("XP")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }
    #endif
    
    // MARK: - Shared Components
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.1),
                Color.blue.opacity(0.1),
                Color.indigo.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GamificationTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
    
    private func tabButton(_ tab: GamificationTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(lang.localized(tab.localizationKey))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selectedTab == tab ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .matchedGeometryEffect(id: "TAB", in: animation)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - XP Indicator
    private var xpIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
            
            Text("\(store.profile.totalXP)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            
            Text("XP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Gamification Alert Modifier
struct GamificationAlertModifier: ViewModifier {
    @ObservedObject var store: GamificationStore
    
    func body(content: Content) -> some View {
        content
            .alert("🎉 ¡Subiste de nivel!", isPresented: $store.showLevelUpAlert) {
                Button("¡Genial!") { }
            } message: {
                if let level = store.newLevel {
                    Text("Has alcanzado el nivel \(level.id): \(level.name)")
                }
            }
            .alert("🏆 ¡Logro desbloqueado!", isPresented: $store.showAchievementAlert) {
                Button("¡Increíble!") { }
            } message: {
                if let achievement = store.lastUnlockedAchievement {
                    Text("\(achievement.name)\n+\(achievement.xpReward) XP")
                }
            }
            .alert("🏅 ¡Nuevo trofeo!", isPresented: $store.showTrophyAlert) {
                Button("¡Asombroso!") { }
            } message: {
                if let trophy = store.lastUnlockedTrophy {
                    Text("\(trophy.name)\n+\(trophy.tier.xpBonus) XP")
                }
            }
    }
}

// MARK: - Profile Tab View
@MainActor
struct ProfileTabView: View {
    @ObservedObject var store: GamificationStore
    @ObservedObject private var lang = LanguageManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Level Card
                levelCard
                
                // Stats Grid
                statsGrid
                
                // Recent XP Events
                recentXPSection
            }
            .padding()
        }
    }
    
    // MARK: - Level Card
    private var levelCard: some View {
        VStack(spacing: 16) {
            // Level icon and name
            HStack(spacing: 16) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple, .blue, .indigo],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: store.profile.level.iconName)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                .shadow(color: .purple.opacity(0.5), radius: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(lang.localized("level")) \(store.profile.level.id)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(store.profile.level.name)
                        .font(.title.weight(.bold))
                    
                    Text("\(store.profile.totalXP) \(lang.localized("total_xp"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Progress to next level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(lang.localized("progress_next_level"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(store.profile.xpProgress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.purple)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * store.profile.xpProgress)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(store.profile.level.minXP) XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if store.profile.level.id < 10 {
                        Text("\(store.profile.level.maxXP) XP")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("¡Nivel máximo!")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                #if os(macOS)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.indigo.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                #else
                .fill(.ultraThinMaterial)
                #endif
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: lang.localized("total_completions"),
                value: "\(store.profile.totalCompletions)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: lang.localized("max_streak"),
                value: "\(store.profile.maxStreak) \(lang.localized("days"))",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: lang.localized("achievements"),
                value: "\(store.achievementStats.unlocked)/\(store.achievementStats.total)",
                icon: "medal.fill",
                color: .yellow
            )
            
            StatCard(
                title: lang.localized("trophies"),
                value: "\(store.trophyStats.unlocked)/\(store.trophyStats.total)",
                icon: "trophy.fill",
                color: .purple
            )
            
            StatCard(
                title: lang.localized("daily") + " Login",
                value: "\(store.profile.dailyLoginStreak) \(lang.localized("days"))",
                icon: "calendar.badge.checkmark",
                color: .blue
            )
            
            StatCard(
                title: lang.localized("current_streak"),
                value: "\(store.profile.currentStreak) \(lang.localized("days"))",
                icon: "bolt.fill",
                color: .cyan
            )
        }
    }
    
    // MARK: - Recent XP Section
    private var recentXPSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.localized("recent_history") + " XP")
                .font(.headline)
            
            if store.recentXPEvents.isEmpty {
                Text(lang.localized("no_rewards_yet"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(store.recentXPEvents.prefix(5)) { event in
                    HStack {
                        Image(systemName: event.isBonus ? "star.fill" : "plus.circle.fill")
                            .foregroundStyle(event.isBonus ? .yellow : .green)
                        
                        Text(event.reason)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("+\(event.amount) XP")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(event.isBonus ? .yellow : .green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        #if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        #endif
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.weight(.bold))
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        #if os(macOS)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        #else
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        #endif
    }
}

// MARK: - Preview
#Preview {
    GamificationHubView()
}
