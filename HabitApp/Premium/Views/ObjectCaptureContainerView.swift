#if os(iOS)
import SwiftUI
import RealityKit
import AVFoundation
import ARKit
import Combine
import UIKit

enum CaptureResult {
    case model(URL)
    case image(UIImage)
    case none
}

// MARK: - Device Capability Detection
class DeviceCapabilityManager {
    static let shared = DeviceCapabilityManager()
    
    var hasLiDAR: Bool {
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    var supportsDepthCapture: Bool {
        if #available(iOS 15.4, *) {
            guard let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
                return false
            }
            return device.activeFormat.supportedDepthDataFormats.count > 0
        }
        return false
    }
    
    var supportsPhotogrammetry: Bool {
        if #available(iOS 17.0, *) {
            #if !targetEnvironment(simulator)
            return PhotogrammetrySession.isSupported
            #else
            return false
            #endif
        }
        return false
    }
    
    var captureQualityLevel: CaptureQuality {
        if hasLiDAR && supportsDepthCapture {
            return .premium
        } else if hasLiDAR {
            return .enhanced
        } else {
            return .basic
        }
    }
    
    enum CaptureQuality {
        case premium    // LiDAR + Depth - Full 3D capture
        case enhanced   // LiDAR only - Good quality
        case basic      // Standard camera - Photo-based
        
        var requiredPhotos: Int {
            switch self {
            case .premium: return 30
            case .enhanced: return 35
            case .basic: return 45
            }
        }
        
        var captureInterval: TimeInterval {
            switch self {
            case .premium: return 0.2  // Fast capture with LiDAR+Depth
            case .enhanced: return 0.3
            case .basic: return 0.5
            }
        }
        
        var detailLevel: String {
            switch self {
            case .premium: return "medium"
            case .enhanced: return "reduced"
            case .basic: return "preview"
            }
        }
        
        var description: String {
            switch self {
            case .premium: return "Premium (LiDAR + Depth)"
            case .enhanced: return "Enhanced (LiDAR)"
            case .basic: return "Standard"
            }
        }
    }
}

