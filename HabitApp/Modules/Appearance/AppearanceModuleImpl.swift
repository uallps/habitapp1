//
//  AppearanceModuleImpl.swift
//  HabitApp
//
//  Módulo de Modo Oscuro/Claro - Implementación
//  Autor: Avilés
//  
//  Este módulo gestiona la apariencia visual de la aplicación
//  (modo oscuro, claro y automático). Se inyecta mediante Protocol + DI.
//

import SwiftUI
import Combine

// MARK: - Appearance Module Implementation
@MainActor
final class AppearanceModuleImpl: AppearanceModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.appearance"
    static var moduleName: String = "Appearance Module"
    static var moduleAuthor: String = "Avilés"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    @Published var currentMode: AppearanceModeType {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "appearanceMode")
            appearanceSubject.send(currentMode)
        }
    }
    
    // MARK: - Publishers
    private let appearanceSubject = PassthroughSubject<AppearanceModeType, Never>()
    var appearancePublisher: AnyPublisher<AppearanceModeType, Never> {
        appearanceSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Protocol Properties
    var colorScheme: ColorScheme? {
        switch currentMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil // Sigue el sistema
        }
    }
    
    var availableModes: [AppearanceModeType] {
        return AppearanceModeType.allCases
    }
    
    // MARK: - Initialization
    init() {
        // Cargar modo guardado
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceModeType(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .auto
        }
        
        print("[\(Self.moduleName)] Module instance created with mode: \(currentMode)")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        print("[\(Self.moduleName)] Available modes: \(availableModes)")
        print("[\(Self.moduleName)] Current mode: \(currentMode)")
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        isEnabled = false
    }
    
    // MARK: - Mode Management
    func setMode(_ mode: AppearanceModeType) {
        print("[\(Self.moduleName)] Changing mode to: \(mode)")
        currentMode = mode
    }
    
    // MARK: - Helper Methods
    
    /// Obtiene el color de fondo apropiado según el esquema actual
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        Color.appBackground(for: colorScheme)
    }
    
    /// Obtiene el color de fondo de tarjeta según el esquema actual
    func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        Color.appCardBackground(for: colorScheme)
    }
    
    /// Obtiene el color de fondo terciario según el esquema actual
    func tertiaryBackgroundColor(for colorScheme: ColorScheme) -> Color {
        Color.appTertiaryBackground(for: colorScheme)
    }
}

// MARK: - SwiftUI View Modifier
struct AppearanceModifier: ViewModifier {
    @ObservedObject var module: AppearanceModuleImpl
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(module.colorScheme)
    }
}

extension View {
    /// Aplica el esquema de color del módulo de apariencia
    func withAppearance(_ module: AppearanceModuleImpl) -> some View {
        self.modifier(AppearanceModifier(module: module))
    }
}

// MARK: - Factory
struct AppearanceModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = AppearanceModuleImpl
    
    static func create() -> AppearanceModuleImpl {
        return AppearanceModuleImpl()
    }
}
