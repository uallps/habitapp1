import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var appConfig = AppConfig.shared
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showHabitsForDay = false
    @State private var showRecap = false
    @State private var selectedRecapPeriod: RecapPeriod = .daily

    private let calendar = Calendar.current
    
    /// Determines if recap section should be shown based on target and settings
    private var showRecapSection: Bool {
        #if PREMIUM
        return true
        #else
        return appConfig.isPremiumUser
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Título
                    Text(lang.localized("progress"))
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if showRecapSection {
                        recapSection
                    }

                    // MARK: - Calendario
                    calendarHeader
                    calendarGrid

                    // MARK: - Estadísticas
                    statisticsSection
                }
                .padding(.bottom, 40)
            }
            .background(Color.appBackground(for: colorScheme))
            .onChange(of: selectedDate) { _, newValue in
                if newValue != nil {
                    showHabitsForDay = true
                }
            }
            .sheet(isPresented: $showHabitsForDay, onDismiss: {
                selectedDate = nil
            }) {
                if let date = selectedDate {
                    HabitsForDayView(date: date)
                        .environmentObject(store)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showRecap) {
                RecapView(period: selectedRecapPeriod)
                    .environmentObject(store)
            }
            #else
            .sheet(isPresented: $showRecap) {
                RecapView(period: selectedRecapPeriod)
                    .environmentObject(store)
            }
            #endif
        }
    }
    
    private var recapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.localized("your_recaps"))
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RecapPeriod.allCases, id: \.self) { period in
                        RecapButton(period: period) {
                            selectedRecapPeriod = period
                            showRecap = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Encabezado del mes
    private var calendarHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(formattedMonth(currentMonth))
                .font(.title3.bold())

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var calendarGrid: some View {
        let weekDayHeaders = ["L", "M", "X", "J", "V", "S", "D"]
        let days = generateDays(for: currentMonth)

        return VStack(spacing: 12) {
            // Días de la semana
            HStack {
                ForEach(weekDayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    if date == Date.distantPast {
                        Color.clear.frame(width: 40, height: 40)
                    } else {
                        CalendarDayCell(
                            date: date,
                            store: store,
                            colorScheme: colorScheme,
                            onTap: {
                                selectedDate = date
                            }
                        )
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
            .padding(.horizontal)
        }
    }

    // MARK: - Estadísticas
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // MES
                VStack(alignment: .leading, spacing: 6) {
                    Text(lang.localized("month_completion"))
                        .foregroundColor(.secondary)
                    Text("\(Int(overallCompletionRate * 100))%")
                        .font(.title2.bold())
                }

                Divider()

                // SEMANA
                VStack(alignment: .leading, spacing: 6) {
                    Text(lang.localized("week_completion"))
                        .foregroundColor(.secondary)
                    Text("\(Int(weeklyCompletionRate * 100))%")
                        .font(.title2.bold())
                }

                Divider()

                // DÍA
                VStack(alignment: .leading, spacing: 6) {
                    Text(lang.localized("day_completion"))
                        .foregroundColor(.secondary)
                    Text("\(Int(dailyCompletionRate * 100))%")
                        .font(.title2.bold())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
            .padding(.horizontal)

            // RACHA
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.localized("longest_streak"))
                    .foregroundColor(.secondary)
                Text("\(longestStreak) \(longestStreak == 1 ? lang.localized("day") : lang.localized("days"))")
                    .font(.title2.bold())
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = lang.dateLocale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func generateDays(for date: Date) -> [Date] {
        var days: [Date] = []
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) + 5) % 7
        days.append(contentsOf: Array(repeating: Date.distantPast, count: weekdayOffset))
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(dayDate)
            }
        }
        return days
    }

    private var overallCompletionRate: Double {
        guard !store.habits.isEmpty else { return 0 }
        let rates = store.habits.map { $0.completionRate(for: currentMonth) }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private var weeklyCompletionRate: Double {
        guard !store.habits.isEmpty else { return 0 }
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let weekStart = calendar.startOfDay(for: weekInterval.start)
        let weekEnd = weekInterval.end

        let rates = store.habits.compactMap { habit -> Double? in
            let creationDay = habit.createdAt.map { calendar.startOfDay(for: $0) } ?? Date.distantPast
            let effectiveStart = max(weekStart, creationDay)
            if effectiveStart >= weekEnd { return nil }
            let activeDays = max(1, calendar.dateComponents([.day], from: effectiveStart, to: weekEnd).day ?? 0)
            let completedThisWeek = habit.completedDates.filter { date in
                date >= weekStart && date < weekEnd
            }.count
            return Double(completedThisWeek) / Double(activeDays)
        }

        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private var dailyCompletionRate: Double {
        guard !store.habits.isEmpty else { return 0 }
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
        let weekdayIndex = calendar.component(.weekday, from: today) - 1
        let todaySymbol = weekdaySymbols[weekdayIndex]

        let habitsForToday = store.habits.filter { habit in
            let creationDay = habit.createdAt.map { calendar.startOfDay(for: $0) } ?? Date.distantPast
            guard todayStart >= creationDay else { return false }
            if habit.frequency.contains("Diario") { return true }
            return habit.frequency.contains(todaySymbol)
        }

        guard !habitsForToday.isEmpty else { return 0 }
        let completedToday = habitsForToday.filter { $0.wasCompleted(on: today) }.count
        return Double(completedToday) / Double(habitsForToday.count)
    }

    private var longestStreak: Int {
        store.habits.map(\.currentStreak).max() ?? 0
    }
}

struct CalendarDayCell: View {
    let date: Date
    let store: HabitStore
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var isCompleted: Bool {
        store.habits.contains { $0.wasCompleted(on: date) }
    }
    
    private var hasMedia: Bool {
        CompletionStore.shared.getCompletions(for: date).contains { $0.hasMedia }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            isCompleted
                            ? Color.cyan
                            : (isToday ? Color.cyan.opacity(0.2) : Color.appBackground(for: colorScheme))
                        )
                )
                .overlay(
                    Circle().stroke(Color.cyan.opacity(isToday ? 0.5 : 0), lineWidth: 2)
                )
                .foregroundColor(isCompleted ? .white : (colorScheme == .dark ? .white : .black.opacity(0.6)))
                .opacity(isCompleted ? 1.0 : 0.4)
            
            if hasMedia {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .offset(x: 14, y: -14)
            }
        }
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
    }
}

struct RecapButton: View {
    let period: RecapPeriod
    let action: () -> Void
    @ObservedObject private var lang = LanguageManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(gradientForPeriod)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: period.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(lang.localized(period.rawValue))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var gradientForPeriod: LinearGradient {
        switch period {
        case .daily:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .weekly:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .monthly:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
