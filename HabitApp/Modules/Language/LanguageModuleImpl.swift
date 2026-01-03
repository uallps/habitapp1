//
//  LanguageModuleImpl.swift
//  HabitApp
//
//  Módulo de Multilengüaje - Implementación
//  Autor: Nieto
//  
//  Este módulo gestiona la internacionalización de la aplicación
//  con soporte para múltiples idiomas. Se inyecta mediante Protocol + DI.
//

import SwiftUI
import Combine

// MARK: - Language Module Implementation
@MainActor
final class LanguageModuleImpl: LanguageModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.language"
    static var moduleName: String = "Language Module"
    static var moduleAuthor: String = "Nieto"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set(true, forKey: "user_set_language")
            currentLocale = Locale(identifier: currentLanguage)
            languageSubject.send(currentLanguage)
        }
    }
    
    @Published private(set) var currentLocale: Locale
    
    // MARK: - Publishers
    private let languageSubject = PassthroughSubject<String, Never>()
    var languagePublisher: AnyPublisher<String, Never> {
        languageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Protocol Properties
    var supportedLanguages: [String] {
        return ["es", "en"]
    }
    
    // MARK: - Translations Dictionary
    private let translations: [String: [String: String]]
    
    // MARK: - Initialization
    init() {
        // Cargar idioma guardado o detectar del sistema
        let userHasSetLanguage = UserDefaults.standard.bool(forKey: "user_set_language")
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language")
        
        let initialLanguage: String
        if userHasSetLanguage, let saved = savedLanguage {
            initialLanguage = saved
        } else {
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "es"
            initialLanguage = (systemLanguage == "en") ? "en" : "es"
            UserDefaults.standard.set(initialLanguage, forKey: "app_language")
        }
        
        self.currentLanguage = initialLanguage
        self.currentLocale = Locale(identifier: initialLanguage)
        
        // Inicializar traducciones
        self.translations = Self.loadTranslations()
        
        print("[\(Self.moduleName)] Module instance created with language: \(initialLanguage)")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        print("[\(Self.moduleName)] Supported languages: \(supportedLanguages)")
        print("[\(Self.moduleName)] Current language: \(currentLanguage)")
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        isEnabled = false
    }
    
    // MARK: - Localization
    func localized(_ key: String) -> String {
        return translations[currentLanguage]?[key] 
            ?? translations["es"]?[key] 
            ?? key
    }
    
    func setLanguage(_ language: String) {
        guard supportedLanguages.contains(language) else {
            print("[\(Self.moduleName)] Language '\(language)' not supported")
            return
        }
        
        print("[\(Self.moduleName)] Changing language to: \(language)")
        currentLanguage = language
    }
    
    // MARK: - Translations Loader
    private static func loadTranslations() -> [String: [String: String]] {
        // Las traducciones están definidas aquí para mantener el módulo autocontenido
        // En producción, podrían cargarse de archivos .strings o .json
        return [
            "es": [
                // General
                "habits": "Hábitos",
                "progress": "Progreso",
                "settings": "Ajustes",
                "save": "Guardar",
                "cancel": "Cancelar",
                "delete": "Eliminar",
                "all": "Todos",
                "daily": "Diario",
                "skip": "Omitir",
                "ok": "OK",
                "error": "Error",
                "unknown_error": "Error desconocido",
                "completed": "Completado",
                "not_completed": "No completado",
                
                // ContentView
                "view_all_habits": "Ver todos los hábitos",
                "no_habits_yet": "Aún no tienes hábitos",
                "create_first_habit": "Crea tu primer hábito para empezar a construir tu mejor versión.",
                "create_habit": "Crear hábito",
                
                // AddHabitView
                "new_habit": "Nuevo hábito",
                "name": "Nombre",
                "name_placeholder": "Ej: Leer 15 minutos",
                "description": "Descripción",
                "optional": "Opcional",
                "icon": "Icono",
                "frequency": "Frecuencia",
                "specific_days": "Días específicos",
                "reminder": "Recordatorio",
                "time": "Hora",
                "enable_reminder": "Activar recordatorio",
                
                // Days
                "monday": "Lunes",
                "tuesday": "Martes",
                "wednesday": "Miércoles",
                "thursday": "Jueves",
                "friday": "Viernes",
                "saturday": "Sábado",
                "sunday": "Domingo",
                "all_days": "Todos los días",
                "dailies": "Diarios",
                
                // Settings
                "appearance": "Apariencia",
                "appearance_mode": "Modo de apariencia",
                "appearance_light": "Claro",
                "appearance_dark": "Oscuro",
                "appearance_auto": "Auto",
                "dark_mode": "Modo oscuro",
                "language": "Idioma",
                "spanish": "Español",
                "english": "English",
                "plans": "Planes",
                "normal": "Normal",
                "premium": "Premium",
                "free_plan": "Plan gratuito",
                "unlock_all": "Desbloquea todo",
                "active_plan": "Plan activo",
                "change": "Cambiar",
                
                // AI Camera
                "ai_camera": "Cámara IA",
                "ai_camera_title": "Crear hábito con IA",
                "ai_camera_subtitle": "Toma una foto de algo que te inspire a crear un nuevo hábito",
                "take_photo": "Tomar foto",
                "choose_gallery": "Elegir de galería",
                "analyzing": "Analizando imagen...",
                
                // Recaps
                "recap_daily": "Resumen del día",
                "recap_weekly": "Resumen semanal",
                "recap_monthly": "Resumen mensual",
                "recap_title": "Tu progreso",
                "recap_completed": "Completados",
                "recap_streak": "Mejor racha",
            ],
            "en": [
                // General
                "habits": "Habits",
                "progress": "Progress",
                "settings": "Settings",
                "save": "Save",
                "cancel": "Cancel",
                "delete": "Delete",
                "all": "All",
                "daily": "Daily",
                "skip": "Skip",
                "ok": "OK",
                "error": "Error",
                "unknown_error": "Unknown error",
                "completed": "Completed",
                "not_completed": "Not completed",
                
                // ContentView
                "view_all_habits": "View all habits",
                "no_habits_yet": "You don't have any habits yet",
                "create_first_habit": "Create your first habit to start building your best self.",
                "create_habit": "Create habit",
                
                // AddHabitView
                "new_habit": "New habit",
                "name": "Name",
                "name_placeholder": "Ex: Read 15 minutes",
                "description": "Description",
                "optional": "Optional",
                "icon": "Icon",
                "frequency": "Frequency",
                "specific_days": "Specific days",
                "reminder": "Reminder",
                "time": "Time",
                "enable_reminder": "Enable reminder",
                
                // Days
                "monday": "Monday",
                "tuesday": "Tuesday",
                "wednesday": "Wednesday",
                "thursday": "Thursday",
                "friday": "Friday",
                "saturday": "Saturday",
                "sunday": "Sunday",
                "all_days": "All days",
                "dailies": "Dailies",
                
                // Settings
                "appearance": "Appearance",
                "appearance_mode": "Appearance mode",
                "appearance_light": "Light",
                "appearance_dark": "Dark",
                "appearance_auto": "Auto",
                "dark_mode": "Dark mode",
                "language": "Language",
                "spanish": "Español",
                "english": "English",
                "plans": "Plans",
                "normal": "Normal",
                "premium": "Premium",
                "free_plan": "Free plan",
                "unlock_all": "Unlock everything",
                "active_plan": "Active plan",
                "change": "Change",
                
                // AI Camera
                "ai_camera": "AI Camera",
                "ai_camera_title": "Create habit with AI",
                "ai_camera_subtitle": "Take a photo of something that inspires you to create a new habit",
                "take_photo": "Take photo",
                "choose_gallery": "Choose from gallery",
                "analyzing": "Analyzing image...",
                
                // Recaps
                "recap_daily": "Daily summary",
                "recap_weekly": "Weekly summary",
                "recap_monthly": "Monthly summary",
                "recap_title": "Your progress",
                "recap_completed": "Completed",
                "recap_streak": "Best streak",
            ]
        ]
    }
}

// MARK: - Factory
struct LanguageModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = LanguageModuleImpl
    
    static func create() -> LanguageModuleImpl {
        return LanguageModuleImpl()
    }
}
