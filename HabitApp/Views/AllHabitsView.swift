//
//  AllHabitsView.swift
//  HabitApp
//
//  Created by Aula03 on 3/12/25.
//

import SwiftUI

struct AllHabitsView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared

    @State private var selectedIcon: String? = nil
    @State private var selectedDay: String? = nil

    private let dayOptions: [String] = ["Todos", "L", "M", "X", "J", "V", "S", "D", "Diario"]

    private var filteredHabits: [Habit] {
        store.habits.filter { habit in
            if let day = selectedDay {
                if day == "Diario" {
                    return habit.frequency.contains("Diario")
                }
                if day != "Todos" {
                    return habit.frequency.contains(day)
                }
            }
            if let icon = selectedIcon {
                if habit.iconName != icon { return false }
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Cabecera con botón de volver
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.appCardBackground(for: colorScheme))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 2)
                }
                .buttonStyle(.plain) // Fix for macOS
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Text(lang.localized("all_habits"))
                .font(.system(size: 26, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Filtro por iconos
            iconFilterBar

            // Filtro por día
            dayFilterBar

            if filteredHabits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text(lang.localized("no_habits_filter"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredHabits) { habit in
                            AllHabitRow(habit: habit)
                                .environmentObject(store)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
    }

    // MARK: - Barra de iconos
    private var iconFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    selectedIcon = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(lang.localized("all"))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedIcon == nil ? Color.cyan : Color.gray.opacity(0.15))
                    .foregroundColor(selectedIcon == nil ? .white : .primary)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain) // Fix for macOS

                ForEach(HabitIcons.all, id: \.self) { icon in
                    Button {
                        selectedIcon = selectedIcon == icon ? nil : icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(selectedIcon == icon ? .white : .cyan)
                            .frame(width: 40, height: 40)
                            .background(selectedIcon == icon ? Color.cyan : Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            .shadow(color: selectedIcon == icon ? Color.cyan.opacity(0.4) : .clear,
                                    radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain) // Fix for macOS
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Barra de días
    private var dayFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dayOptions, id: \.self) { day in
                    Button {
                        if selectedDay == day || day == "Todos" {
                            selectedDay = (day == "Todos" ? nil : day)
                        } else {
                            selectedDay = day
                        }
                    } label: {
                        Text(lang.dayName(for: day))
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDay == day || (day == "Todos" && selectedDay == nil)
                                        ? Color.cyan
                                        : Color.gray.opacity(0.15))
                            .foregroundColor(selectedDay == day || (day == "Todos" && selectedDay == nil)
                                             ? .white
                                             : .primary)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain) // Fix for macOS
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Fila de hábito
struct AllHabitRow: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var lang = LanguageManager.shared
    var habit: Habit

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Image(systemName: habit.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)

                if !habit.description.isEmpty {
                    Text(habit.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("\(lang.localized("frequency_label")): \(frequencyText(for: habit))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                deleteHabit()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(.plain) // Fix for macOS
        }
        .padding()
        .background(Color.appCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 3)
    }

    private func deleteHabit() {
        if let index = store.habits.firstIndex(where: { $0.id == habit.id }) {
            store.removeHabit(at: IndexSet(integer: index))
        }
    }

    private func frequencyText(for habit: Habit) -> String {
        if habit.frequency.contains("Diario") {
            return lang.localized("daily")
        }
        let days = habit.frequency.compactMap { lang.shortDayName(for: $0) }.joined(separator: ", ")
        return days.isEmpty ? lang.localized("no_days") : days
    }
}
