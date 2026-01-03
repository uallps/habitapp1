//
//  AIHabitModuleImpl.swift
//  HabitApp
//
//  Módulo de Generación de Hábitos con IA - Implementación
//  Autor: Diego
//  
//  Este módulo utiliza OpenAI GPT-4 Vision para analizar imágenes
//  y sugerir hábitos relacionados. Se inyecta mediante Protocol + DI.
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AI Habit Module Implementation
@MainActor
final class AIHabitModuleImpl: AIHabitModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.aihabit"
    static var moduleName: String = "AI Habit Module"
    static var moduleAuthor: String = "Diego"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    @Published var isProcessing: Bool = false
    @Published var lastSuggestion: HabitSuggestionData?
    @Published var lastError: String?
    
    // MARK: - Dependencies
    private let openAIService = OpenAIService.shared
    
    // MARK: - Protocol Properties
    var isConfigured: Bool {
        return openAIService.hasAPIKey
    }
    
    // MARK: - Initialization
    init() {
        print("[\(Self.moduleName)] Module instance created")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        print("[\(Self.moduleName)] OpenAI configured: \(isConfigured)")
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        isProcessing = false
        lastSuggestion = nil
        lastError = nil
        isEnabled = false
    }
    
    // MARK: - Image Analysis
    func analyzeImage(_ imageData: Data, completion: @escaping (Result<HabitSuggestionData, Error>) -> Void) {
        guard isConfigured else {
            completion(.failure(AIHabitError.notConfigured))
            return
        }
        
        guard !isProcessing else {
            completion(.failure(AIHabitError.alreadyProcessing))
            return
        }
        
        print("[\(Self.moduleName)] Analyzing image...")
        isProcessing = true
        lastError = nil
        
        // Convertir datos a imagen según plataforma
        #if os(iOS)
        guard let image = UIImage(data: imageData) else {
            isProcessing = false
            completion(.failure(AIHabitError.invalidImage))
            return
        }
        
        Task {
            do {
                let suggestion = try await openAIService.analyzeImage(image)
                
                // Convertir a estructura desacoplada
                let suggestionData = HabitSuggestionData(
                    name: suggestion.name,
                    description: suggestion.description,
                    category: suggestion.category.rawValue,
                    iconName: suggestion.iconName,
                    frequency: suggestion.frequency,
                    confidence: suggestion.confidence,
                    detectedObject: suggestion.detectedObject
                )
                
                await MainActor.run {
                    self.isProcessing = false
                    self.lastSuggestion = suggestionData
                    completion(.success(suggestionData))
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
        #elseif os(macOS)
        guard let image = NSImage(data: imageData) else {
            isProcessing = false
            completion(.failure(AIHabitError.invalidImage))
            return
        }
        
        Task {
            do {
                let suggestion = try await openAIService.analyzeImage(image)
                
                let suggestionData = HabitSuggestionData(
                    name: suggestion.name,
                    description: suggestion.description,
                    category: suggestion.category.rawValue,
                    iconName: suggestion.iconName,
                    frequency: suggestion.frequency,
                    confidence: suggestion.confidence,
                    detectedObject: suggestion.detectedObject
                )
                
                await MainActor.run {
                    self.isProcessing = false
                    self.lastSuggestion = suggestionData
                    completion(.success(suggestionData))
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
        #endif
    }
    
    // MARK: - View Factory
    func cameraView() -> AnyView {
        return AnyView(
            CameraHabitViewWrapper()
        )
    }
}

// MARK: - Errors
enum AIHabitError: LocalizedError {
    case notConfigured
    case alreadyProcessing
    case invalidImage
    case analysisFaild
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI API key is not configured"
        case .alreadyProcessing:
            return "Already processing an image"
        case .invalidImage:
            return "Invalid image data"
        case .analysisFaild:
            return "Failed to analyze image"
        }
    }
}

// MARK: - View Wrapper
struct CameraHabitViewWrapper: View {
    var body: some View {
        CameraHabitView()
    }
}

// MARK: - Factory
struct AIHabitModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = AIHabitModuleImpl
    
    static func create() -> AIHabitModuleImpl {
        return AIHabitModuleImpl()
    }
}
