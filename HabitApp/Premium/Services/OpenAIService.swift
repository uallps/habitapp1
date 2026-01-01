//
//  OpenAIService.swift
//  HabitApp
//
//  AI-powered image analysis using OpenAI GPT-4o Vision
//

import Foundation
import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - OpenAI API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: [OpenAIContent]
}

struct OpenAIContent: Codable {
    let type: String
    let text: String?
    let imageUrl: ImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
}

struct ImageURL: Codable {
    let url: String
    let detail: String?
}

struct OpenAIResponse: Codable {
    let choices: [Choice]?
    let error: OpenAIError?
    
    struct Choice: Codable {
        let message: ResponseMessage
    }
    
    struct ResponseMessage: Codable {
        let content: String
    }
    
    struct OpenAIError: Codable {
        let message: String
    }
}

// MARK: - Habit Suggestion Model
struct HabitSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: HabitCategory
    let iconName: String
    let frequency: [String]
    let confidence: Double
    let detectedObject: String
}

enum HabitCategory: String, CaseIterable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case learning = "learning"
    case health = "health"
    case productivity = "productivity"
    case sleep = "sleep"
    case hydration = "hydration"
    case creativity = "creativity"
    case social = "social"
    case unknown = "unknown"
    
    var icon: String {
        switch self {
        case .fitness: return "figure.walk"
        case .nutrition: return "leaf.fill"
        case .mindfulness: return "brain.head.profile"
        case .learning: return "book.fill"
        case .health: return "heart.fill"
        case .productivity: return "clock.fill"
        case .sleep: return "bed.double.fill"
        case .hydration: return "drop.fill"
        case .creativity: return "paintbrush.fill"
        case .social: return "person.2.fill"
        case .unknown: return "sparkles"
        }
    }
}

