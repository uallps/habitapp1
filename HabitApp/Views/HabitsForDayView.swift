import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Helper struct for image viewer data
struct ImageViewerData: Identifiable {
    let id = UUID()
    #if os(iOS)
    let image: UIImage
    #elseif os(macOS)
    let image: NSImage
    #endif
    let habitName: String
}

// Helper struct for 3D model viewer data
struct Model3DViewerData: Identifiable {
    let id = UUID()
    let url: URL
}

struct HabitsForDayView: View {
    @EnvironmentObject var store: HabitStore
    @ObservedObject private var completionStore = CompletionStore.shared
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared
    let date: Date
    
    @State private var selectedCompletion: HabitCompletion?
    @State private var imageViewerData: ImageViewerData?
    @State private var model3DViewerData: Model3DViewerData?
    @State private var habitToUncomplete: Habit?
    @State private var showUncompleteAlert = false
    #if os(iOS)
    @State private var loadedImages: [UUID: UIImage] = [:]
    #elseif os(macOS)
    @State private var loadedImages: [UUID: NSImage] = [:]
    #endif
    @State private var habitsSnapshot: [Habit] = []

    private var formatter: DateFormatter {
        let df = DateFormatter()
        df.locale = lang.dateLocale
        df.dateStyle = .full
        return df
    }

    private let calendar = Calendar.current

    private func getHabitsForDate() -> [Habit] {
        store.habits.filter { habit in
            let creationDay = habit.createdAt.map { calendar.startOfDay(for: $0) } ?? Date.distantPast
            let targetDay = calendar.startOfDay(for: date)
            guard targetDay >= creationDay else { return false }

            if habit.frequency.contains("Diario") { return true }

            let weekdaySymbols = ["D", "L", "M", "X", "J", "V", "S"]
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let daySymbol = weekdaySymbols[weekdayIndex]

            return habit.frequency.contains(daySymbol)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(formatter.string(from: date).capitalized)
                .font(.title3.bold())
                .padding(.top)

            if habitsSnapshot.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text(lang.localized("no_habits_scheduled"))
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(habitsSnapshot) { habit in
                            HabitDayCard(
                                habit: habit,
                                date: date,
                                completionStore: completionStore,
                                loadedImages: $loadedImages,
                                onUncomplete: {
                                    habitToUncomplete = habit
                                    showUncompleteAlert = true
                                },
                                onViewImage: { image, name in
                                    imageViewerData = ImageViewerData(image: image, habitName: name)
                                },
                                onViewModel3D: { url in
                                    model3DViewerData = Model3DViewerData(url: url)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(Color.appBackground(for: colorScheme))
        .onAppear {
            habitsSnapshot = getHabitsForDate()
        }
        .sheet(item: $imageViewerData) { data in
            ImageViewerSheet(image: data.image, habitName: data.habitName, date: date)
        }
        .sheet(item: $model3DViewerData) { data in
            Model3DViewer(modelURL: data.url)
        }
        .alert(lang.localized("uncomplete_habit"), isPresented: $showUncompleteAlert, presenting: habitToUncomplete) { habit in
            Button(lang.localized("cancel"), role: .cancel) {}
            Button(lang.localized("uncomplete"), role: .destructive) {
                store.uncompleteHabit(habit, on: date)
                habitsSnapshot = getHabitsForDate()
            }
        } message: { habit in
            Text(lang.localized("uncomplete_habit_message"))
        }
    }
}

struct HabitDayCard: View {
    let habit: Habit
    let date: Date
    let completionStore: CompletionStore
    #if os(iOS)
    @Binding var loadedImages: [UUID: UIImage]
    let onUncomplete: () -> Void
    let onViewImage: (UIImage, String) -> Void
    let onViewModel3D: (URL) -> Void
    #elseif os(macOS)
    @Binding var loadedImages: [UUID: NSImage]
    let onUncomplete: () -> Void
    let onViewImage: (NSImage, String) -> Void
    let onViewModel3D: (URL) -> Void
    #endif
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared
    
    private var completion: HabitCompletion? {
        completionStore.getCompletion(for: habit.id, on: date)
    }
    
    private var isCompleted: Bool {
        habit.wasCompleted(on: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: habit.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? .green : .gray)
                    .frame(width: 44, height: 44)
                    .background((isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)

                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isCompleted {
                    Button(action: onUncomplete) {
                        Text(lang.localized("completed"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(lang.localized("not_completed"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let note = completion?.note, !note.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(note)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.leading, 56)
            }
            
            if let completion = completion, completion.hasMedia {
                MediaPreviewButton(
                    completion: completion,
                    habitName: habit.name,
                    completionStore: completionStore,
                    loadedImages: $loadedImages,
                    onViewImage: onViewImage,
                    onViewModel3D: onViewModel3D
                )
            }
        }
        .padding()
        .background(Color.appCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

struct MediaPreviewButton: View {
    let completion: HabitCompletion
    let habitName: String
    let completionStore: CompletionStore
    #if os(iOS)
    @Binding var loadedImages: [UUID: UIImage]
    let onViewImage: (UIImage, String) -> Void
    #elseif os(macOS)
    @Binding var loadedImages: [UUID: NSImage]
    let onViewImage: (NSImage, String) -> Void
    #endif
    let onViewModel3D: (URL) -> Void
    
    @ObservedObject private var lang = LanguageManager.shared
    @State private var isLoading = false
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                ThumbnailView(completion: completion, loadedImages: $loadedImages)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(completion.mediaType == .image ? lang.localized("view_photo") : lang.localized("view_3d_model"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(lang.localized("tap_to_view"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
            .padding(.leading, 56)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
    
    private func handleTap() {
        if completion.mediaType == .image {
            if let cached = loadedImages[completion.id] {
                onViewImage(cached, habitName)
            } else {
                isLoading = true
                Task {
                    if let image = await completionStore.loadImageAsync(for: completion) {
                        await MainActor.run {
                            loadedImages[completion.id] = image
                            isLoading = false
                            onViewImage(image, habitName)
                        }
                    } else {
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                }
            }
        } else if completion.mediaType == .model3D {
            if let url = completionStore.getModel3DURL(for: completion) {
                onViewModel3D(url)
            }
        }
    }
}

struct ThumbnailView: View {
    let completion: HabitCompletion
    #if os(iOS)
    @Binding var loadedImages: [UUID: UIImage]
    @State private var image: UIImage?
    #elseif os(macOS)
    @Binding var loadedImages: [UUID: NSImage]
    @State private var image: NSImage?
    #endif
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if completion.mediaType == .image {
                if let img = image ?? loadedImages[completion.id] {
                    #if os(iOS)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                    #elseif os(macOS)
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(10)
                    #endif
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .task {
                        await loadThumbnail()
                    }
                }
            } else {
                // 3D Model thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "cube.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    private func loadThumbnail() async {
        guard completion.mediaType == .image else {
            isLoading = false
            return
        }
        
        if let loaded = await CompletionStore.shared.loadImageAsync(for: completion) {
            await MainActor.run {
                image = loaded
                loadedImages[completion.id] = loaded
                isLoading = false
            }
        } else {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
