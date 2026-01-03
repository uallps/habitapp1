import SwiftUI

struct SettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var appConfig = AppConfig.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showGamificationHub = false

    var body: some View {
        #if os(macOS)
        macOSSettingsView
        #else
        iOSSettingsView
        #endif
    }
    
    // MARK: - iOS Settings
    #if os(iOS)
    private var iOSSettingsView: some View {
        Form {
            // ---------- APARIENCIA ----------
            Section(header: Text(languageManager.localized("appearance"))) {
                Picker(languageManager.localized("appearance_mode"), selection: $appConfig.appearanceMode) {
                    Text(languageManager.localized("appearance_light")).tag(AppearanceMode.light)
                    Text(languageManager.localized("appearance_dark")).tag(AppearanceMode.dark)
                    Text(languageManager.localized("appearance_auto")).tag(AppearanceMode.auto)
                }
                .pickerStyle(.segmented)
            }

            // ---------- IDIOMA ----------
            Section(header: Text(languageManager.localized("language"))) {
                Picker(languageManager.localized("language"), selection: $languageManager.language) {
                    Text(languageManager.localized("spanish")).tag("es")
                    Text(languageManager.localized("english")).tag("en")
                }
                .pickerStyle(.segmented)
            }

            // ---------- PLANES ----------
            #if !PREMIUM
            Section(header: Text(languageManager.localized("plans"))) {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            planCard(
                                title: languageManager.localized("normal"),
                                price: "0€",
                                subtitle: languageManager.localized("free_plan"),
                                isPremiumPlan: false,
                                isActive: !appConfig.isPremium,
                                buttonTitle: !appConfig.isPremium ? languageManager.localized("active_plan") : languageManager.localized("change"),
                                buttonAction: { appConfig.downgradeToFree() },
                                width: geo.size.width * 0.85
                            )

                            planCard(
                                title: languageManager.localized("premium"),
                                price: "PRO",
                                subtitle: languageManager.localized("unlock_all"),
                                isPremiumPlan: true,
                                isActive: appConfig.isPremium,
                                buttonTitle: appConfig.isPremium ? languageManager.localized("active_plan") : languageManager.localized("change"),
                                buttonAction: { appConfig.upgradeToPremium() },
                                width: geo.size.width * 0.85
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .frame(height: 480)
            }
            #endif
            
            // ---------- GAMIFICACIÓN (Premium) ----------
            if PremiumFeatures.isEnabled {
                Section(header: Text("🎮 \(languageManager.localized("gamification"))")) {
                    Button {
                        showGamificationHub = true
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "trophy.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageManager.localized("game_center"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(languageManager.localized("gamification_subtitle"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // XP Badge
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(GamificationStore.shared.profile.totalXP) XP")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.purple)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.purple.opacity(0.15), in: Capsule())
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // ---------- VERSIÓN DE LA APP ----------
            appVersionSection
        }
        .navigationTitle(languageManager.localized("settings"))
        .sheet(isPresented: $showGamificationHub) {
            GamificationHubView()
        }
    }
    #endif
    
    // MARK: - macOS Settings
    #if os(macOS)
    private var macOSSettingsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text(languageManager.localized("settings"))
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                
                // Settings Cards
                VStack(spacing: 20) {
                    // Appearance Card
                    macOSSettingsCard(title: languageManager.localized("appearance"), icon: "paintbrush.fill", iconColor: .purple) {
                        HStack(spacing: 12) {
                            ForEach([AppearanceMode.light, AppearanceMode.dark, AppearanceMode.auto], id: \.self) { mode in
                                macOSAppearanceButton(mode: mode)
                            }
                        }
                    }
                    
                    // Language Card
                    macOSSettingsCard(title: languageManager.localized("language"), icon: "globe", iconColor: .blue) {
                        HStack(spacing: 12) {
                            macOSLanguageButton(language: "es", flag: "🇪🇸", name: languageManager.localized("spanish"))
                            macOSLanguageButton(language: "en", flag: "🇬🇧", name: languageManager.localized("english"))
                        }
                    }
                    
                    // Plans Card
                    #if !PREMIUM
                    macOSSettingsCard(title: languageManager.localized("plans"), icon: "star.fill", iconColor: .orange) {
                        HStack(spacing: 20) {
                            planCard(
                                title: languageManager.localized("normal"),
                                price: "0€",
                                subtitle: languageManager.localized("free_plan"),
                                isPremiumPlan: false,
                                isActive: !appConfig.isPremium,
                                buttonTitle: !appConfig.isPremium ? languageManager.localized("active_plan") : languageManager.localized("change"),
                                buttonAction: { appConfig.downgradeToFree() },
                                width: 280
                            )
                            
                            planCard(
                                title: languageManager.localized("premium"),
                                price: "PRO",
                                subtitle: languageManager.localized("unlock_all"),
                                isPremiumPlan: true,
                                isActive: appConfig.isPremium,
                                buttonTitle: appConfig.isPremium ? languageManager.localized("active_plan") : languageManager.localized("change"),
                                buttonAction: { appConfig.upgradeToPremium() },
                                width: 280
                            )
                        }
                    }
                    #endif
                    
                    // Gamification Card (Premium)
                    if PremiumFeatures.isEnabled {
                        macOSSettingsCard(title: "🎮 \(languageManager.localized("gamification"))", icon: "trophy.fill", iconColor: .purple) {
                            Button {
                                showGamificationHub = true
                            } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(languageManager.localized("game_center"))
                                            .font(.headline)
                                        Text(languageManager.localized("gamification_subtitle"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                        Text("\(GamificationStore.shared.profile.totalXP) XP")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.purple.opacity(0.2), in: Capsule())
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.1), .indigo.opacity(0.1)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // App Info Card
                    macOSSettingsCard(title: languageManager.localized("app_version"), icon: "info.circle.fill", iconColor: .cyan) {
                        macOSAppInfoContent
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
            }
        }
        .background(Color.appBackground(for: colorScheme))
        .sheet(isPresented: $showGamificationHub) {
            GamificationHubView()
        }
    }
    
    private func macOSSettingsCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title3.bold())
            }
            
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
        )
    }
    
    private func macOSAppearanceButton(mode: AppearanceMode) -> some View {
        let isSelected = appConfig.appearanceMode == mode
        let icon: String = {
            switch mode {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .auto: return "circle.lefthalf.filled"
            }
        }()
        let title: String = {
            switch mode {
            case .light: return languageManager.localized("appearance_light")
            case .dark: return languageManager.localized("appearance_dark")
            case .auto: return languageManager.localized("appearance_auto")
            }
        }()
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                appConfig.appearanceMode = mode
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(width: 80, height: 70)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cyan : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func macOSLanguageButton(language: String, flag: String, name: String) -> some View {
        let isSelected = languageManager.language == language
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                languageManager.language = language
            }
        } label: {
            HStack(spacing: 10) {
                Text(flag)
                    .font(.title2)
                Text(name)
                    .font(.body.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cyan : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var macOSAppInfoContent: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localized("app_name"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if PREMIUM
                    Text("HabitApp Premium")
                        .font(.headline)
                        .foregroundStyle(Color.orange)
                    #else
                    Text(appConfig.isPremium ? "HabitApp Premium" : "HabitApp")
                        .font(.headline)
                        .foregroundStyle(appConfig.isPremium ? Color.orange : Color.primary)
                    #endif
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(languageManager.localized("version"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("1.0")
                        .font(.headline)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localized("current_plan"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if PREMIUM
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.orange)
                        Text("Premium")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.orange)
                    }
                    #else
                    if appConfig.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.orange)
                            Text("Premium")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.orange)
                        }
                    } else {
                        Text("Free")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    #endif
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if PREMIUM
                    Text("HabitAppPremium")
                        .font(.caption.weight(.medium))
                    #else
                    Text("HabitApp")
                        .font(.caption.weight(.medium))
                    #endif
                }
            }
        }
    }
    #endif
    
    // MARK: - Shared App Version Section
    private var appVersionSection: some View {
        Section(header: Text(languageManager.localized("app_version"))) {
            // App Name
            HStack {
                Text(languageManager.localized("app_name"))
                Spacer()
                #if PREMIUM
                Text("HabitApp Premium")
                    .foregroundStyle(Color.orange)
                    .fontWeight(.semibold)
                #else
                Text(appConfig.isPremium ? "HabitApp Premium" : "HabitApp")
                    .foregroundStyle(appConfig.isPremium ? Color.orange : Color.primary)
                    .fontWeight(.semibold)
                #endif
            }
            
            // Target/Build Type
            HStack {
                Text("Target")
                Spacer()
                #if PREMIUM
                Text("HabitAppPremium")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                #else
                Text("HabitApp")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                #endif
            }
            
            // Current Plan
            HStack {
                Text(languageManager.localized("current_plan"))
                Spacer()
                #if PREMIUM
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.orange)
                        .font(.caption)
                    Text("Premium")
                        .foregroundStyle(Color.orange)
                        .fontWeight(.semibold)
                }
                #else
                if appConfig.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.orange)
                            .font(.caption)
                        Text("Premium")
                            .foregroundStyle(Color.orange)
                            .fontWeight(.semibold)
                    }
                } else {
                    Text("Free")
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                #endif
            }
            
            // Version Number
            HStack {
                Text(languageManager.localized("version"))
                Spacer()
                Text("1.0")
                    .foregroundStyle(.secondary)
            }
            
            // Features list based on current plan
            #if PREMIUM
            premiumFeaturesView
            #else
            if appConfig.isPremium {
                premiumFeaturesView
            } else {
                freeLimitsView
            }
            #endif
        }
    }
    
    // MARK: - Features Views
    private var freeLimitsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.localized("free_limits"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.orange)
                Text("\(languageManager.localized("max_habits")): \(appConfig.maxHabits)")
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(.orange)
                Text(languageManager.localized("basic_statistics"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
                Text(languageManager.localized("no_ai_camera"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
                Text(languageManager.localized("no_recaps"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "megaphone")
                    .foregroundStyle(.orange)
                Text(languageManager.localized("shows_ads"))
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private var premiumFeaturesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.localized("premium_benefits"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "infinity")
                    .foregroundStyle(.green)
                Text(languageManager.localized("unlimited_habits"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.green)
                Text(languageManager.localized("ai_camera_feature"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.green)
                Text(languageManager.localized("recaps_feature"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.green)
                Text(languageManager.localized("habit_notes"))
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "nosign")
                    .foregroundStyle(.green)
                Text(languageManager.localized("no_ads"))
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    // MARK: - TARJETA DE PLAN
    private func planCard(
        title: String,
        price: String,
        subtitle: String,
        isPremiumPlan: Bool,
        isActive: Bool,
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        width: CGFloat
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.title2.bold())
                        if isPremiumPlan {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(isPremiumPlan ? .orange : .primary)

                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Funcionalidades con iconos
            VStack(alignment: .leading, spacing: 10) {
                if isPremiumPlan {
                    planFeatureRow(icon: "infinity", text: languageManager.localized("unlimited_habits"), color: .green)
                    planFeatureRow(icon: "camera.viewfinder", text: languageManager.localized("ai_camera_feature"), color: .green)
                    planFeatureRow(icon: "chart.bar.doc.horizontal", text: languageManager.localized("recaps_feature"), color: .green)
                    planFeatureRow(icon: "note.text", text: languageManager.localized("habit_notes"), color: .green)
                    planFeatureRow(icon: "nosign", text: languageManager.localized("no_ads"), color: .green)
                    planFeatureRow(icon: "chart.xyaxis.line", text: languageManager.localized("advanced_statistics"), color: .green)
                } else {
                    planFeatureRow(icon: "list.bullet", text: "\(languageManager.localized("max_habits")): 5", color: .orange)
                    planFeatureRow(icon: "chart.bar.xaxis", text: languageManager.localized("basic_statistics"), color: .orange)
                    planFeatureRow(icon: "xmark.circle", text: languageManager.localized("no_ai_camera"), color: .red)
                    planFeatureRow(icon: "xmark.circle", text: languageManager.localized("no_recaps"), color: .red)
                    planFeatureRow(icon: "megaphone", text: languageManager.localized("shows_ads"), color: .red)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()

            // Botón
            Button(buttonTitle) {
                buttonAction()
            }
            .buttonStyle(.plain)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? Color.gray.opacity(0.3) : (isPremiumPlan ? Color.orange : Color.cyan))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(isActive)
        }
        .padding(22)
        .frame(width: width)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(isActive ? (isPremiumPlan ? Color.orange.opacity(0.15) : Color.cyan.opacity(0.18)) : Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(isActive ? (isPremiumPlan ? Color.orange : Color.cyan) : Color.primary.opacity(0.12), lineWidth: isActive ? 2 : 1)
        )
    }
    
    private func planFeatureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.callout)
        }
    }
}
