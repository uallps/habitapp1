//
//  Media3DModuleImpl.swift
//  HabitApp
//
//  Módulo de Modelado 3D e Imágenes - Implementación
//  Autor: Lucas
//  
//  Este módulo permite capturar objetos en 3D y guardar imágenes
//  al completar un hábito. Se inyecta mediante Protocol + DI.
//

import SwiftUI
import Combine
#if os(iOS)
import RealityKit
import ARKit
#endif

// MARK: - Media 3D Module Implementation
@MainActor
final class Media3DModuleImpl: Media3DModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.media3d"
    static var moduleName: String = "Media 3D Module"
    static var moduleAuthor: String = "Lucas"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    @Published var isCapturing: Bool = false
    @Published var captureProgress: Double = 0
    
    private var currentCompletion: ((Result<URL, Error>) -> Void)?
    
    // MARK: - Protocol Properties
    var supports3DCapture: Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            #if !targetEnvironment(simulator)
            return PhotogrammetrySession.isSupported
            #else
            return false
            #endif
        }
        return false
        #else
        return false
        #endif
    }
    
    var hasLiDAR: Bool {
        #if os(iOS)
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    init() {
        print("[\(Self.moduleName)] Module instance created")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        print("[\(Self.moduleName)] 3D Capture supported: \(supports3DCapture)")
        print("[\(Self.moduleName)] LiDAR available: \(hasLiDAR)")
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        cancelCapture()
        isEnabled = false
    }
    
    // MARK: - 3D Capture
    func startCapture(completion: @escaping (Result<URL, Error>) -> Void) {
        guard supports3DCapture else {
            completion(.failure(Media3DError.notSupported))
            return
        }
        
        print("[\(Self.moduleName)] Starting 3D capture...")
        isCapturing = true
        currentCompletion = completion
        
        // La captura real se maneja en la vista ObjectCaptureContainerView
    }
    
    func cancelCapture() {
        print("[\(Self.moduleName)] Cancelling capture...")
        isCapturing = false
        captureProgress = 0
        currentCompletion?(.failure(Media3DError.cancelled))
        currentCompletion = nil
    }
    
    // MARK: - View Factory
    func captureView() -> AnyView {
        #if os(iOS)
        return AnyView(
            ObjectCaptureContainerViewWrapper(module: self)
        )
        #else
        return AnyView(
            Text("3D Capture not available on macOS")
                .foregroundColor(.secondary)
        )
        #endif
    }
    
    func viewerView(for modelURL: URL) -> AnyView {
        return AnyView(
            Model3DViewerWrapper(modelURL: modelURL)
        )
    }
    
    // MARK: - Internal Methods
    func completeCapture(with url: URL) {
        isCapturing = false
        captureProgress = 0
        currentCompletion?(.success(url))
        currentCompletion = nil
    }
    
    func failCapture(with error: Error) {
        isCapturing = false
        captureProgress = 0
        currentCompletion?(.failure(error))
        currentCompletion = nil
    }
}

// MARK: - Errors
enum Media3DError: LocalizedError {
    case notSupported
    case cancelled
    case captureFaild
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "3D capture is not supported on this device"
        case .cancelled:
            return "3D capture was cancelled"
        case .captureFaild:
            return "Failed to capture 3D model"
        case .processingFailed:
            return "Failed to process 3D model"
        }
    }
}

// MARK: - View Wrappers
#if os(iOS)
struct ObjectCaptureContainerViewWrapper: View {
    let module: Media3DModuleImpl
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ObjectCaptureContainerView { result in
            switch result {
            case .model(let url):
                module.completeCapture(with: url)
            case .image(_):
                // Image captured, but we expected 3D model
                break
            case .none:
                module.cancelCapture()
            }
            dismiss()
        }
    }
}
#endif

struct Model3DViewerWrapper: View {
    let modelURL: URL
    
    var body: some View {
        Model3DViewer(modelURL: modelURL)
    }
}

// MARK: - Factory
struct Media3DModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = Media3DModuleImpl
    
    static func create() -> Media3DModuleImpl {
        return Media3DModuleImpl()
    }
}
