import SwiftUI
import Combine

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "app_language")
            UserDefaults.standard.set(true, forKey: "user_set_language")
            currentLocale = Locale(identifier: language)
        }
    }
    
    @Published var currentLocale: Locale
    
    private init() {
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
        
        self.language = initialLanguage
        self.currentLocale = Locale(identifier: initialLanguage)
    }
    
    func setLanguage(_ lang: String) {
        language = lang
    }
    
    func localized(_ key: String) -> String {
        return translations[language]?[key] ?? translations["es"]?[key] ?? key
    }
    
    private let translations: [String: [String: String]] = [
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
            
            // Short days
            "mon": "Lun",
            "tue": "Mar",
            "wed": "Mié",
            "thu": "Jue",
            "fri": "Vie",
            "sat": "Sáb",
            "sun": "Dom",
            
            // HabitCardView
            "streak": "Racha",
            "days": "días",
            "day": "día",
            "add_note": "Añadir nota",
            "for_today": "para %@ de hoy",
            
            // AllHabitsView
            "all_habits": "Todos los hábitos",
            "no_habits_filter": "No hay hábitos para este filtro.",
            "frequency_label": "Frecuencia",
            "no_days": "Sin días",
            
            // StatisticsView
            "month_completion": "Porcentaje de cumplimiento del mes",
            "week_completion": "Porcentaje de cumplimiento de la semana",
            "day_completion": "Porcentaje de cumplimiento del día",
            "longest_streak": "Racha más larga",
            
            // HabitsForDayView
            "no_habits_scheduled": "No hay hábitos programados para este día.",
            "note_label": "Nota",
            
            // SettingsView
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
            "plan_text_free": "• Hábitos ilimitados\n• Recordatorios básicos\n• Estadísticas básicas",
            "plan_text_premium": "• Todo lo del plan normal\n• Estadísticas avanzadas\n• Filtros y calendario PRO\n• Sin límites / funciones extra",
            
            "app_version": "Versión de la app",
            "current_version": "Versión actual",
            "app_name": "Nombre de la app",
            "current_plan": "Plan actual",
            "version": "Versión",
            "free_limits": "Limitaciones del plan gratuito:",
            "max_habits": "Máximo de hábitos",
            "basic_statistics": "Estadísticas básicas",
            "no_ai_camera": "Sin cámara IA",
            "no_recaps": "Sin recaps",
            "shows_ads": "Muestra anuncios",
            "premium_benefits": "Beneficios Premium:",
            "unlimited_habits": "Hábitos ilimitados",
            "advanced_statistics": "Estadísticas avanzadas",
            "cloud_backup": "Backup en la nube",
            "no_ads": "Sin anuncios",
            "ai_camera_feature": "Cámara IA para crear hábitos",
            "recaps_feature": "Recaps diarios/semanales/mensuales",
            "no_notes": "Sin notas en hábitos",
            "habit_notes": "Notas en hábitos",
            
            // Icons filter
            "no_habits_icon": "No hay hábitos con este icono todavía.",
            
            // Notifications
            "notification_title": "¡Hora de %@!",
            "notification_body": "No olvides tu hábito de hoy 💪",
            
            "habits_count": "Hábitos",
            "habit_limit_title": "Límite alcanzado",
            "habit_limit_message": "Has alcanzado el límite de 5 hábitos en la versión gratuita. Actualiza a Premium para crear hábitos ilimitados.",
            "upgrade_premium": "Obtener Premium",
            "ads_enabled": "Anuncios activados",
            "ads_disabled": "Sin anuncios",
            
            // AI Camera Feature
            "ai_camera": "Cámara IA",
            "ai_camera_title": "Cámara Inteligente",
            "ai_camera_subtitle": "Haz una foto y la IA te sugerirá un hábito relacionado",
            "take_photo": "Tomar foto",
            "choose_gallery": "Elegir de galería",
            "analyze_create_habit": "Analizar y crear hábito",
            "analyzing": "Analizando...",
            "retake": "Volver a tomar",
            "configure_api": "Configurar API",
            "openai_api_key": "Clave API de OpenAI",
            "api_key_description": "Necesitas una clave de API de OpenAI para usar el análisis de imágenes con IA.",
            "detected": "Detectado:",
            "suggested_habit": "Hábito sugerido",
            "habit_exists": "Ya tienes un hábito con este nombre.",
            "camera_premium_only": "La cámara IA es una función Premium",
            "camera_unavailable": "Cámara no disponible",
            "camera_unavailable_message": "No se pudo acceder a la cámara. Por favor, verifica los permisos en Ajustes.",
            "camera_not_available": "Este dispositivo no tiene cámara disponible.",
            "open_settings": "Abrir Ajustes",
            
            // Categories
            "category_fitness": "Fitness",
            "category_nutrition": "Nutrición",
            "category_mindfulness": "Mindfulness",
            "category_learning": "Aprendizaje",
            "category_health": "Salud",
            "category_productivity": "Productividad",
            "category_sleep": "Sueño",
            "category_hydration": "Hidratación",
            "category_creativity": "Creatividad",
            "category_social": "Social",
            "category_unknown": "Otro",
            
            // Habit Completion Sheet
            "habit_completed": "¡Hábito completado!",
            "day_streak": "días de racha",
            "note_placeholder": "¿Cómo te ha ido? Escribe una nota...",
            "capture_moment": "Captura el momento",
            "photo": "Foto",
            "3d_model": "Modelo 3D",
            "preview": "Vista previa",
            "choose_source": "Elegir fuente",
            
            // 3D Capture
            "3d_capture_title": "Captura 3D",
            "3d_capture_instructions": "Mueve tu dispositivo alrededor del objeto para capturar un modelo 3D.",
            "3d_step_1": "Coloca el objeto en una superficie plana",
            "3d_step_2": "Mueve la cámara lentamente alrededor",
            "3d_step_3": "Mantén el objeto centrado en la pantalla",
            "start_capture": "Iniciar captura",
            "move_around": "Muévete alrededor",
            "capturing": "Capturando...",
            "create_model": "Crear modelo",
            "processing_model": "Procesando modelo 3D...",
            "processing_subtitle": "Esto puede tardar unos segundos",
            "3d_preview": "Vista previa 3D",
            "3d_model_ready": "Modelo 3D listo",
            "3d_not_supported_title": "3D no disponible",
            "3d_not_supported_message": "La captura 3D requiere iPhone 12 o superior con iOS 17+. ¿Deseas tomar una foto en su lugar?",
            "take_photo_instead": "Tomar foto",
            
            // Media Viewing
            "view_photo": "Ver foto",
            "view_3d_model": "Ver modelo 3D",
            "tap_to_view": "Toca para ver",
            
            // Recaps
            "your_recaps": "Tus recaps",
            "weekly": "Semanal",
            "monthly": "Mensual",
            "your_daily_recap": "Tu recap del día",
            "your_weekly_recap": "Tu recap semanal",
            "your_monthly_recap": "Tu recap mensual",
            "your_progress": "Tu progreso",
            "completion_rate": "tasa de completado",
            "highlights": "Destacados",
            "no_media_yet": "Aún no hay fotos",
            "moments_captured": "momentos capturados",
            "photos": "fotos",
            "3d_models": "modelos 3D",
            "keep_going": "¡Sigue así!",
            "recap_motivation": "Cada pequeño paso cuenta. Continúa construyendo tus hábitos día a día.",
            
            // Uncomplete Habit and Model
            "uncomplete_habit": "Desmarcar hábito",
            "uncomplete": "Desmarcar",
            "uncomplete_habit_message": "¿Estás seguro de que quieres desmarcar este hábito? Se eliminarán la nota y cualquier foto o modelo 3D asociado.",
            "model_not_found": "Modelo no encontrado",
            "close": "Cerrar"
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
            "no_habits_yet": "No habits yet",
            "create_first_habit": "Create your first habit to start building your best self.",
            "create_habit": "Create habit",
            
            // AddHabitView
            "new_habit": "New habit",
            "name": "Name",
            "name_placeholder": "E.g: Read 15 minutes",
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
            
            // Short days
            "mon": "Mon",
            "tue": "Tue",
            "wed": "Wed",
            "thu": "Thu",
            "fri": "Fri",
            "sat": "Sat",
            "sun": "Sun",
            
            // HabitCardView
            "streak": "Streak",
            "days": "days",
            "day": "day",
            "add_note": "Add note",
            "for_today": "for %@ today",
            
            // AllHabitsView
            "all_habits": "All habits",
            "no_habits_filter": "No habits match this filter.",
            "frequency_label": "Frequency",
            "no_days": "No days",
            
            // StatisticsView
            "month_completion": "Monthly completion rate",
            "week_completion": "Weekly completion rate",
            "day_completion": "Daily completion rate",
            "longest_streak": "Longest streak",
            
            // HabitsForDayView
            "no_habits_scheduled": "No habits scheduled for this day.",
            "note_label": "Note",
            
            // SettingsView
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
            "plan_text_free": "• Unlimited habits\n• Basic reminders\n• Basic statistics",
            "plan_text_premium": "• Everything in normal plan\n• Advanced statistics\n• PRO filters and calendar\n• No limits / extra features",
            
            "app_version": "App version",
            "current_version": "Current version",
            "app_name": "App name",
            "current_plan": "Current plan",
            "version": "Version",
            "free_limits": "Free plan limitations:",
            "max_habits": "Max habits",
            "basic_statistics": "Basic statistics",
            "no_ai_camera": "No AI Camera",
            "no_recaps": "No Recaps",
            "shows_ads": "Shows ads",
            "premium_benefits": "Premium benefits:",
            "unlimited_habits": "Unlimited habits",
            "advanced_statistics": "Advanced statistics",
            "cloud_backup": "Cloud backup",
            "no_ads": "No ads",
            "ai_camera_feature": "AI Camera to create habits",
            "recaps_feature": "Daily/Weekly/Monthly Recaps",
            "no_notes": "No habit notes",
            "habit_notes": "Habit notes",
            
            // Icons filter
            "no_habits_icon": "No habits with this icon yet.",
            
            // Notifications
            "notification_title": "Time for %@!",
            "notification_body": "Don't forget your habit today 💪",
            
            "habits_count": "Habits",
            "habit_limit_title": "Limit reached",
            "habit_limit_message": "You have reached the limit of 5 habits in the free version. Upgrade to Premium for unlimited habits.",
            "upgrade_premium": "Get Premium",
            "ads_enabled": "Ads enabled",
            "ads_disabled": "No ads",
            
            // AI Camera Feature
            "ai_camera": "AI Camera",
            "ai_camera_title": "Smart Camera",
            "ai_camera_subtitle": "Take a photo and AI will suggest a related habit",
            "take_photo": "Take photo",
            "choose_gallery": "Choose from gallery",
            "analyze_create_habit": "Analyze and create habit",
            "analyzing": "Analyzing...",
            "retake": "Retake",
            "configure_api": "Configure API",
            "openai_api_key": "OpenAI API Key",
            "api_key_description": "You need an OpenAI API key to use AI image analysis.",
            "detected": "Detected:",
            "suggested_habit": "Suggested habit",
            "habit_exists": "You already have a habit with this name.",
            "camera_premium_only": "AI Camera is a Premium feature",
            "camera_unavailable": "Camera unavailable",
            "camera_unavailable_message": "Could not access the camera. Please check permissions in Settings.",
            "camera_not_available": "This device does not have a camera available.",
            "open_settings": "Open Settings",
            
            // Categories
            "category_fitness": "Fitness",
            "category_nutrition": "Nutrition",
            "category_mindfulness": "Mindfulness",
            "category_learning": "Learning",
            "category_health": "Health",
            "category_productivity": "Productivity",
            "category_sleep": "Sleep",
            "category_hydration": "Hydration",
            "category_creativity": "Creativity",
            "category_social": "Social",
            "category_unknown": "Other",
            
            // Habit Completion Sheet
            "habit_completed": "Habit completed!",
            "day_streak": "day streak",
            "note_placeholder": "How did it go? Write a note...",
            "capture_moment": "Capture the moment",
            "photo": "Photo",
            "3d_model": "3D Model",
            "preview": "Preview",
            "choose_source": "Choose source",
            
            // 3D Capture
            "3d_capture_title": "3D Capture",
            "3d_capture_instructions": "Move your device around the object to capture a 3D model.",
            "3d_step_1": "Place the object on a flat surface",
            "3d_step_2": "Move the camera slowly around",
            "3d_step_3": "Keep the object centered on screen",
            "start_capture": "Start capture",
            "move_around": "Move around",
            "capturing": "Capturing...",
            "create_model": "Create model",
            "processing_model": "Processing 3D model...",
            "processing_subtitle": "This may take a few seconds",
            "3d_preview": "3D Preview",
            "3d_model_ready": "3D Model Ready",
            "3d_not_supported_title": "3D Not Supported",
            "3d_not_supported_message": "3D capture requires iPhone 12 or later with iOS 17+. Would you like to take a photo instead?",
            "take_photo_instead": "Take Photo Instead",
            
            // Media Viewing
            "view_photo": "View photo",
            "view_3d_model": "View 3D model",
            "tap_to_view": "Tap to view",
            
            // Recaps
            "your_recaps": "Your recaps",
            "weekly": "Weekly",
            "monthly": "Monthly",
            "your_daily_recap": "Your daily recap",
            "your_weekly_recap": "Your weekly recap",
            "your_monthly_recap": "Your monthly recap",
            "your_progress": "Your progress",
            "completion_rate": "completion rate",
            "highlights": "Highlights",
            "no_media_yet": "No photos yet",
            "moments_captured": "moments captured",
            "photos": "photos",
            "3d_models": "3D models",
            "keep_going": "Keep going!",
            "recap_motivation": "Every small step counts. Keep building your habits day by day.",
            
            // Uncomplete Habit and Model
            "uncomplete_habit": "Uncomplete habit",
            "uncomplete": "Uncomplete",
            "uncomplete_habit_message": "Are you sure you want to uncomplete this habit? The note and any associated photo or 3D model will be deleted.",
            "model_not_found": "Model not found",
            "close": "Close"
        ]
    ]
    
    // MARK: - Localized weekday symbols
    var weekDaySymbols: [String] {
        ["L", "M", "X", "J", "V", "S", "D"]
    }
    
    var weekDayNames: [String] {
        [
            localized("monday"),
            localized("tuesday"),
            localized("wednesday"),
            localized("thursday"),
            localized("friday"),
            localized("saturday"),
            localized("sunday")
        ]
    }
    
    var shortWeekDayNames: [String] {
        [
            localized("mon"),
            localized("tue"),
            localized("wed"),
            localized("thu"),
            localized("fri"),
            localized("sat"),
            localized("sun")
        ]
    }
    
    func dayName(for symbol: String) -> String {
        switch symbol {
        case "L": return localized("monday")
        case "M": return localized("tuesday")
        case "X": return localized("wednesday")
        case "J": return localized("thursday")
        case "V": return localized("friday")
        case "S": return localized("saturday")
        case "D": return localized("sunday")
        case "Diario": return localized("dailies")
        case "Todos": return localized("all_days")
        default: return symbol
        }
    }
    
    func shortDayName(for symbol: String) -> String {
        switch symbol {
        case "L": return localized("mon")
        case "M": return localized("tue")
        case "X": return localized("wed")
        case "J": return localized("thu")
        case "V": return localized("fri")
        case "S": return localized("sat")
        case "D": return localized("sun")
        default: return symbol
        }
    }
    
    var dateLocale: Locale {
        Locale(identifier: language == "es" ? "es_ES" : "en_US")
    }
}
