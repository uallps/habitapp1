//
//  DailyRewardsView.swift
//  HabitApp
//
//  Vista de recompensas diarias - Sistema de login diario con calendario semanal
//

import SwiftUI

@MainActor
struct DailyRewardsView: View {
    @ObservedObject var store: GamificationStore
    @State private var showClaimAnimation = false
    @State private var claimedRewardInfo: ClaimedRewardInfo?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con streak info
                dailyStreakHeader
                
                // Calendario semanal
                weeklyCalendar
                
                // Claim button
                claimButton
                
                // Próximas recompensas
                upcomingRewards
                
                // Historial reciente
                recentHistory
            }
            .padding()
        }
        .overlay {
            if showClaimAnimation, let rewardInfo = claimedRewardInfo {
                RewardClaimAnimation(rewardInfo: rewardInfo) {
                    showClaimAnimation = false
                    claimedRewardInfo = nil
                }
            }
        }
    }
    
    // MARK: - Daily Streak Header
    private var dailyStreakHeader: some View {
        VStack(spacing: 16) {
            // Fire streak icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .orange.opacity(0.5), radius: 20)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 4) {
                Text("\(store.profile.loginStreak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Días consecutivos")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Bonus info
            if store.profile.loginStreak >= 7 {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    
                    Text("¡Bonus x\(min(store.profile.loginStreak / 7, 4) + 1) activo!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.15), in: Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Weekly Calendar
    private var weeklyCalendar: some View {
        VStack(spacing: 16) {
            Text("Esta semana")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset - getDayOfWeek(), to: Date()) ?? Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let isPast = date < Calendar.current.startOfDay(for: Date())
                    let isClaimed = store.hasClaimedReward(for: date)
                    
                    DayRewardCell(
                        date: date,
                        isToday: isToday,
                        isPast: isPast,
                        isClaimed: isClaimed,
                        dayNumber: dayOffset + 1
                    )
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Claim Button
    private var claimButton: some View {
        Button {
            claimDailyReward()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: store.canClaimDailyReward ? "gift.fill" : "checkmark.circle.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.canClaimDailyReward ? "Reclamar recompensa" : "Recompensa reclamada")
                        .font(.headline)
                    
                    if store.canClaimDailyReward {
                        Text("+\(calculateTodayReward()) XP")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    } else {
                        Text("Vuelve mañana")
                            .font(.caption)
                            .opacity(0.8)
                    }
                }
                
                Spacer()
                
                if store.canClaimDailyReward {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        store.canClaimDailyReward
                            ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!store.canClaimDailyReward)
    }
    
    // MARK: - Upcoming Rewards
    private var upcomingRewards: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Próximas recompensas")
                    .font(.headline)
                
                Spacer()
                
                Text("Días consecutivos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 10) {
                UpcomingRewardRow(days: 7, reward: "50 XP Bonus", icon: "star.fill", color: .yellow, achieved: store.profile.loginStreak >= 7)
                UpcomingRewardRow(days: 14, reward: "100 XP + Badge", icon: "medal.fill", color: .orange, achieved: store.profile.loginStreak >= 14)
                UpcomingRewardRow(days: 30, reward: "250 XP + Trofeo", icon: "trophy.fill", color: .purple, achieved: store.profile.loginStreak >= 30)
                UpcomingRewardRow(days: 100, reward: "1000 XP + Legendario", icon: "crown.fill", color: .yellow, achieved: store.profile.loginStreak >= 100)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Recent History
    private var recentHistory: some View {
        VStack(spacing: 16) {
            Text("Historial reciente")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if store.recentRewards.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("Aún no has reclamado recompensas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(store.recentRewards.prefix(5)) { reward in
                    HStack {
                        Circle()
                            .fill(reward.bonusMultiplier > 1 ? Color.yellow : Color.green)
                            .frame(width: 10, height: 10)
                        
                        Text(reward.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if reward.bonusMultiplier > 1 {
                            Text("x\(reward.bonusMultiplier)")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.yellow.opacity(0.2), in: Capsule())
                        }
                        
                        Text("+\(reward.xpEarned) XP")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                    
                    if reward.id != store.recentRewards.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Helper Methods
    private func getDayOfWeek() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Adjust for Monday start (weekday 1 = Sunday, 2 = Monday, etc.)
        return weekday == 1 ? 6 : weekday - 2
    }
    
    private func calculateTodayReward() -> Int {
        // Calcular qué recompensa toca basado en la racha de login
        let dayIndex = max(0, (store.profile.dailyLoginStreak - 1)) % 7
        let baseRewards = [5, 10, 15, 20, 25, 30, 50]
        let baseXP = dayIndex < baseRewards.count ? baseRewards[dayIndex] : 25
        
        // Multiplicador por racha
        let streakMultiplier = max(1, (store.profile.loginStreak / 7) + 1)
        return baseXP * streakMultiplier
    }
    
    private func claimDailyReward() {
        guard store.canClaimDailyReward else { return }
        
        print("[DailyRewardsView] Claiming daily reward...")
        
        if let reward = store.claimDailyReward() {
            let streakDay = store.profile.dailyLoginStreak
            let bonusMultiplier = max(1, streakDay / 7 + 1)
            let xpEarned = reward.xpReward * bonusMultiplier
            
            print("[DailyRewardsView] Reward claimed - XP: \(xpEarned), day: \(streakDay)")
            
            claimedRewardInfo = ClaimedRewardInfo(
                xpEarned: xpEarned,
                streakDay: streakDay,
                bonusMultiplier: bonusMultiplier
            )
            
            withAnimation(.spring(response: 0.3)) {
                showClaimAnimation = true
            }
        } else {
            print("[DailyRewardsView] Failed to claim reward")
        }
    }
}

// MARK: - Day Reward Cell
struct DayRewardCell: View {
    let date: Date
    let isToday: Bool
    let isPast: Bool
    let isClaimed: Bool
    let dayNumber: Int
    
    private let weekdaySymbols = ["L", "M", "X", "J", "V", "S", "D"]
    
    var body: some View {
        VStack(spacing: 6) {
            Text(weekdaySymbols[dayNumber - 1])
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                if isToday {
                    Circle()
                        .stroke(Color.purple, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                if isClaimed {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else if isPast {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red.opacity(0.7))
                } else {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundStyle(isToday ? .purple : .gray)
                }
            }
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .foregroundStyle(isToday ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundColor: Color {
        if isClaimed {
            return .green
        } else if isPast {
            return .red.opacity(0.2)
        } else if isToday {
            return .purple.opacity(0.2)
        } else {
            return .gray.opacity(0.2)
        }
    }
}

// MARK: - Upcoming Reward Row
struct UpcomingRewardRow: View {
    let days: Int
    let reward: String
    let icon: String
    let color: Color
    let achieved: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(achieved ? color : color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(achieved ? .white : color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(days) días")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(achieved ? .primary : .secondary)
                
                Text(reward)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if achieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("🔒")
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Claimed Reward Info
struct ClaimedRewardInfo {
    let xpEarned: Int
    let streakDay: Int
    let bonusMultiplier: Int
}

// MARK: - Reward Claim Animation
struct RewardClaimAnimation: View {
    let rewardInfo: ClaimedRewardInfo
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showSparkles = false
    @State private var xpCountUp = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 30) {
                // Gift box
                ZStack {
                    // Sparkles
                    ForEach(0..<12, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 10...20)))
                            .foregroundStyle([.yellow, .orange, .pink, .purple].randomElement()!)
                            .offset(
                                x: showSparkles ? CGFloat.random(in: -100...100) : 0,
                                y: showSparkles ? CGFloat.random(in: -100...100) : 0
                            )
                            .opacity(showSparkles ? 0 : 1)
                    }
                    
                    // Gift icon
                    Image(systemName: "gift.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 20)
                }
                
                // XP earned
                VStack(spacing: 8) {
                    Text("¡Recompensa diaria!")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text("+\(xpCountUp) XP")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                    
                    if rewardInfo.bonusMultiplier > 1 {
                        Text("Bonus x\(rewardInfo.bonusMultiplier)")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Día \(rewardInfo.streakDay) de racha")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Continue button
                Button {
                    onDismiss()
                } label: {
                    Text("¡Genial!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.purple, in: Capsule())
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1).delay(0.3)) {
                showSparkles = true
            }
            
            // XP count up animation
            let steps = 20
            let stepValue = rewardInfo.xpEarned / steps
            for i in 0..<steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    xpCountUp = min((i + 1) * stepValue, rewardInfo.xpEarned)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DailyRewardsView(store: GamificationStore.shared)
}
