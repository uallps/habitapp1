import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var appConfig = AppConfig.shared
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedTab = 0
    @State private var showingAddHabit = false
    @State private var selectedIconFilter: String? = nil
    @StateObject private var inAppNotifier = InAppNotificationManager.shared
    private let calendar = Calendar.current
    
    /// Determines if camera AI feature should be shown based on target, settings and module availability
    private var showCameraFeature: Bool {
        #if PREMIUM
        return ModuleRegistry.shared.hasAIHabitModule
        #else
        return appConfig.hasCameraFeature && ModuleRegistry.shared.hasAIHabitModule
        #endif
    }
    
    private var habitsForToday: [Habit] {
        let today = Date()
        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayIndex = calendar.component(.weekday, from: today) - 1
        let todaySymbol = weekdaySymbols[weekdayIndex]

        return store.habits.filter { habit in
            if habit.frequency.contains("Diario") { return true }
            return habit.frequency.contains(todaySymbol)
        }
    }

    var body: some View {
        ZStack {
            #if os(macOS)
            // macOS: Use custom floating tab bar
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case 0:
                        habitsTab
                    case 1:
                        if showCameraFeature, let aiModule = ModuleRegistry.shared.aiHabitModule {
                            aiModule.cameraView()
                        } else {
                            StatisticsView()
                        }
                    case 2:
                        if showCameraFeature {
                            StatisticsView()
                        } else {
                            SettingsView()
                        }
                    case 3:
                        SettingsView()
                    default:
                        habitsTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Floating tab bar for macOS
                macOSFloatingTabBar
                    .padding(.bottom, 20)
            }
            #else
            // iOS: Use native TabView
            TabView(selection: $selectedTab) {
                habitsTab
                    .tabItem {
                        VStack {
                            Image(systemName: "checkmark.circle")
                            Text(lang.localized("habits"))
                        }
                    }
                    .tag(0)

                if showCameraFeature, let aiModule = ModuleRegistry.shared.aiHabitModule {
                    aiModule.cameraView()
                        .tabItem {
                            VStack {
                                Image(systemName: "camera.fill")
                                Text(lang.localized("ai_camera"))
                            }
                        }
                        .tag(1)
                }

                StatisticsView()
                    .tabItem {
                        VStack {
                            Image(systemName: "chart.bar.xaxis")
                            Text(lang.localized("progress"))
                        }
                    }
                    .tag(showCameraFeature ? 2 : 1)

                SettingsView()
                    .tabItem {
                        VStack {
                            Image(systemName: "gearshape")
                            Text(lang.localized("settings"))
                        }
                    }
                    .tag(showCameraFeature ? 3 : 2)
            }
            .accentColor(Color.cyan)
            #endif
            
            if inAppNotifier.showBanner {
                BannerView(
                    title: inAppNotifier.bannerTitle,
                    message: inAppNotifier.bannerMessage
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .preferredColorScheme(appConfig.colorScheme)
    }
    
    #if os(macOS)
    private var macOSFloatingTabBar: some View {
        HStack(spacing: 8) {
            macOSTabButton(icon: "checkmark.circle", title: lang.localized("habits"), tag: 0)
            
            if showCameraFeature {
                macOSTabButton(icon: "camera.fill", title: lang.localized("ai_camera"), tag: 1)
                macOSTabButton(icon: "chart.bar.xaxis", title: lang.localized("progress"), tag: 2)
                macOSTabButton(icon: "gearshape", title: lang.localized("settings"), tag: 3)
            } else {
                macOSTabButton(icon: "chart.bar.xaxis", title: lang.localized("progress"), tag: 1)
                macOSTabButton(icon: "gearshape", title: lang.localized("settings"), tag: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 20, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func macOSTabButton(icon: String, title: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedTab == tag ? icon + ".fill" : icon)
                    .font(.system(size: 16, weight: .medium))
                if selectedTab == tag {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundColor(selectedTab == tag ? .white : .primary.opacity(0.7))
            .padding(.horizontal, selectedTab == tag ? 16 : 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedTab == tag {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyan)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    #endif

    private var habitsTab: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 16) { // LazyVStack for performance
                        Text(lang.localized("habits"))
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 20)

                        HStack {
                            NavigationLink {
                                AllHabitsView()
                                    .environmentObject(store)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet.rectangle")
                                    Text(lang.localized("view_all_habits"))
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.cyan.opacity(0.15))
                                .foregroundColor(Color.cyan)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)

                        if store.habits.isEmpty {
                            emptyStateView
                        } else {
                            iconFilterBar

                            if filteredHabitsForToday.isEmpty {
                                Text(lang.localized("no_habits_icon"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }

                            ForEach(filteredHabitsForToday) { habit in
                                HabitCardView(habit: habit)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .background(Color.appBackground(for: colorScheme))

                Button(action: {
                    showingAddHabit.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 65, height: 65)
                        .background(Color.cyan)
                        .clipShape(Circle())
                        .shadow(color: Color.cyan.opacity(0.4), radius: 10)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
                .sheet(isPresented: $showingAddHabit) {
                    AddHabitView(store: store)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(Color.cyan.opacity(0.8))
            }

            VStack(spacing: 6) {
                Text(lang.localized("no_habits_yet"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text(lang.localized("create_first_habit"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            Button {
                showingAddHabit.toggle()
            } label: {
                Label(lang.localized("create_habit"), systemImage: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.cyan)
            .cornerRadius(30)
            .shadow(color: Color.cyan.opacity(0.4), radius: 6)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredHabits: [Habit] {
        if let icon = selectedIconFilter {
            return store.habits.filter { $0.iconName == icon }
        }
        return store.habits
    }
    
    private var filteredHabitsForToday: [Habit] {
        let todayHabits = habitsForToday
        if let icon = selectedIconFilter {
            return todayHabits.filter { $0.iconName == icon }
        }
        return todayHabits
    }

    private var iconFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    selectedIconFilter = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(lang.localized("all"))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedIconFilter == nil ? Color.cyan : Color.gray.opacity(0.15))
                    .foregroundColor(selectedIconFilter == nil ? .white : .primary)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)

                ForEach(HabitIcons.all, id: \.self) { icon in
                    Button {
                        selectedIconFilter = selectedIconFilter == icon ? nil : icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(selectedIconFilter == icon ? .white : .cyan)
                            .frame(width: 40, height: 40)
                            .background(selectedIconFilter == icon ? Color.cyan : Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            .shadow(color: selectedIconFilter == icon ? Color.cyan.opacity(0.4) : .clear,
                                    radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore.shared)
}
