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
            "close": "Cerrar",
            
            // Gamification - General
            "game_center": "Centro de Juego",
            "profile": "Perfil",
            "achievements": "Logros",
            "trophies": "Trofeos",
            "rewards": "Recompensas",
            "level": "Nivel",
            "xp": "XP",
            "total_xp": "XP Total",
            
            // Gamification - Levels
            "level_novice": "Novato",
            "level_apprentice": "Aprendiz",
            "level_dedicated": "Dedicado",
            "level_consistent": "Constante",
            "level_expert": "Experto",
            "level_master": "Maestro",
            "level_legend": "Leyenda",
            "level_hero": "Héroe",
            "level_champion": "Campeón",
            "level_immortal": "Inmortal",
            
            // Gamification - Achievement Categories
            "category_streaks": "Rachas",
            "category_completions": "Completados",
            "category_consistency": "Consistencia",
            "category_explorer": "Explorador",
            "category_special": "Especiales",
            
            // Gamification - Rarity
            "rarity_common": "Común",
            "rarity_uncommon": "Poco común",
            "rarity_rare": "Raro",
            "rarity_epic": "Épico",
            "rarity_legendary": "Legendario",
            
            // Gamification - Trophy Tiers
            "tier_bronze": "Bronce",
            "tier_silver": "Plata",
            "tier_gold": "Oro",
            "tier_platinum": "Platino",
            "tier_diamond": "Diamante",
            
            // Gamification - Stats
            "unlocked": "Desbloqueados",
            "to_unlock": "Por desbloquear",
            "completed_percent": "Completado",
            "trophies_obtained": "Trofeos obtenidos",
            "to_achieve": "Por conseguir",
            
            // Gamification - Daily Rewards
            "consecutive_days": "Días consecutivos",
            "bonus_active": "¡Bonus x%@ activo!",
            "this_week": "Esta semana",
            "claim_reward": "Reclamar recompensa",
            "reward_claimed": "Recompensa reclamada",
            "come_back_tomorrow": "Vuelve mañana",
            "upcoming_rewards": "Próximas recompensas",
            "recent_history": "Historial reciente",
            "no_rewards_yet": "Aún no has reclamado recompensas",
            
            // Gamification - Settings
            "gamification": "Gamificación",
            "gamification_subtitle": "XP, Logros, Trofeos y Recompensas",
            "daily_rewards": "Recompensas diarias",
            
            // Gamification - Achievements (Names)
            "achievement_streak_3": "Primer Paso",
            "achievement_streak_7": "Semana Perfecta",
            "achievement_streak_14": "Dos Semanas Fuertes",
            "achievement_streak_30": "Mes Invicto",
            "achievement_streak_100": "Centenario",
            "achievement_streak_365": "Un Año Imparable",
            "achievement_complete_1": "Primer Hábito",
            "achievement_complete_10": "Empezando Fuerte",
            "achievement_complete_50": "En Racha",
            "achievement_complete_100": "Centurión",
            "achievement_complete_500": "Medio Millar",
            "achievement_complete_1000": "Mil Éxitos",
            "achievement_perfect_week": "Semana Perfecta",
            "achievement_monthly_80": "Maestro Mensual",
            "achievement_monthly_100": "Mes Perfecto",
            "achievement_yearly_goal": "Meta Anual",
            "achievement_first_photo": "Primer Recuerdo",
            "achievement_first_3d": "Explorador 3D",
            "achievement_first_ai": "Pionero IA",
            "achievement_variety": "Variedad",
            "achievement_all_categories": "Explorador Total",
            "achievement_first_day": "Bienvenido",
            "achievement_comeback": "Regreso Triunfal",
            "achievement_early_bird": "Madrugador",
            "achievement_night_owl": "Noctámbulo",
            "achievement_new_year": "Año Nuevo",
            
            // Gamification - Achievements (Descriptions)
            "achievement_streak_3_desc": "Completa una racha de 3 días",
            "achievement_streak_7_desc": "Mantén una racha de 7 días",
            "achievement_streak_14_desc": "Mantén una racha de 14 días",
            "achievement_streak_30_desc": "Mantén una racha de 30 días",
            "achievement_streak_100_desc": "Mantén una racha de 100 días",
            "achievement_streak_365_desc": "Mantén una racha de 365 días",
            "achievement_complete_1_desc": "Completa un hábito por primera vez",
            "achievement_complete_10_desc": "Completa 10 hábitos en total",
            "achievement_complete_50_desc": "Completa 50 hábitos en total",
            "achievement_complete_100_desc": "Completa 100 hábitos en total",
            "achievement_complete_500_desc": "Completa 500 hábitos en total",
            "achievement_complete_1000_desc": "Completa 1000 hábitos en total",
            "achievement_perfect_week_desc": "Completa todos los hábitos de una semana",
            "achievement_monthly_80_desc": "Alcanza 80% de completitud en un mes",
            "achievement_monthly_100_desc": "Completa el 100% de los hábitos de un mes",
            "achievement_yearly_goal_desc": "Completa todos tus hábitos en un año",
            "achievement_first_photo_desc": "Sube tu primera foto de un hábito",
            "achievement_first_3d_desc": "Crea tu primer modelo 3D",
            "achievement_first_ai_desc": "Crea un hábito con la cámara IA",
            "achievement_variety_desc": "Crea hábitos de 5 categorías diferentes",
            "achievement_all_categories_desc": "Crea hábitos en todas las categorías",
            "achievement_first_day_desc": "Completa tu primer día en la app",
            "achievement_comeback_desc": "Vuelve después de 7 días de inactividad",
            "achievement_early_bird_desc": "Completa un hábito antes de las 7am",
            "achievement_night_owl_desc": "Completa un hábito después de las 11pm",
            "achievement_new_year_desc": "Completa un hábito el 1 de enero",
            
            // Gamification - Profile Tab
            "progress_next_level": "Progreso al siguiente nivel",
            "max_streak": "Racha Máxima",
            "current_streak": "Racha Actual",
            "total_completions": "Completados",
            "next_level": "Siguiente nivel",
            "xp_remaining": "XP restantes"
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
            "close": "Close",
            
            // Gamification - General
            "game_center": "Game Center",
            "profile": "Profile",
            "achievements": "Achievements",
            "trophies": "Trophies",
            "rewards": "Rewards",
            "level": "Level",
            "xp": "XP",
            "total_xp": "Total XP",
            
            // Gamification - Levels
            "level_novice": "Novice",
            "level_apprentice": "Apprentice",
            "level_dedicated": "Dedicated",
            "level_consistent": "Consistent",
            "level_expert": "Expert",
            "level_master": "Master",
            "level_legend": "Legend",
            "level_hero": "Hero",
            "level_champion": "Champion",
            "level_immortal": "Immortal",
            
            // Gamification - Achievement Categories
            "category_streaks": "Streaks",
            "category_completions": "Completions",
            "category_consistency": "Consistency",
            "category_explorer": "Explorer",
            "category_special": "Special",
            
            // Gamification - Rarity
            "rarity_common": "Common",
            "rarity_uncommon": "Uncommon",
            "rarity_rare": "Rare",
            "rarity_epic": "Epic",
            "rarity_legendary": "Legendary",
            
            // Gamification - Trophy Tiers
            "tier_bronze": "Bronze",
            "tier_silver": "Silver",
            "tier_gold": "Gold",
            "tier_platinum": "Platinum",
            "tier_diamond": "Diamond",
            
            // Gamification - Stats
            "unlocked": "Unlocked",
            "to_unlock": "To unlock",
            "completed_percent": "Completed",
            "trophies_obtained": "Trophies obtained",
            "to_achieve": "To achieve",
            
            // Gamification - Daily Rewards
            "consecutive_days": "Consecutive days",
            "bonus_active": "Bonus x%@ active!",
            "this_week": "This week",
            "claim_reward": "Claim reward",
            "reward_claimed": "Reward claimed",
            "come_back_tomorrow": "Come back tomorrow",
            "upcoming_rewards": "Upcoming rewards",
            "recent_history": "Recent history",
            "no_rewards_yet": "You haven't claimed any rewards yet",
            
            // Gamification - Settings
            "gamification": "Gamification",
            "gamification_subtitle": "XP, Achievements, Trophies & Rewards",
            "daily_rewards": "Daily rewards",
            
            // Gamification - Achievements (Names)
            "achievement_streak_3": "First Step",
            "achievement_streak_7": "Perfect Week",
            "achievement_streak_14": "Two Strong Weeks",
            "achievement_streak_30": "Undefeated Month",
            "achievement_streak_100": "Centenarian",
            "achievement_streak_365": "Unstoppable Year",
            "achievement_complete_1": "First Habit",
            "achievement_complete_10": "Starting Strong",
            "achievement_complete_50": "On a Roll",
            "achievement_complete_100": "Centurion",
            "achievement_complete_500": "Half Thousand",
            "achievement_complete_1000": "A Thousand Wins",
            "achievement_perfect_week": "Perfect Week",
            "achievement_monthly_80": "Monthly Master",
            "achievement_monthly_100": "Perfect Month",
            "achievement_yearly_goal": "Yearly Goal",
            "achievement_first_photo": "First Memory",
            "achievement_first_3d": "3D Explorer",
            "achievement_first_ai": "AI Pioneer",
            "achievement_variety": "Variety",
            "achievement_all_categories": "Total Explorer",
            "achievement_first_day": "Welcome",
            "achievement_comeback": "Triumphant Return",
            "achievement_early_bird": "Early Bird",
            "achievement_night_owl": "Night Owl",
            "achievement_new_year": "New Year",
            
            // Gamification - Achievements (Descriptions)
            "achievement_streak_3_desc": "Complete a 3-day streak",
            "achievement_streak_7_desc": "Maintain a 7-day streak",
            "achievement_streak_14_desc": "Maintain a 14-day streak",
            "achievement_streak_30_desc": "Maintain a 30-day streak",
            "achievement_streak_100_desc": "Maintain a 100-day streak",
            "achievement_streak_365_desc": "Maintain a 365-day streak",
            "achievement_complete_1_desc": "Complete a habit for the first time",
            "achievement_complete_10_desc": "Complete 10 habits in total",
            "achievement_complete_50_desc": "Complete 50 habits in total",
            "achievement_complete_100_desc": "Complete 100 habits in total",
            "achievement_complete_500_desc": "Complete 500 habits in total",
            "achievement_complete_1000_desc": "Complete 1000 habits in total",
            "achievement_perfect_week_desc": "Complete all habits for a week",
            "achievement_monthly_80_desc": "Reach 80% completion in a month",
            "achievement_monthly_100_desc": "Complete 100% of habits in a month",
            "achievement_yearly_goal_desc": "Complete all your habits in a year",
            "achievement_first_photo_desc": "Upload your first habit photo",
            "achievement_first_3d_desc": "Create your first 3D model",
            "achievement_first_ai_desc": "Create a habit with the AI camera",
            "achievement_variety_desc": "Create habits in 5 different categories",
            "achievement_all_categories_desc": "Create habits in all categories",
            "achievement_first_day_desc": "Complete your first day in the app",
            "achievement_comeback_desc": "Return after 7 days of inactivity",
            "achievement_early_bird_desc": "Complete a habit before 7am",
            "achievement_night_owl_desc": "Complete a habit after 11pm",
            "achievement_new_year_desc": "Complete a habit on January 1st",
            
            // Gamification - Profile Tab
            "progress_next_level": "Progress to next level",
            "max_streak": "Max Streak",
            "current_streak": "Current Streak",
            "total_completions": "Completions",
            "next_level": "Next level",
            "xp_remaining": "XP remaining"
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
