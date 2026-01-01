import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HabitStore
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var appConfig = AppConfig.shared // Añadido AppConfig
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Campos del formulario
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isDaily: Bool = true
    @State private var selectedDays: Set<String> = []
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var selectedIcon: String = "figure.walk"
    
    @State private var iconScrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    @State private var showLimitAlert = false

    // MARK: - Días y iconos disponibles
    private let weekDays = ["L", "M", "X", "J", "V", "S", "D"]
    private let availableIcons = HabitIcons.all

    var body: some View {
        VStack(spacing: 24) {
            
            // MARK: - Título
            Text(lang.localized("new_habit"))
                .font(.system(size: 26, weight: .bold))
                .padding(.top, 12)
            
            if appConfig.isFree {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(lang.localized("habits_count")): \(store.habits.count)/\(appConfig.maxHabits)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Nombre
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.localized("name"))
                            .font(.headline)
                        TextField(lang.localized("name_placeholder"), text: $name)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            #if os(macOS)
                            .textFieldStyle(.plain)
                            #endif
                    }

                    // MARK: - Descripción
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.localized("description"))
                            .font(.headline)
                        TextField(lang.localized("optional"), text: $description, axis: .vertical)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            #if os(macOS)
                            .textFieldStyle(.plain)
                            #endif
                    }

                    // MARK: - Icono
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.localized("icon"))
                            .font(.headline)
                        
                        GeometryReader { geometry in
                            let iconSize: CGFloat = 48
                            let spacing: CGFloat = 12
                            let totalWidth = CGFloat(availableIcons.count) * (iconSize + spacing) - spacing
                            let maxOffset = max(0, totalWidth - geometry.size.width + 32)
                            
                            HStack(spacing: spacing) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: { selectedIcon = icon }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(selectedIcon == icon ? .white : .cyan)
                                            .frame(width: iconSize, height: iconSize)
                                            .background(selectedIcon == icon ? Color.cyan : Color.gray.opacity(0.15))
                                            .cornerRadius(12)
                                            .shadow(color: selectedIcon == icon ? Color.cyan.opacity(0.4) : .clear, radius: 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                            .offset(x: -min(max(0, iconScrollOffset + dragOffset), maxOffset))
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = -value.translation.width
                                    }
                                    .onEnded { value in
                                        iconScrollOffset = min(max(0, iconScrollOffset - value.translation.width), maxOffset)
                                    }
                            )
                            .animation(.interactiveSpring(), value: dragOffset)
                        }
                        .frame(height: 56)
                        .clipped()
                    }

                    // MARK: - Frecuencia
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.localized("frequency"))
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                isDaily = true
                                selectedDays.removeAll()
                            }) {
                                Text(lang.localized("daily"))
                                    .fontWeight(.medium)
                                    .foregroundColor(isDaily ? .white : .primary)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(isDaily ? Color.cyan : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain) // Fix for macOS

                            Button(action: {
                                isDaily = false
                            }) {
                                Text(lang.localized("specific_days"))
                                    .fontWeight(.medium)
                                    .foregroundColor(!isDaily ? .white : .primary)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(!isDaily ? Color.cyan : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain) // Fix for macOS
                        }

                        if !isDaily {
                            HStack(spacing: 10) {
                                ForEach(weekDays, id: \.self) { day in
                                    Button(action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }) {
                                        Text(day)
                                            .fontWeight(.semibold)
                                            .frame(width: 36, height: 36)
                                            .background(selectedDays.contains(day) ? Color.cyan : Color.gray.opacity(0.1))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                            .cornerRadius(18)
                                    }
                                    .buttonStyle(.plain) // Fix for macOS
                                }
                            }
                        }
                    }

                    // MARK: - Recordatorio
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

                    // MARK: - Botón guardar
                    Button(action: saveHabit) {
                        Text(lang.localized("save"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? Color.gray.opacity(0.4) : Color.cyan)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain) // Fix for macOS
                    .disabled(name.isEmpty)
                    .padding(.top, 8)
                }
                .padding(.horizontal)
            }
        }
        .background(Color.appBackground(for: colorScheme))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: hideKeyboard) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.cyan)
                }
            }
        }
        .alert(lang.localized("habit_limit_title"), isPresented: $showLimitAlert) {
            Button(lang.localized("cancel"), role: .cancel) { }
            Button(lang.localized("upgrade_premium")) {
                appConfig.upgradeToPremium()
            }
        } message: {
            Text(lang.localized("habit_limit_message"))
        }
    }

    // MARK: - Save logic
    func saveHabit() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        if appConfig.isFree && store.habits.count >= appConfig.maxHabits {
            showLimitAlert = true
            return
        }

        let newHabit = Habit(
            name: name,
            description: description,
            frequency: isDaily ? ["Diario"] : Array(selectedDays),
            reminderTime: reminderEnabled ? reminderTime : nil,
            iconName: selectedIcon,
            completedDates: [],
            createdAt: Date()
        )

        if appConfig.showAds {
            AdManager.shared.showInterstitialAd {
                store.addHabit(newHabit)
                dismiss()
            }
        } else {
            store.addHabit(newHabit)
            dismiss()
        }
    }
    
    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #elseif os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }
}
