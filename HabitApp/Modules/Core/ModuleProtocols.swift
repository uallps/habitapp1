//
//  ModuleProtocols.swift
//  HabitApp
//
//  Protocolos base para la arquitectura modular (Plugin Pattern)
//  Cada módulo implementa su protocolo para inyectarse sin acoplar el núcleo
//

import SwiftUI
import Combine

// MARK: - Base Module Protocol
/// Protocolo base que todos los módulos deben implementar
@MainActor
protocol ModuleProtocol: AnyObject {
    /// Identificador único del módulo
    static var moduleId: String { get }
    
    /// Nombre descriptivo del módulo
    static var moduleName: String { get }
    
    /// Autor/responsable del módulo
    static var moduleAuthor: String { get }
    
    /// Versión del módulo
    static var moduleVersion: String { get }
    
    /// Indica si el módulo está habilitado
    var isEnabled: Bool { get }
    
    /// Inicializa el módulo
    func initialize()
    
    /// Limpia recursos del módulo
    func cleanup()
}

// MARK: - Ads Module Protocol (Avilés)
/// Protocolo para el módulo de anuncios
@MainActor
protocol AdsModuleProtocol: ModuleProtocol {
    /// Indica si los anuncios están configurados
    var isAdMobConfigured: Bool { get }
    
    /// Indica si hay un anuncio cargado
    var isAdLoaded: Bool { get }
    
    /// Carga un anuncio intersticial
    func loadInterstitialAd()
    
    /// Muestra un anuncio intersticial
    /// - Parameters:
    ///   - rootViewController: ViewController desde el que mostrar el anuncio
    ///   - completion: Callback al cerrar el anuncio
    func showInterstitialAd(from rootViewController: Any?, completion: (() -> Void)?)
    
    /// Indica si se deben mostrar anuncios
    var shouldShowAds: Bool { get }
}

// MARK: - Media 3D Module Protocol (Lucas)
/// Protocolo para el módulo de modelado 3D e imágenes al completar hábito
@MainActor
protocol Media3DModuleProtocol: ModuleProtocol {
    /// Indica si el dispositivo soporta captura 3D
    var supports3DCapture: Bool { get }
    
    /// Indica si tiene LiDAR
    var hasLiDAR: Bool { get }
    
    /// Inicia la captura de un modelo 3D
    /// - Parameter completion: Callback con la URL del modelo o error
    func startCapture(completion: @escaping (Result<URL, Error>) -> Void)
    
    /// Cancela la captura actual
    func cancelCapture()
    
    /// Vista para captura de objetos 3D
    func captureView() -> AnyView
    
    /// Vista para visualizar modelo 3D
    /// - Parameter modelURL: URL del modelo a visualizar
    func viewerView(for modelURL: URL) -> AnyView
}

// MARK: - AI Habit Generation Module Protocol (Diego)
/// Protocolo para el módulo de generación de hábitos con IA desde imagen
@MainActor
protocol AIHabitModuleProtocol: ModuleProtocol {
    /// Indica si el servicio de IA está configurado
    var isConfigured: Bool { get }
    
    /// Indica si está procesando una imagen
    var isProcessing: Bool { get }
    
    /// Analiza una imagen y sugiere un hábito
    /// - Parameters:
    ///   - imageData: Datos de la imagen en base64
    ///   - completion: Callback con la sugerencia de hábito
    func analyzeImage(_ imageData: Data, completion: @escaping (Result<HabitSuggestionData, Error>) -> Void)
    
    /// Vista principal de cámara para captura de hábitos con IA
    func cameraView() -> AnyView
}

/// Estructura de datos para sugerencia de hábito (desacoplada del modelo interno)
struct HabitSuggestionData {
    let name: String
    let description: String
    let category: String
    let iconName: String
    let frequency: [String]
    let confidence: Double
    let detectedObject: String
}

// MARK: - Recaps Module Protocol (Jorge)
/// Protocolo para el módulo de recaps/resúmenes de hábitos
@MainActor
protocol RecapsModuleProtocol: ModuleProtocol {
    /// Tipos de periodo disponibles para recaps
    var availablePeriods: [String] { get }
    
    /// Genera datos del recap para un periodo
    /// - Parameter period: Periodo del recap (daily, weekly, monthly)
    func generateRecapData(for period: String) -> RecapData
    
