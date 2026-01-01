import SwiftUI

struct HabitCardView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var appConfig = AppConfig.shared

    var habit: Habit
    
    @State private var showCompletionSheet = false

    var body: some View {
        HStack(spacing: 16) {
            // Icono circular
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Image(systemName: habit.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }

            // Texto principal
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(lang.localized("streak")): \(habit.currentStreak) \(habit.currentStreak == 1 ? lang.localized("day") : lang.localized("days"))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Botón completar
            Button {
                if store.isCompletedToday(habit) {
                    store.toggleHabitCompletion(habit)
                } else {
                    if appConfig.showAds {
                        AdManager.shared.showInterstitialAd {
                            store.toggleHabitCompletion(habit)
                            // Show completion sheet for Premium users
                            if appConfig.canAddNotes {
                                showCompletionSheet = true
                            }
                        }
                    } else {
                        store.toggleHabitCompletion(habit)
                        if appConfig.canAddNotes {
                            showCompletionSheet = true
                        }
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(store.isCompletedToday(habit) ? Color.cyan : Color.cyan.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: store.isCompletedToday(habit) ? "checkmark" : "circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(store.isCompletedToday(habit) ? .white : .cyan)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCompletionSheet) {
                HabitCompletionSheet(habit: habit)
                    .environmentObject(store)
            }

            // Botón eliminar
            Button {
                if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
                    store.removeHabit(at: IndexSet(integer: index))
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.appCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 3)
    }
}
