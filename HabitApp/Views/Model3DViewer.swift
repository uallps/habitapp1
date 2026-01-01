import SwiftUI
import QuickLook
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import QuickLookUI
#endif

struct Model3DViewer: View {
    let modelURL: URL
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var lang = LanguageManager.shared
    @State private var contentState: ContentDisplayState = .loading
    #if os(iOS)
    @State private var loadedImage: UIImage?
    #elseif os(macOS)
    @State private var loadedImage: NSImage?
    #endif
    @State private var verifiedURL: URL?
    @State private var isAccessingSecurityScope = false
    
    enum ContentDisplayState {
        case loading
        case model
        case image
        case error(String)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch contentState {
                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(lang.localized("loading"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                        
                case .model:
                    if let url = verifiedURL {
                        QuickLookPreview(url: url)
                            .ignoresSafeArea()
                    } else {
                        errorView(message: "Invalid URL")
                    }
                        
                case .image:
                    if let image = loadedImage {
                        ImageViewerContent(image: image)
                    }
                    
                case .error(let message):
                    errorView(message: message)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                #endif
                ToolbarItem(placement: .principal) {
                    Text(contentState.isImage ? lang.localized("photo") : lang.localized("3d_model"))
                        .font(.headline)
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onDisappear {
            // Stop accessing security scoped resource when view disappears
            if isAccessingSecurityScope {
                modelURL.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(lang.localized("model_not_found"))
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text(lang.localized("close"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.cyan)
                    .cornerRadius(12)
            }
        }
    }
    
    private func loadContent() {
        // Try with security-scoped access
        isAccessingSecurityScope = modelURL.startAccessingSecurityScopedResource()
        
        // Check if it's a relative path or needs resolution
        let resolvedURL = resolveMediaURL(modelURL)
        
        guard FileManager.default.fileExists(atPath: resolvedURL.path) else {
            contentState = .error("Archivo no encontrado: \(resolvedURL.lastPathComponent)")
            return
        }
        
        let ext = resolvedURL.pathExtension.lowercased()
        
        // Handle images
        if ["jpg", "jpeg", "png", "heic", "heif"].contains(ext) {
            do {
                let data = try Data(contentsOf: resolvedURL)
                #if os(iOS)
                if let image = UIImage(data: data) {
                    loadedImage = image
                    contentState = .image
                    return
                }
                #elseif os(macOS)
                if let image = NSImage(data: data) {
                    loadedImage = image
                    contentState = .image
                    return
                }
                #endif
            } catch {
                print("Error loading image: \(error)")
            }
        }
        
        // Handle 3D models
        if ext == "usdz" {
            // Verify USDZ file is valid
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: resolvedURL.path)
                if let fileSize = attributes[.size] as? Int64, fileSize > 0 {
                    verifiedURL = resolvedURL
                    contentState = .model
                    return
                }
            } catch {
                print("Error checking model file: \(error)")
            }
        }
        
        contentState = .error("Formato no soportado: \(ext)")
    }
    
    private func resolveMediaURL(_ url: URL) -> URL {
        // If it's already an absolute path that exists, use it
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        
        // Try resolving relative to HabitMedia directory
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let mediaDir = documentsDir.appendingPathComponent("HabitMedia", isDirectory: true)
        
        // Check if URL path is just a filename
        let filename = url.lastPathComponent
        let resolvedURL = mediaDir.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: resolvedURL.path) {
            return resolvedURL
        }
        
        // Return original URL if resolution fails
        return url
    }
}

extension Model3DViewer.ContentDisplayState {
    var isImage: Bool {
        if case .image = self { return true }
        return false
    }
}

#if os(iOS)
struct ImageViewerContent: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            }
        }
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        if context.coordinator.url != url {
            context.coordinator.url = url
            uiViewController.reloadData()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL
        private var previewItem: PreviewItem
        
        init(url: URL) {
            self.url = url
            self.previewItem = PreviewItem(url: url)
            super.init()
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 
            // Verify file exists before reporting item count
            return FileManager.default.fileExists(atPath: url.path) ? 1 : 0
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            // Update preview item with current URL
            previewItem = PreviewItem(url: url)
            return previewItem
        }
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    let fileURL: URL
    
    init(url: URL) {
        self.fileURL = url
        super.init()
    }
    
    var previewItemURL: URL? {
        return fileURL
    }
    
    var previewItemTitle: String? {
        return fileURL.deletingPathExtension().lastPathComponent
    }
}
#endif

#if os(macOS)
struct ImageViewerContent: View {
    let image: NSImage
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

struct QuickLookPreview: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.previewItem = PreviewItem(url: url)
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = PreviewItem(url: url)
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    let fileURL: URL
    
    init(url: URL) {
        self.fileURL = url
        super.init()
    }
    
    var previewItemURL: URL? {
        return fileURL
    }
    
    var previewItemTitle: String? {
        return fileURL.deletingPathExtension().lastPathComponent
    }
}
#endif
