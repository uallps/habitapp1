//
//  TrophyRoomView.swift
//  HabitApp
//
//  Sala de trofeos - Colección de trofeos épicos con diseño de vitrina
//

import SwiftUI

@MainActor
struct TrophyRoomView: View {
    @ObservedObject var store: GamificationStore
    @State private var selectedTier: TrophyTier?
    @State private var selectedTrophy: Trophy?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trophy room header
                trophyRoomHeader
                
                // Tier selector
                tierSelector
                
                // Trophy showcase
                trophyShowcase
            }
            .padding()
        }
        .sheet(item: $selectedTrophy) { trophy in
            TrophyDetailSheet(trophy: trophy)
        }
    }
    
    // MARK: - Trophy Room Header
    private var trophyRoomHeader: some View {
        VStack(spacing: 12) {
            // Decorative trophy cabinet
            ZStack {
                // Cabinet background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brown.opacity(0.3),
                                Color.brown.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                
                // Shelves
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.brown.opacity(0.4))
                        .frame(height: 4)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.brown.opacity(0.4))
                        .frame(height: 4)
                }
                .frame(height: 120)
                
                // Trophies on display
                HStack(spacing: 24) {
                    ForEach(TrophyTier.allCases, id: \.self) { tier in
                        let unlockedCount = store.trophies(for: tier).filter { $0.isUnlocked }.count
                        let totalCount = store.trophies(for: tier).count
                        
                        VStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.title)
                                .foregroundStyle(
                                    unlockedCount > 0 ? tier.color : Color.gray.opacity(0.3)
                                )
                                .shadow(color: unlockedCount > 0 ? tier.color.opacity(0.5) : .clear, radius: 5)
                            
                            Text("\(unlockedCount)/\(totalCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(store.trophyStats.unlocked)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Trofeos obtenidos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(store.trophyStats.total - store.trophyStats.unlocked)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                    
                    Text("Por conseguir")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Tier Selector
    private var tierSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All tiers button
                tierButton(nil, name: "Todos")
                
                ForEach(TrophyTier.allCases, id: \.self) { tier in
                    tierButton(tier, name: tier.displayName)
                }
            }
        }
    }
    
    private func tierButton(_ tier: TrophyTier?, name: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTier = tier
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(tier?.color ?? .purple)
                
                Text(name)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(selectedTier == tier ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selectedTier == tier {
                    Capsule()
                        .fill(tier?.color ?? Color.purple)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Trophy Showcase
    private var trophyShowcase: some View {
        let filtered = selectedTier == nil
            ? store.trophies
            : store.trophies(for: selectedTier!)
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filtered) { trophy in
                TrophyCard(trophy: trophy)
                    .onTapGesture {
                        selectedTrophy = trophy
                    }
            }
        }
    }
}

// MARK: - Trophy Card
struct TrophyCard: View {
    let trophy: Trophy
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Trophy pedestal
            ZStack {
                // Base
                Ellipse()
                    .fill(Color.brown.opacity(0.3))
                    .frame(width: 100, height: 20)
                    .offset(y: 40)
                
                // Trophy using the new component
                TrophyIconView(trophy: trophy, size: 80)
                    .scaleEffect(trophy.isUnlocked && isAnimating ? 1.05 : 1.0)
            }
            .frame(height: 90)
            
            // Trophy info
            VStack(spacing: 4) {
                Text(trophy.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(trophy.isUnlocked ? .primary : .secondary)
                
                // Tier badge
                Text(trophy.tier.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(trophy.isUnlocked ? trophy.tier.color : Color.gray, in: Capsule())
                
                // XP Bonus
                if trophy.isUnlocked {
                    Text("+\(trophy.tier.xpBonus) XP")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    if trophy.isUnlocked {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [trophy.tier.color.opacity(0.5), trophy.tier.color.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                }
        }
        .onAppear {
            if trophy.isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Trophy Detail Sheet
struct TrophyDetailSheet: View {
    let trophy: Trophy
    @Environment(\.dismiss) private var dismiss
    @State private var isShining = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Large trophy display
                    ZStack {
                        // Pedestal
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // Pedestal top
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.brown, .brown.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 180, height: 20)
                            
                            // Pedestal body
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.brown.opacity(0.8), .brown.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 160, height: 40)
                        }
                        .frame(height: 260)
                        
                        // Trophy using the new component
                        VStack {
                            TrophyIconView(trophy: trophy, size: 140)
                                .scaleEffect(trophy.isUnlocked && isShining ? 1.05 : 1.0)
                                .shadow(color: trophy.isUnlocked ? trophy.tier.color.opacity(0.5) : .clear, radius: 20)
                            
                            Spacer()
                        }
                        .frame(height: 260)
                    }
                    .frame(height: 260)
                    
                    // Trophy info
                    VStack(spacing: 12) {
                        Text(trophy.name)
                            .font(.title.weight(.bold))
                        
                        Text(trophy.tier.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(trophy.tier.color, in: Capsule())
                        
                        Text(trophy.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Requirement
                    VStack(spacing: 8) {
                        Text("Requisito")
                            .font(.headline)
                        
                        Text(trophy.requirement.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // XP Bonus
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        
                        Text("+\(trophy.tier.xpBonus) XP Bonus")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                    }
                    .padding()
                    .background(.yellow.opacity(0.15), in: Capsule())
                    
                    // Status
                    if trophy.isUnlocked {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            Text("¡Conseguido!")
                                .foregroundStyle(.green)
                            
                            if let date = trophy.unlockedDate {
                                Text("el \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    } else {
                        Text("🔒 Aún no conseguido")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Detalle del Trofeo")
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
            .onAppear {
                if trophy.isUnlocked {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isShining = true
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TrophyRoomView(store: GamificationStore.shared)
}