struct ObjectCaptureContainerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var lang = LanguageManager.shared
    @StateObject private var captureManager = AdvancedPhotoCaptureManager()
    @State private var showInstructions = true
    @State private var processingModel = false
    @State private var processingProgress: Double = 0
    @State private var errorMessage: String?
    @State private var deviceCapabilities = DeviceCapabilityManager.shared
    
    let onComplete: (CaptureResult) -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showInstructions {
                instructionsView
            } else if processingModel {
                processingView
            } else {
                captureView
            }
        }
        .onAppear {
            captureManager.setupForQuality(deviceCapabilities.captureQualityLevel)
        }
        .onDisappear {
            captureManager.stopSession()
        }
    }
    
    // MARK: - Instructions View
    private var instructionsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: deviceCapabilities.hasLiDAR ? "camera.metering.matrix" : "cube.transparent")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
            }
            
            VStack(spacing: 16) {
                Text(lang.localized("3d_capture_title"))
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                // Show quality badge
                HStack(spacing: 8) {
                    Image(systemName: qualityIcon)
                        .foregroundColor(qualityColor)
                    Text(deviceCapabilities.captureQualityLevel.description)
                        .font(.subheadline.bold())
                        .foregroundColor(qualityColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(qualityColor.opacity(0.2))
                .cornerRadius(20)
                
                Text(qualityDescription)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                instructionRow(icon: "1.circle.fill", text: lang.localized("3d_step_1"))
                instructionRow(icon: "2.circle.fill", text: lang.localized("3d_step_2"))
                instructionRow(icon: "3.circle.fill", text: lang.localized("3d_step_3"))
                
                if deviceCapabilities.hasLiDAR {
                    instructionRow(icon: "checkmark.circle.fill", text: "LiDAR activado para mejor precisión")
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    onComplete(.none)
                    dismiss()
                }) {
                    Text(lang.localized("cancel"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(14)
                }
                
                Button(action: {
                    showInstructions = false
                    captureManager.startSession()
                }) {
                    Text(lang.localized("start_capture"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cyan)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    private var qualityIcon: String {
        switch deviceCapabilities.captureQualityLevel {
        case .premium: return "star.fill"
        case .enhanced: return "sparkles"
        case .basic: return "camera.fill"
        }
    }
    
    private var qualityColor: Color {
        switch deviceCapabilities.captureQualityLevel {
        case .premium: return .yellow
        case .enhanced: return .cyan
        case .basic: return .green
        }
    }
    
    private var qualityDescription: String {
        switch deviceCapabilities.captureQualityLevel {
        case .premium:
            return "Tu dispositivo tiene LiDAR y sensor de profundidad. Captura rápida y alta calidad."
        case .enhanced:
            return "Tu dispositivo tiene LiDAR. Captura mejorada de modelos 3D."
        case .basic:
            return lang.localized("3d_capture_instructions")
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Capture View
    private var captureView: some View {
        ZStack {
            AdvancedCameraPreview(captureManager: captureManager)
                .ignoresSafeArea()
            
            // Depth visualization overlay for LiDAR devices
            if deviceCapabilities.hasLiDAR && captureManager.isCapturing {
                depthOverlay
            }
            
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        captureManager.stopSession()
                        onComplete(.none)
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        if deviceCapabilities.hasLiDAR {
                            Image(systemName: "camera.metering.matrix")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Image(systemName: "photo.stack")
                            .font(.subheadline)
                        Text("\(captureManager.capturedCount)/\(captureManager.requiredPhotos)")
                            .font(.headline.monospacedDigit())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
                .padding()
                
                Spacer()
                
                // Preview of last captured image
                if let lastImage = captureManager.lastCapturedImage {
                    HStack {
                        Spacer()
                        Image(uiImage: lastImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 4)
                            .padding(.trailing, 20)
                    }
                }
                
                // Progress circle with guidance
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: Double(captureManager.capturedCount) / Double(captureManager.requiredPhotos))
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.2), value: captureManager.capturedCount)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title)
                            .foregroundColor(.cyan)
                        
                        Text(lang.localized("move_around"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if captureManager.isCapturing {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(lang.localized("capturing"))
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if deviceCapabilities.hasLiDAR && captureManager.depthQuality > 0.7 {
                            Text("Profundidad: Excelente")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    if captureManager.isCapturing {
                        VStack(spacing: 4) {
                            ProgressView(value: Double(captureManager.capturedCount), total: Double(captureManager.requiredPhotos))
                                .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                                .frame(height: 4)
                            
                            Text("\(Int((Double(captureManager.capturedCount) / Double(captureManager.requiredPhotos)) * 100))%")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    HStack(spacing: 40) {
                        // Capture button
                        Button(action: {
                            if captureManager.isCapturing {
                                captureManager.stopCapturing()
                            } else {
                                captureManager.startCapturing()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(captureManager.isCapturing ? Color.red : Color.cyan)
                                    .frame(width: 70, height: 70)
                                
                                if captureManager.isCapturing {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                } else {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        
                        // Process button - visible when enough photos captured
                        if captureManager.capturedCount >= captureManager.requiredPhotos {
                            Button(action: processCapture) {
                                Text(lang.localized("create_model"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .cornerRadius(25)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3), value: captureManager.capturedCount >= captureManager.requiredPhotos)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private var depthOverlay: some View {
        VStack {
            HStack {
                Spacer()
                if captureManager.depthQuality > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Calidad Depth")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(depthQualityColor)
                                    .frame(width: geo.size.width * captureManager.depthQuality, height: 6)
                            }
                        }
                        .frame(width: 60, height: 6)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .padding(.trailing, 16)
                    .padding(.top, 80)
                }
            }
            Spacer()
        }
    }
    
    private var depthQualityColor: Color {
        if captureManager.depthQuality > 0.7 {
            return .green
        } else if captureManager.depthQuality > 0.4 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: processingProgress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: processingProgress)
                
                Text("\(Int(processingProgress * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Text(lang.localized("processing_model"))
                .font(.headline)
                .foregroundColor(.white)
            
            Text(deviceCapabilities.hasLiDAR ? "Procesando con datos LiDAR..." : lang.localized("processing_subtitle"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private func processCapture() {
        processingModel = true
        captureManager.stopCapturing()
        captureManager.stopSession()
        
        Task {
            let result = await captureManager.processAndGetResult { progress in
                Task { @MainActor in
                    self.processingProgress = progress
                }
            }
            
            await MainActor.run {
                processingModel = false
                onComplete(result)
                dismiss()
            }
        }
    }
}

// MARK: - Advanced Photo Capture Manager with LiDAR Support
@MainActor
class AdvancedPhotoCaptureManager: NSObject, ObservableObject {
    @Published var capturedCount: Int = 0
    @Published var isCapturing: Bool = false
    @Published var lastCapturedImage: UIImage?
    @Published var depthQuality: Double = 0
    
    var requiredPhotos: Int = 40
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var depthOutput: AVCaptureDepthDataOutput?
    private var capturedImages: [UIImage] = []
    private var capturedDepthData: [CVPixelBuffer] = []
    private var lastCaptureTime: Date = Date()
    
    private var captureInterval: TimeInterval = 0.5
    private var qualityLevel: DeviceCapabilityManager.CaptureQuality = .basic
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setupForQuality(_ quality: DeviceCapabilityManager.CaptureQuality) {
        self.qualityLevel = quality
        self.requiredPhotos = quality.requiredPhotos
        self.captureInterval = quality.captureInterval
    }
    
    func startSession() {
        let session = AVCaptureSession()
        
        // Use higher quality for LiDAR devices
        if qualityLevel == .premium || qualityLevel == .enhanced {
            session.sessionPreset = .photo
        } else {
            session.sessionPreset = .high
        }
        
        // Configure camera input - prefer LiDAR depth camera if available
        var camera: AVCaptureDevice?
        
        if qualityLevel == .premium {
            camera = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)
        }
        
        if camera == nil {
            camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        guard let selectedCamera = camera,
              let input = try? AVCaptureDeviceInput(device: selectedCamera) else { return }
        
        // Configure camera for optimal capture
        try? selectedCamera.lockForConfiguration()
        
        if selectedCamera.isFocusModeSupported(.continuousAutoFocus) {
            selectedCamera.focusMode = .continuousAutoFocus
        }
        if selectedCamera.isExposureModeSupported(.continuousAutoExposure) {
            selectedCamera.exposureMode = .continuousAutoExposure
        }
        if selectedCamera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            selectedCamera.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        
        selectedCamera.unlockForConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
        // Depth output for LiDAR devices
        if qualityLevel == .premium {
            let depthOutput = AVCaptureDepthDataOutput()
            depthOutput.isFilteringEnabled = true
            depthOutput.setDelegate(self, callbackQueue: videoQueue)
            
            if session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                self.depthOutput = depthOutput
                
                // Synchronize outputs
                if let connection = depthOutput.connection(with: .depthData) {
                    connection.isEnabled = true
                }
            }
        }
        
        captureSession = session
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stopSession() {
        isCapturing = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
        }
    }
    
    func startCapturing() {
        isCapturing = true
        capturedImages.removeAll()
        capturedDepthData.removeAll()
        capturedCount = 0
        lastCapturedImage = nil
        lastCaptureTime = Date()
    }
    
    func stopCapturing() {
        isCapturing = false
    }
    
    func processAndGetResult(progressHandler: @escaping (Double) -> Void) async -> CaptureResult {
        guard !capturedImages.isEmpty else {
            return .none
        }
        
        // Get the best quality image
        let bestImage = capturedImages.max(by: { 
            ($0.size.width * $0.size.height) < ($1.size.width * $1.size.height) 
        }) ?? capturedImages[0]
        
        // Try photogrammetry on supported devices
        if #available(iOS 17.0, *) {
            #if !targetEnvironment(simulator)
            if PhotogrammetrySession.isSupported {
                progressHandler(0.05)
                
                let tempDir = FileManager.default.temporaryDirectory
                let captureDir = tempDir.appendingPathComponent("capture_\(UUID().uuidString)")
                
                do {
                    try FileManager.default.createDirectory(at: captureDir, withIntermediateDirectories: true)
                    
                    // Save images with optimized compression
                    for (index, image) in capturedImages.enumerated() {
                        let progress = 0.05 + (Double(index) / Double(capturedImages.count) * 0.15)
                        progressHandler(progress)
                        
                        // Use higher quality for LiDAR captures
                        let compressionQuality: CGFloat = qualityLevel == .premium ? 0.98 : 0.95
                        
                        if let data = image.jpegData(compressionQuality: compressionQuality) {
                            let filename = String(format: "IMG_%04d.jpg", index)
                            let fileURL = captureDir.appendingPathComponent(filename)
                            try data.write(to: fileURL)
                        }
                    }
                    
                    progressHandler(0.2)
                    
                    // Output URL in Documents (permanent)
                    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let modelsDir = documentsDir.appendingPathComponent("HabitMedia", isDirectory: true)
                    try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
                    let outputURL = modelsDir.appendingPathComponent("model_\(UUID().uuidString).usdz")
                    
                    // Configure session based on device capabilities
                    var configuration = PhotogrammetrySession.Configuration()
                    configuration.checkpointDirectory = tempDir.appendingPathComponent("checkpoint_\(UUID().uuidString)")
                    
                    let session = try PhotogrammetrySession(input: captureDir, configuration: configuration)
                    
                    // Use reduced detail for all quality levels (most compatible)
                    let request = PhotogrammetrySession.Request.modelFile(url: outputURL, detail: .reduced)
                    
                    try session.process(requests: [request])
                    
                    for try await output in session.outputs {
                        switch output {
                        case .processingComplete:
                            progressHandler(1.0)
                            // Clean up temp directory
                            try? FileManager.default.removeItem(at: captureDir)
                            try? FileManager.default.removeItem(at: configuration.checkpointDirectory!)
                            
                            if FileManager.default.fileExists(atPath: outputURL.path) {
                                return .model(outputURL)
                            } else {
                                return .image(bestImage)
                            }
                            
                        case .requestProgress(_, let fractionComplete):
                            progressHandler(0.2 + fractionComplete * 0.8)
                            
                        case .requestError(_, let error):
                            print("Photogrammetry error: \(error)")
                            try? FileManager.default.removeItem(at: captureDir)
                            try? FileManager.default.removeItem(at: configuration.checkpointDirectory!)
                            progressHandler(1.0)
                            return .image(bestImage)
                            
                        default:
                            break
                        }
                    }
                } catch {
                    print("PhotogrammetrySession error: \(error)")
                    try? FileManager.default.removeItem(at: captureDir)
                }
            }
            #endif
        }
        
        // Fallback: return best captured image
        progressHandler(1.0)
        return .image(bestImage)
    }
}

extension AdvancedPhotoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task { @MainActor in
            guard isCapturing else { return }
            
            let now = Date()
            guard now.timeIntervalSince(lastCaptureTime) >= captureInterval else { return }
            guard capturedCount < requiredPhotos else {
                stopCapturing()
                return
            }
            
            lastCaptureTime = now
            
            if let image = imageFromSampleBuffer(sampleBuffer) {
                capturedImages.append(image)
                capturedCount = capturedImages.count
                lastCapturedImage = image
            }
        }
    }
    
    nonisolated private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: [.useSoftwareRenderer: false, .highQualityDownsample: true])
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

extension AdvancedPhotoCaptureManager: AVCaptureDepthDataOutputDelegate {
    nonisolated func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        Task { @MainActor in
            // Calculate depth quality based on accuracy
            let depthDataMap = depthData.depthDataMap
            let width = CVPixelBufferGetWidth(depthDataMap)
            let height = CVPixelBufferGetHeight(depthDataMap)
            
            // Simple quality metric based on coverage
            let quality = min(1.0, Double(width * height) / (640.0 * 480.0))
            depthQuality = quality
            
            if isCapturing && capturedCount < requiredPhotos {
                capturedDepthData.append(depthDataMap)
            }
        }
    }
}

// MARK: - Advanced Camera Preview
struct AdvancedCameraPreview: UIViewRepresentable {
    @ObservedObject var captureManager: AdvancedPhotoCaptureManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        DispatchQueue.main.async {
            if let previewLayer = captureManager.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            captureManager.previewLayer?.frame = uiView.bounds
        }
    }
}

#else
// macOS stub - ObjectCapture is only available on iOS
import SwiftUI
import AppKit

enum CaptureResult {
    case model(URL)
    case image(NSImage)
    case none
}

struct ObjectCaptureContainerView: View {
    let onComplete: (CaptureResult) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("La captura 3D no está disponible en macOS")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Esta función requiere un iPhone o iPad con LiDAR")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Cerrar") {
                onComplete(.none)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}
#endif
