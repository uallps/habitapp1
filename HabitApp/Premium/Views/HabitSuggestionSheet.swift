//
//  HabitSuggestionSheet.swift
//  HabitApp
//
//  Sheet to display and confirm AI-suggested habit
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct HabitSuggestionSheet: View {
    let suggestion: HabitSuggestion
    #if os(iOS)
    let originalImage: UIImage?
    #elseif os(macOS)
    let originalImage: NSImage?
    #endif
    let onConfirm: (Habit) -> Void
    let onCancel: () -> Void
    
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Editable fields
    @State private var habitName: String
    @State private var habitDescription: String
    @State private var selectedIcon: String
    @State private var isDaily: Bool
    @State private var selectedDays: Set<String>
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    private let weekDays = ["L", "M", "X", "J", "V", "S", "D"]
    
    #if os(iOS)
    init(suggestion: HabitSuggestion, originalImage: UIImage?, onConfirm: @escaping (Habit) -> Void, onCancel: @escaping () -> Void) {
        self.suggestion = suggestion
        self.originalImage = originalImage
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        _habitName = State(initialValue: suggestion.name)
        _habitDescription = State(initialValue: suggestion.description)
        _selectedIcon = State(initialValue: suggestion.iconName)
        
        let daily = suggestion.frequency.contains("Diario")
        _isDaily = State(initialValue: daily)
        _selectedDays = State(initialValue: daily ? [] : Set(suggestion.frequency))
    }
    #elseif os(macOS)
    init(suggestion: HabitSuggestion, originalImage: NSImage?, onConfirm: @escaping (Habit) -> Void, onCancel: @escaping () -> Void) {
        self.suggestion = suggestion
        self.originalImage = originalImage
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        _habitName = State(initialValue: suggestion.name)
        _habitDescription = State(initialValue: suggestion.description)
        _selectedIcon = State(initialValue: suggestion.iconName)
        
        let daily = suggestion.frequency.contains("Diario")
        _isDaily = State(initialValue: daily)
        _selectedDays = State(initialValue: daily ? [] : Set(suggestion.frequency))
    }
    #endif
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Detection Result Header
                    VStack(spacing: 12) {
                        if let image = originalImage {
                            #if os(iOS)
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cyan, lineWidth: 3)
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                            #elseif os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cyan, lineWidth: 3)
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                            #endif
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                            Text(lang.localized("detected"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(suggestion.detectedObject.capitalized)
                            .font(.system(size: 22, weight: .bold))
                        
                        // Confidence indicator
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                Circle()
                                    .fill(Double(index) < suggestion.confidence * 5 ? Color.cyan : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                            Text("\(Int(suggestion.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Suggested Habit Form
                    VStack(alignment: .leading, spacing: 20) {
                        // Category Badge
                        HStack {
                            Image(systemName: suggestion.category.icon)
                                .foregroundColor(.white)
                            Text(lang.localized("category_\(suggestion.category.rawValue)"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .cornerRadius(20)
                        
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.localized("name"))
                                .font(.headline)
                            TextField(lang.localized("name_placeholder"), text: $habitName)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.localized("description"))
                                .font(.headline)
                            TextField(lang.localized("optional"), text: $habitDescription, axis: .vertical)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .lineLimit(3...6)
                        }
                        
                        // Icon Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.localized("icon"))
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(HabitIcons.all, id: \.self) { icon in
                                        Button {
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.system(size: 22))
                                                .foregroundColor(selectedIcon == icon ? .white : .cyan)
                                                .frame(width: 48, height: 48)
                                                .background(selectedIcon == icon ? Color.cyan : Color.gray.opacity(0.15))
                                                .cornerRadius(12)
                                                .shadow(color: selectedIcon == icon ? Color.cyan.opacity(0.4) : .clear, radius: 3)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Frequency
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lang.localized("frequency"))
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                Button {
                                    isDaily = true
                                    selectedDays.removeAll()
                                } label: {
                                    Text(lang.localized("daily"))
                                        .fontWeight(.medium)
                                        .foregroundColor(isDaily ? .white : .primary)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(isDaily ? Color.cyan : Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    isDaily = false
                                } label: {
                                    Text(lang.localized("specific_days"))
                                        .fontWeight(.medium)
                                        .foregroundColor(!isDaily ? .white : .primary)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(!isDaily ? Color.cyan : Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if !isDaily {
                                HStack(spacing: 10) {
                                    ForEach(weekDays, id: \.self) { day in
                                        Button {
                                            if selectedDays.contains(day) {
                                                selectedDays.remove(day)
                                            } else {
                                                selectedDays.insert(day)
                                            }
                                        } label: {
                                            Text(day)
                                                .fontWeight(.semibold)
                                                .frame(width: 36, height: 36)
                                                .background(selectedDays.contains(day) ? Color.cyan : Color.gray.opacity(0.1))
                                                .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                                .cornerRadius(18)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Reminder
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.localized("reminder"))
                                .font(.headline)
                            
                            HStack {
                                Text(lang.localized("time"))
                                Spacer()
                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .disabled(!reminderEnabled)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            
                            Toggle(lang.localized("enable_reminder"), isOn: $reminderEnabled)
                                .tint(.cyan)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            createHabit()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text(lang.localized("create_habit"))
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(habitName.isEmpty ? Color.gray : Color.cyan)
                            .cornerRadius(14)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(habitName.isEmpty)
                        
                        Button {
                            onCancel()
                        } label: {
                            Text(lang.localized("cancel"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.appBackground(for: colorScheme))
            .navigationTitle(lang.localized("suggested_habit"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                #endif
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func createHabit() {
        let habit = Habit(
            name: habitName,
            description: habitDescription,
            frequency: isDaily ? ["Diario"] : Array(selectedDays),
            reminderTime: reminderEnabled ? reminderTime : nil,
            iconName: selectedIcon,
            completedDates: [],
            createdAt: Date()
        )
        onConfirm(habit)
    }
}

#Preview {
    HabitSuggestionSheet(
        suggestion: HabitSuggestion(
            name: "Leer 20 páginas",
            description: "Dedica tiempo cada día a la lectura",
            category: .learning,
            iconName: "book.fill",
            frequency: ["Diario"],
            confidence: 0.85,
            detectedObject: "book"
        ),
        originalImage: nil,
        onConfirm: { _ in },
        onCancel: {}
    )
}
