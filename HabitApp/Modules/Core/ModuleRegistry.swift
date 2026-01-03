//
//  ModuleRegistry.swift
//  HabitApp
//
//  Registro central de módulos - Patrón Service Locator / Dependency Injection Container
//  Permite inyectar y obtener módulos sin acoplar el núcleo de la aplicación
//

import Foundation
import SwiftUI
import Combine

// MARK: - Module Registry
/// Contenedor central para registro e inyección de dependencias de módulos
@MainActor
final class ModuleRegistry: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ModuleRegistry()
    
    // MARK: - Module Storage
    private var modules: [String: any ModuleProtocol] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Typed Module References
    @Published private(set) var adsModule: (any AdsModuleProtocol)?
    @Published private(set) var media3DModule: (any Media3DModuleProtocol)?
    @Published private(set) var aiHabitModule: (any AIHabitModuleProtocol)?
    @Published private(set) var recapsModule: (any RecapsModuleProtocol)?
    @Published private(set) var languageModule: (any LanguageModuleProtocol)?
    @Published private(set) var appearanceModule: (any AppearanceModuleProtocol)?
    @Published private(set) var gamificationModule: (any GamificationModuleProtocol)?
    
    // MARK: - Initialization
    private init() {
        print("[ModuleRegistry] Initializing module registry...")
    }
    
    // MARK: - Registration Methods
    
    /// Registra un módulo genérico
    /// - Parameter module: Módulo a registrar
    func register<T: ModuleProtocol>(_ module: T) {
        let moduleId = type(of: module).moduleId
        modules[moduleId] = module
        module.initialize()
        print("[ModuleRegistry] Registered module: \(type(of: module).moduleName) (v\(type(of: module).moduleVersion)) by \(type(of: module).moduleAuthor)")
    }
    
    /// Registra el módulo de anuncios
    /// - Parameter module: Módulo de anuncios
    func registerAdsModule(_ module: any AdsModuleProtocol) {
        adsModule = module
        register(module)
    }
    
    /// Registra el módulo de modelado 3D
    /// - Parameter module: Módulo de 3D
    func registerMedia3DModule(_ module: any Media3DModuleProtocol) {
        media3DModule = module
        register(module)
    }
    
    /// Registra el módulo de generación de hábitos con IA
    /// - Parameter module: Módulo de IA
    func registerAIHabitModule(_ module: any AIHabitModuleProtocol) {
        aiHabitModule = module
        register(module)
    }
    
    /// Registra el módulo de recaps
    /// - Parameter module: Módulo de recaps
    func registerRecapsModule(_ module: any RecapsModuleProtocol) {
        recapsModule = module
        register(module)
    }
    
    /// Registra el módulo de idioma
    /// - Parameter module: Módulo de idioma
    func registerLanguageModule(_ module: any LanguageModuleProtocol) {
        languageModule = module
        register(module)
    }
    
    /// Registra el módulo de apariencia
    /// - Parameter module: Módulo de apariencia
    func registerAppearanceModule(_ module: any AppearanceModuleProtocol) {
        appearanceModule = module
        register(module)
    }
    
    /// Registra el módulo de gamificación
    /// - Parameter module: Módulo de gamificación
    func registerGamificationModule(_ module: any GamificationModuleProtocol) {
        gamificationModule = module
        register(module)
    }
    
    // MARK: - Retrieval Methods
    
    /// Obtiene un módulo por su tipo
    /// - Returns: El módulo o nil si no está registrado
    func getModule<T: ModuleProtocol>(_ type: T.Type) -> T? {
        return modules.values.first { $0 is T } as? T
    }
    
    /// Obtiene un módulo por su ID
    /// - Parameter moduleId: ID del módulo
    /// - Returns: El módulo o nil
    func getModule(byId moduleId: String) -> (any ModuleProtocol)? {
        return modules[moduleId]
    }
    
    /// Lista todos los módulos registrados
    var allModules: [any ModuleProtocol] {
        Array(modules.values)
    }
    
    /// Lista los IDs de todos los módulos
    var registeredModuleIds: [String] {
        Array(modules.keys)
    }
    
    // MARK: - Module Lifecycle
    
    /// Inicializa todos los módulos registrados
    func initializeAllModules() {
        for module in modules.values {
            if !module.isEnabled {
                module.initialize()
            }
        }
        print("[ModuleRegistry] All modules initialized")
    }
    
    /// Limpia todos los módulos
    func cleanupAllModules() {
        for module in modules.values {
            module.cleanup()
        }
        print("[ModuleRegistry] All modules cleaned up")
    }
    
    /// Elimina un módulo del registro
    /// - Parameter moduleId: ID del módulo a eliminar
    func unregister(moduleId: String) {
        if let module = modules[moduleId] {
            module.cleanup()
            modules.removeValue(forKey: moduleId)
            print("[ModuleRegistry] Unregistered module: \(moduleId)")
        }
    }
    
    // MARK: - Feature Availability Checks
    
    /// Verifica si el módulo de anuncios está disponible
    var hasAdsModule: Bool { adsModule != nil }
    
    /// Verifica si el módulo 3D está disponible
    var hasMedia3DModule: Bool { media3DModule != nil }
    
    /// Verifica si el módulo de IA está disponible
    var hasAIHabitModule: Bool { aiHabitModule != nil }
    
    /// Verifica si el módulo de recaps está disponible
    var hasRecapsModule: Bool { recapsModule != nil }
    
    /// Verifica si el módulo de idioma está disponible
    var hasLanguageModule: Bool { languageModule != nil }
    
    /// Verifica si el módulo de apariencia está disponible
    var hasAppearanceModule: Bool { appearanceModule != nil }
    
    /// Verifica si el módulo de gamificación está disponible
    var hasGamificationModule: Bool { gamificationModule != nil }
}

// MARK: - Module Registration Helper
/// Helper para registrar módulos al inicio de la app
struct ModuleBootstrapper {
    
    @MainActor
    static func bootstrap() {
        let registry = ModuleRegistry.shared
        
        // Registrar módulo de Anuncios (Avilés)
        let adsModule = AdsModuleImpl()
        registry.registerAdsModule(adsModule)
        
        // Registrar módulo de Modelado 3D (Lucas)
        let media3DModule = Media3DModuleImpl()
        registry.registerMedia3DModule(media3DModule)
        
        // Registrar módulo de IA para Hábitos (Diego)
        let aiHabitModule = AIHabitModuleImpl()
        registry.registerAIHabitModule(aiHabitModule)
        
        // Registrar módulo de Recaps (Jorge)
        let recapsModule = RecapsModuleImpl()
        registry.registerRecapsModule(recapsModule)
        
        // Registrar módulo de Idioma (Nieto)
        let languageModule = LanguageModuleImpl()
        registry.registerLanguageModule(languageModule)
        
        // Registrar módulo de Apariencia (Avilés)
        let appearanceModule = AppearanceModuleImpl()
        registry.registerAppearanceModule(appearanceModule)
        
        // Registrar módulo de Gamificación (Lucas)
        let gamificationModule = GamificationModuleImpl()
        registry.registerGamificationModule(gamificationModule)
        
        print("[ModuleBootstrapper] All modules registered successfully")
    }
}
