import Foundation
import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}

class AppConfig: ObservableObject {
    
    static let shared = AppConfig()
    
    // MARK: - App Version Type
    enum AppVersion: String {
        case free
        case premium
    }
    
    /// Whether the app is built as the Premium target
    static var isPremiumTarget: Bool {
        #if PREMIUM
        return true
        #else
        return false
        #endif
    }
    
    @Published var isPremiumUser: Bool {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: "isPremium")
        }
    }
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    private init() {
        #if PREMIUM
        // Premium target is always premium
        self.isPremiumUser = true
        #else
        self.isPremiumUser = UserDefaults.standard.bool(forKey: "isPremium")
        #endif
        
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .auto
        }
    }
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil // nil means follow system
        }
    }
    
    // Determina la versión basándose en el target o UserDefaults
    var currentVersion: AppVersion {
        #if PREMIUM
        return .premium
        #else
        return isPremiumUser ? .premium : .free
        #endif
    }
    
    var isPremium: Bool {
        #if PREMIUM
        return true
        #else
        return isPremiumUser
        #endif
    }
    
    var isFree: Bool {
        #if PREMIUM
        return false
        #else
        return !isPremiumUser
        #endif
    }
    
    // MARK: - App Info
    var appName: String {
        #if PREMIUM
        return "HabitApp Premium"
        #else
        return isPremiumUser ? "HabitApp Premium" : "HabitApp"
        #endif
    }
    
    var bundleIdentifier: String {
        #if PREMIUM
        return "ual.HabitAppPremium"
        #else
        return isPremiumUser ? "ual.HabitAppPremium" : "ual.HabitApp"
        #endif
    }
    
    // MARK: - Feature Limits
    
    // Límite de hábitos
    var maxHabits: Int {
        isPremium ? Int.max : 5
    }
    
    // Acceso a estadísticas avanzadas
    var hasAdvancedStatistics: Bool {
        isPremium
    }
    
    // Acceso a temas personalizados
    var hasCustomThemes: Bool {
        isPremium
    }
    
    // Acceso a exportar datos
    var canExportData: Bool {
        isPremium
    }
    
    // Acceso a notificaciones ilimitadas
    var hasUnlimitedNotifications: Bool {
        isPremium
    }
    
    // Mostrar anuncios
    var showAds: Bool {
        #if PREMIUM
        return false
        #else
        return !isPremiumUser
        #endif
    }
    
    // Acceso a iconos premium
    var hasPremiumIcons: Bool {
        isPremium
    }
    
    // Acceso a backup en la nube
    var hasCloudBackup: Bool {
        isPremium
    }
    
    var canAddNotes: Bool {
        isPremium
    }
    
    // Acceso a cámara IA para crear hábitos
    var hasCameraFeature: Bool {
        isPremium
    }
    
    // MARK: - Methods
    
    func upgradeToPremium() {
        isPremiumUser = true
    }
    
    func downgradeToFree() {
        isPremiumUser = false
    }
    
    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
    }
}
