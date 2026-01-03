//
//  AchievementsTabView.swift
//  HabitApp
//
//  Vista de logros con diseño de juego - Colección de medallas y badges
//

import SwiftUI

@MainActor
struct AchievementsTabView: View {
    @ObservedObject var store: GamificationStore
    @State private var selectedCategory: AchievementCategory?
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header stats
                achievementStats
                
                // Category filter
                categoryFilter
                
                // Achievement grid
                achievementGrid
            }
            .padding()
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }
    
    // MARK: - Achievement Stats
    private var achievementStats: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(store.achievementStats.unlocked)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Desbloqueados")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(height: 50)
            
            VStack {
                Text("\(store.achievementStats.total - store.achievementStats.unlocked)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray)
                
                Text("Por desbloquear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(height: 50)
            
            VStack {
                let percentage = Double(store.achievementStats.unlocked) / Double(max(store.achievementStats.total, 1)) * 100
                Text("\(Int(percentage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                
                Text("Completado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All categories button
                categoryButton(nil, name: "Todos", icon: "square.grid.2x2.fill")
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    categoryButton(category, name: category.displayName, icon: category.icon)
                }
            }
        }
    }
    
    private func categoryButton(_ category: AchievementCategory?, name: String, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(name)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selectedCategory == category {
                    Capsule()
                        .fill(category?.color ?? Color.purple)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        let filtered = selectedCategory == nil 
            ? store.achievements 
            : store.achievements(for: selectedCategory!)
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filtered) { achievement in
                AchievementCard(achievement: achievement)
                    .onTapGesture {
                        selectedAchievement = achievement
                    }
            }
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            // Achievement icon using the new component
            AchievementIconView(achievement: achievement, size: 70)
            
            // Name
            Text(achievement.name)
                .font(.caption2.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
            
            // Progress bar (if not unlocked)
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progressPercentage)
                    .progressViewStyle(.linear)
                    .tint(achievement.category.color)
                    .frame(width: 50)
            }
            
            // Rarity indicator
            Text(achievement.rarity.displayName)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(achievement.rarity.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(achievement.rarity.color.opacity(0.2), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay {
                    if achievement.isUnlocked && achievement.rarity.glowIntensity > 0 {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(achievement.rarity.color.opacity(0.5), lineWidth: 1)
                    }
                }
        }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large achievement icon using the new component
                    AchievementIconView(achievement: achievement, size: 150)
                        .shadow(color: achievement.isUnlocked ? achievement.rarity.color.opacity(0.5) : .clear, radius: 20)
                    
                    // Achievement info
                    VStack(spacing: 8) {
                        Text(achievement.name)
                            .font(.title.weight(.bold))
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Category & Rarity
                        HStack(spacing: 12) {
                            Label(achievement.category.displayName, systemImage: achievement.category.icon)
                                .font(.caption)
                                .foregroundStyle(achievement.category.color)
                            
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text(achievement.rarity.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(achievement.rarity.color)
                        }
                        .padding(.top, 4)
                    }
                    
                    // XP Reward
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        
                        Text("+\(achievement.xpReward) XP")
                            .font(.headline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.yellow.opacity(0.2), in: Capsule())
                    
                    // Progress section
                    VStack(spacing: 12) {
                        Text("Progreso")
                            .font(.headline)
                        
                        if achievement.isUnlocked {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                
                                Text("¡Completado!")
                                    .foregroundStyle(.green)
                                
                                if let date = achievement.unlockedDate {
                                    Text("el \(date.formatted(date: .abbreviated, time: .omitted))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                ProgressView(value: achievement.progressPercentage)
                                    .progressViewStyle(.linear)
                                    .tint(achievement.rarity.color)
                                    .frame(height: 8)
                                
                                Text("\(achievement.progress) / \(achievement.requirement)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Detalle del Logro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            #endif
        }
    }
}

// MARK: - Preview
#Preview {
    AchievementsTabView(store: GamificationStore.shared)
}
