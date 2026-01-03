import SwiftUI

enum RecapPeriod: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}

struct RecapView: View {
    @EnvironmentObject var store: HabitStore
    @ObservedObject private var completionStore = CompletionStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let period: RecapPeriod
    
    @State private var currentPage = 0
    @State private var timer: Timer?
    @State private var progress: CGFloat = 0
    
    private let storyDuration: TimeInterval = 5.0
    private var totalPages: Int { 4 }
    
    private var dateRange: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .weekly:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return DateInterval(start: start, end: end)
        case .monthly:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient based on page
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bars
                    progressBars
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: closeRecap) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Content
                    #if os(macOS)
                    // macOS: Use custom paging
                    Group {
                        switch currentPage {
                        case 0: welcomeStory
                        case 1: statsStory
                        case 2: highlightsStory
                        case 3: summaryStory
                        default: welcomeStory
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    #else
                    TabView(selection: $currentPage) {
                        welcomeStory.tag(0)
                        statsStory.tag(1)
                        highlightsStory.tag(2)
                        summaryStory.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                }
                
                // Tap areas for navigation
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { previousPage() }
                    
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { nextPage() }
                }
                
                // Navigation arrows for macOS
                #if os(macOS)
                HStack {
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button(action: nextPage) {
                        Image(systemName: currentPage < totalPages - 1 ? "chevron.right" : "checkmark")
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 30)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .onChange(of: currentPage) { _, _ in
            restartTimer()
        }
    }
    
    private func closeRecap() {
        stopTimer()
        dismiss()
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        let colors: [Color] = {
            switch currentPage {
            case 0: return [Color.cyan, Color.blue]
            case 1: return [Color.purple, Color.pink]
            case 2: return [Color.orange, Color.red]
            case 3: return [Color.green, Color.cyan]
            default: return [Color.cyan, Color.blue]
            }
        }()
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    // MARK: - Progress Bars
    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalPages, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: progressWidth(for: index, totalWidth: geo.size.width))
                    }
                }
                .frame(height: 3)
            }
        }
    }
    
    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentPage {
            return totalWidth
        } else if index == currentPage {
            return totalWidth * progress
        } else {
            return 0
        }
    }
    
    // MARK: - Stories
    private var welcomeStory: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: period.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text(lang.localized("your_\(period.rawValue)_recap"))
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text(periodDateString)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private var statsStory: some View {
        let calendar = Calendar.current
        let totalHabits = store.habits.count
        
        // Calculate completion rate properly
        let rate: Double = {
            guard totalHabits > 0 else { return 0 }
            
            _ = daysInPeriod
            let completionsPerDay = completionStore.getUniqueCompletionsPerDay(in: dateRange)
            
            var totalPossible = 0
            var totalCompleted = 0
            
            // For each day in the period
            var currentDate = dateRange.start
            while currentDate < dateRange.end && currentDate <= Date() {
                totalPossible += totalHabits
                totalCompleted += completionsPerDay[calendar.startOfDay(for: currentDate)]?.count ?? 0
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            guard totalPossible > 0 else { return 0 }
            
            let calculatedRate = Double(totalCompleted) / Double(totalPossible) * 100
            return min(calculatedRate, 100.0)
        }()
        
        let completedCount = completionStore.getCompletedHabitsCount(in: dateRange)
        
        return VStack(spacing: 32) {
            Spacer()
            
            Text(lang.localized("your_progress"))
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(Int(rate))%")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(lang.localized("completion_rate"))
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 40) {
                statItem(value: "\(completedCount)", label: lang.localized("completed"))
                statItem(value: "\(totalHabits)", label: lang.localized("habits"))
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var highlightsStory: some View {
        let featuredCompletions = completionStore.getFeaturedImages(in: dateRange, limit: 4)
        let imageCount = completionStore.getMediaCount(in: dateRange, type: .image)
        let model3DCount = completionStore.getMediaCount(in: dateRange, type: .model3D)
        
        return VStack(spacing: 24) {
            Spacer()
            
            Text(lang.localized("highlights"))
                .font(.title.bold())
                .foregroundColor(.white)
            
            if featuredCompletions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(lang.localized("no_media_yet"))
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(featuredCompletions.prefix(4)) { completion in
                        if let image = completionStore.loadImage(for: completion) {
                            #if os(iOS)
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(16)
                            #elseif os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(16)
                            #endif
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Media count with proper breakdown
            VStack(spacing: 4) {
                if imageCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                        Text("\(imageCount) \(imageCount == 1 ? lang.localized("photo") : lang.localized("photos"))")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                }
                
                if model3DCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "cube.fill")
                            .font(.caption)
                        Text("\(model3DCount) \(model3DCount == 1 ? lang.localized("3d_model") : lang.localized("3d_models"))")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                
                if imageCount == 0 && model3DCount == 0 {
                    Text(lang.localized("no_media_yet"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    private var summaryStory: some View {
        let longestStreak = store.habits.map(\.currentStreak).max() ?? 0
        
        return VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text(lang.localized("keep_going"))
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text(lang.localized("longest_streak"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(longestStreak) \(longestStreak == 1 ? lang.localized("day") : lang.localized("days"))")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
            }
            
            Text(lang.localized("recap_motivation"))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helpers
    private var periodDateString: String {
        let formatter = DateFormatter()
        formatter.locale = lang.dateLocale
        
        switch period {
        case .daily:
            formatter.dateFormat = "EEEE, d MMMM"
            return formatter.string(from: Date())
        case .weekly:
            formatter.dateFormat = "d MMM"
            let start = formatter.string(from: dateRange.start)
            let end = formatter.string(from: dateRange.end.addingTimeInterval(-86400))
            return "\(start) - \(end)"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: Date())
        }
    }
    
    private var daysInPeriod: Int {
        switch period {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation {
                progress += 0.05 / storyDuration
            }
            
            if progress >= 1 {
                nextPage()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func restartTimer() {
        progress = 0
        stopTimer()
        startTimer()
    }
    
    private func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
                progress = 0
            }
        } else {
            dismiss()
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
                progress = 0
            }
        }
    }
}