// MARK: - OpenAI Service
@MainActor
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private var apiKey: String {
        // Load API key from Secrets.plist
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String,
              !key.isEmpty,
              key != "your-openai-api-key-here" else {
            print("⚠️ OpenAI API Key not found in Secrets.plist")
            return ""
        }
        return key
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    private init() {}
    
    // MARK: - Validate API Key
    private func validateAPIKey() throws {
        guard !apiKey.isEmpty else {
            throw OpenAIServiceError.noApiKey
        }
    }
    
    // MARK: - Analyze Image
    #if os(iOS)
    func analyzeImage(_ image: UIImage, language: String = "es") async throws -> HabitSuggestion {
        try validateAPIKey()
        
        isAnalyzing = true
        lastError = nil
        
        defer { isAnalyzing = false }
        
        // Resize and compress image for API
        guard let imageData = resizeAndCompressImage(image) else {
            throw OpenAIServiceError.imageProcessingFailed
        }
        
        return try await performAnalysis(imageData: imageData, language: language)
    }
    #elseif os(macOS)
    func analyzeImage(_ image: NSImage, language: String = "es") async throws -> HabitSuggestion {
        try validateAPIKey()
        
        isAnalyzing = true
        lastError = nil
        
        defer { isAnalyzing = false }
        
        // Resize and compress image for API
        guard let imageData = resizeAndCompressImageMac(image) else {
            throw OpenAIServiceError.imageProcessingFailed
        }
        
        return try await performAnalysis(imageData: imageData, language: language)
    }
    #endif
    
    private func performAnalysis(imageData: Data, language: String) async throws -> HabitSuggestion {
        let base64URL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        
        let prompt = createPrompt(for: language)
        
        let request = OpenAIRequest(
            model: "gpt-4o",
            messages: [
                OpenAIMessage(
                    role: "user",
                    content: [
                        OpenAIContent(type: "text", text: prompt, imageUrl: nil),
                        OpenAIContent(type: "image_url", text: nil, imageUrl: ImageURL(url: base64URL, detail: "low"))
                    ]
                )
            ],
            maxTokens: 500
        )
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
               let errorMessage = errorResponse.error?.message {
                lastError = errorMessage
                throw OpenAIServiceError.apiError(errorMessage)
            }
            throw OpenAIServiceError.httpError(httpResponse.statusCode)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices?.first?.message.content else {
            throw OpenAIServiceError.noContent
        }
        
        return try parseHabitSuggestion(from: content)
    }
    
    private func createPrompt(for language: String) -> String {
        if language == "en" {
            return """
            Analyze this image and suggest a healthy habit that could be associated with what you see.
            
            IMPORTANT: Respond ENTIRELY IN ENGLISH.
            
            Respond ONLY with a valid JSON object in this exact format (no markdown, no explanation):
            {
                "detected_object": "what you see in the image (in English)",
                "habit_name": "suggested habit name in English (short, actionable)",
                "habit_description": "brief description of the habit in English",
                "category": "one of: fitness, nutrition, mindfulness, learning, health, productivity, sleep, hydration, creativity, social",
                "frequency": "daily or specific days like Mon,Tue,Wed,Thu,Fri",
                "confidence": 0.0 to 1.0
            }
            
            Examples:
            - Running shoes → "Run for 30 minutes" (fitness)
            - Book → "Read 20 pages" (learning)
            - Water bottle → "Drink 8 glasses of water" (hydration)
            - Yoga mat → "Practice yoga for 15 minutes" (mindfulness)
            - Vegetables → "Eat vegetables with every meal" (nutrition)
            - Bed → "Sleep 8 hours" (sleep)
            - Weights → "Do weight training" (fitness)
            
            Be creative but practical. The habit should be achievable and beneficial.
            """
        } else {
            return """
            Analiza esta imagen y sugiere un hábito saludable que pueda estar relacionado con lo que ves.
            
            IMPORTANTE: Responde COMPLETAMENTE EN ESPAÑOL.
            
            Responde SOLO con un objeto JSON válido en este formato exacto (sin markdown, sin explicación):
            {
                "detected_object": "lo que ves en la imagen (en español)",
                "habit_name": "nombre del hábito sugerido en español (corto, accionable)",
                "habit_description": "breve descripción del hábito en español",
                "category": "uno de: fitness, nutrition, mindfulness, learning, health, productivity, sleep, hydration, creativity, social",
                "frequency": "daily o días específicos como L,M,X,J,V",
                "confidence": 0.0 a 1.0
            }
            
            Ejemplos:
            - Zapatillas de correr → "Salir a correr 30 minutos" (fitness)
            - Libro → "Leer 20 páginas" (learning)
            - Botella de agua → "Beber 8 vasos de agua" (hydration)
            - Esterilla de yoga → "Practicar yoga 15 minutos" (mindfulness)
            - Verduras → "Comer verduras en cada comida" (nutrition)
            - Cama → "Dormir 8 horas" (sleep)
            - Pesas → "Hacer ejercicio con pesas" (fitness)
            
            Sé creativo pero práctico. El hábito debe ser alcanzable y beneficioso.
            """
        }
    }
    
    // MARK: - Parse Response
    private func parseHabitSuggestion(from content: String) throws -> HabitSuggestion {
        // Clean up the response - remove markdown code blocks if present
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanContent.data(using: .utf8) else {
            throw OpenAIServiceError.parsingFailed
        }
        
        struct SuggestionResponse: Codable {
            let detectedObject: String
            let habitName: String
            let habitDescription: String
            let category: String
            let frequency: String
            let confidence: Double
            
            enum CodingKeys: String, CodingKey {
                case detectedObject = "detected_object"
                case habitName = "habit_name"
                case habitDescription = "habit_description"
                case category, frequency, confidence
            }
        }
        
        let parsed = try JSONDecoder().decode(SuggestionResponse.self, from: jsonData)
        
        let category = HabitCategory(rawValue: parsed.category.lowercased()) ?? .unknown
        
        // Parse frequency
        let frequency: [String]
        if parsed.frequency.lowercased() == "daily" || parsed.frequency.lowercased() == "diario" {
            frequency = ["Diario"]
        } else {
            frequency = parsed.frequency.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        
        return HabitSuggestion(
            name: parsed.habitName,
            description: parsed.habitDescription,
            category: category,
            iconName: category.icon,
            frequency: frequency.isEmpty ? ["Diario"] : frequency,
            confidence: parsed.confidence,
            detectedObject: parsed.detectedObject
        )
    }
    
    // MARK: - Image Processing
    #if os(iOS)
    private func resizeAndCompressImage(_ image: UIImage, maxSize: CGFloat = 512) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        let newSize: CGSize
        if ratio < 1 {
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        } else {
            newSize = size
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.7)
    }
    #elseif os(macOS)
    private func resizeAndCompressImageMac(_ image: NSImage, maxSize: CGFloat = 512) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        let newSize: CGSize
        if ratio < 1 {
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        } else {
            newSize = size
        }
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        
        guard let tiffData = newImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
    #endif
}

enum OpenAIServiceError: LocalizedError {
    case imageProcessingFailed
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent
    case parsingFailed
    case noApiKey
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Error procesando la imagen."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .httpError(let code):
            return "Error HTTP: \(code)"
        case .apiError(let message):
            return "Error API: \(message)"
        case .noContent:
            return "No se recibió respuesta."
        case .parsingFailed:
            return "Error al procesar la respuesta."
        case .noApiKey:
            return "API Key de OpenAI no configurada. Añade tu key en Secrets.plist"
        }
    }
}