    /// Vista de recap para un periodo específico
    /// - Parameter period: Periodo del recap
    func recapView(for period: String) -> AnyView
}

/// Estructura de datos para recap (desacoplada del modelo interno)
struct RecapData {
    let period: String
    let totalHabits: Int
    let completedHabits: Int
    let completionRate: Double
    let bestStreak: Int
    let mostCompletedHabit: String?
}

// MARK: - Language Module Protocol (Nieto)
/// Protocolo para el módulo de multilengüaje
@MainActor
protocol LanguageModuleProtocol: ModuleProtocol {
    /// Idioma actual
    var currentLanguage: String { get set }
    
    /// Locale actual
    var currentLocale: Locale { get }
    
    /// Idiomas soportados
    var supportedLanguages: [String] { get }
    
    /// Traduce una clave
    /// - Parameter key: Clave de traducción
    func localized(_ key: String) -> String
    
    /// Cambia el idioma
    /// - Parameter language: Código del idioma (es, en, etc.)
    func setLanguage(_ language: String)
    
    /// Publisher para cambios de idioma
    var languagePublisher: AnyPublisher<String, Never> { get }
}

// MARK: - Appearance Module Protocol (Avilés)
/// Protocolo para el módulo de modo oscuro/claro
@MainActor
protocol AppearanceModuleProtocol: ModuleProtocol {
    /// Modo de apariencia actual
    var currentMode: AppearanceModeType { get set }
    
    /// Esquema de color actual
    var colorScheme: ColorScheme? { get }
    
    /// Modos disponibles
    var availableModes: [AppearanceModeType] { get }
    
    /// Cambia el modo de apariencia
    /// - Parameter mode: Nuevo modo
    func setMode(_ mode: AppearanceModeType)
    
    /// Publisher para cambios de apariencia
    var appearancePublisher: AnyPublisher<AppearanceModeType, Never> { get }
}

/// Tipo de modo de apariencia (desacoplado del modelo interno)
enum AppearanceModeType: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}

// MARK: - Gamification Module Protocol (Lucas)
/// Protocolo para el módulo de gamificación y recompensas
@MainActor
protocol GamificationModuleProtocol: ModuleProtocol {
    /// Indica si el usuario tiene acceso premium a gamificación
    var isPremiumUser: Bool { get }
    
    /// Nivel actual del usuario
    var currentLevel: Int { get }
    
    /// XP total del usuario
    var totalXP: Int { get }
    
    /// Número de logros desbloqueados
    var unlockedAchievements: Int { get }
    
    /// Número de trofeos obtenidos
    var unlockedTrophies: Int { get }
    
    /// Racha actual de login diario
    var loginStreak: Int { get }
    
    /// Registra un hábito completado y otorga XP
    /// - Parameters:
    ///   - streak: Días consecutivos completando el hábito
    ///   - category: Categoría del hábito
    func recordHabitCompletion(streak: Int, category: String)
    
    /// Registra una foto añadida
    func recordPhotoAdded()
    
    /// Registra un modelo 3D creado
    func recordModel3DCreated()
    
    /// Registra un hábito creado con IA
    func recordAIHabitCreated()
    
    /// Intenta reclamar recompensa diaria
    /// - Returns: XP ganado o nil si ya se reclamó
    func claimDailyReward() -> Int?
    
    /// Vista principal del hub de gamificación
    func gamificationHubView() -> AnyView
    
    /// Datos del perfil de gamificación
    func getProfileData() -> GamificationProfileData
}

/// Estructura de datos del perfil de gamificación (desacoplada del modelo interno)
struct GamificationProfileData {
    let totalXP: Int
    let currentLevel: Int
    let levelName: String
    let xpForNextLevel: Int
    let currentLevelProgress: Double
    let totalCompletions: Int
    let maxStreak: Int
    let unlockedAchievements: Int
    let totalAchievements: Int
    let unlockedTrophies: Int
    let totalTrophies: Int
    let loginStreak: Int
}

// MARK: - Module Factory Protocol
/// Protocolo para factory que crea instancias de módulos
@MainActor
protocol ModuleFactoryProtocol {
    associatedtype ModuleType: ModuleProtocol
    
    /// Crea una instancia del módulo
    static func create() -> ModuleType
}
