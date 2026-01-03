import SwiftUI
import AVFoundation
import PhotosUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct HabitCompletionSheet: View {
    @EnvironmentObject var store: HabitStore
    @ObservedObject private var completionStore = CompletionStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    let habit: Habit
    @State private var noteText: String = ""
    #if os(iOS)
    @State private var selectedImage: UIImage?
    @State private var capturedFallbackImage: UIImage?
    #elseif os(macOS)
    @State private var selectedImage: NSImage?
    @State private var capturedFallbackImage: NSImage?
    #endif
    @State private var model3DURL: URL?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showObjectCapture = false
    @State private var mediaType: MediaChoice = .none
    @State private var isProcessing = false
    @State private var showCameraAlert = false
    @State private var show3DNotSupportedAlert = false
    
    enum MediaChoice {
        case none, image, model3D
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    completionHeader
                    noteSection
                    mediaSection
                    
                    if let image = selectedImage ?? capturedFallbackImage {
                        imagePreviewSection(image: image)
                    }
                    
                    #if os(iOS)
                    if model3DURL != nil {
                        model3DPreview
                    }
                    #endif
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.1),
                        Color.appBackground(for: colorScheme)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lang.localized("skip")) {
                        saveAndDismiss(skipMedia: true)
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.localized("save")) {
                        saveAndDismiss(skipMedia: false)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                    .disabled(isProcessing)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.localized("skip")) {
                        saveAndDismiss(skipMedia: true)
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.localized("save")) {
                        saveAndDismiss(skipMedia: false)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                    .disabled(isProcessing)
                }
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .fullScreenCover(isPresented: $showObjectCapture) {
                ObjectCaptureContainerView { result in
                    handleCaptureResult(result)
                }
            }
            .alert(lang.localized("camera_unavailable"), isPresented: $showCameraAlert) {
                Button(lang.localized("open_settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(lang.localized("ok"), role: .cancel) {}
            } message: {
                Text(lang.localized("camera_unavailable_message"))
            }
            .alert(lang.localized("3d_not_supported_title"), isPresented: $show3DNotSupportedAlert) {
                Button(lang.localized("take_photo_instead")) {
                    checkCameraAndShow()
                }
                Button(lang.localized("ok"), role: .cancel) {}
            } message: {
                Text(lang.localized("3d_not_supported_message"))
            }
            #elseif os(macOS)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            #endif
        }
    }
    
    private func handleCaptureResult(_ result: CaptureResult) {
        switch result {
        case .model(let url):
            model3DURL = url
            mediaType = .model3D
            capturedFallbackImage = nil
            selectedImage = nil
        case .image(let image):
            capturedFallbackImage = image
            selectedImage = nil
            mediaType = .image
            model3DURL = nil
        case .none:
            break
        }
    }
    
    // MARK: - Completion Header
    private var completionHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 15, y: 5)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text(lang.localized("habit_completed"))
                    .font(.title2.bold())
                
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.cyan)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(habit.currentStreak + 1) \(lang.localized("day_streak"))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(lang.localized("add_note"), systemImage: "note.text")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(lang.localized("note_placeholder"))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $noteText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(Color.appCardBackground(for: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(lang.localized("capture_moment"), systemImage: "camera.fill")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                MediaOptionButton(
                    icon: "photo.fill",
                    title: lang.localized("photo"),
                    isSelected: mediaType == .image && (selectedImage != nil || capturedFallbackImage != nil),
                    color: .blue
                ) {
                    showImageOptions()
                }
                #if os(iOS)
                MediaOptionButton(
                    icon: "cube.fill",
                    title: lang.localized("3d_model"),
                    isSelected: mediaType == .model3D && model3DURL != nil,
                    color: .purple
                ) {
                    start3DCapture()
                }
                #endif
            }
        }
    }
    
    // MARK: - Image Preview
    #if os(iOS)
    private func imagePreviewSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(lang.localized("preview"), systemImage: "photo")
                    .font(.headline)
                Spacer()
                Button(action: {
                    selectedImage = nil
                    capturedFallbackImage = nil
                    mediaType = .none
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        }
    }
    #elseif os(macOS)
    private func imagePreviewSection(image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(lang.localized("preview"), systemImage: "photo")
                    .font(.headline)
                Spacer()
                Button(action: {
                    selectedImage = nil
                    capturedFallbackImage = nil
                    mediaType = .none
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        }
    }
    #endif
    
    // MARK: - 3D Model Preview
    #if os(iOS)
    private var model3DPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(lang.localized("3d_preview"), systemImage: "cube.fill")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // Delete the temp model file
                    if let url = model3DURL {
                        try? FileManager.default.removeItem(at: url)
                    }
                    model3DURL = nil
                    mediaType = .none
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                
                VStack(spacing: 12) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                    
                    Text(lang.localized("3d_model_ready"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    #endif
    
    // MARK: - Actions
    #if os(iOS)
    private func showImageOptions() {
        let actionSheet = UIAlertController(
            title: lang.localized("choose_source"),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: lang.localized("take_photo"), style: .default) { _ in
                checkCameraAndShow()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: lang.localized("choose_gallery"), style: .default) { _ in
            mediaType = .image
            model3DURL = nil
            capturedFallbackImage = nil
            showImagePicker = true
        })
        
        actionSheet.addAction(UIAlertAction(title: lang.localized("cancel"), style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(actionSheet, animated: true)
        }
    }
    
    private func checkCameraAndShow() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            mediaType = .image
            model3DURL = nil
            capturedFallbackImage = nil
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        mediaType = .image
                        model3DURL = nil
                        capturedFallbackImage = nil
                        showCamera = true
                    }
                }
            }
        default:
            showCameraAlert = true
        }
    }
    
    private func start3DCapture() {
        #if targetEnvironment(simulator)
        show3DNotSupportedAlert = true
        #else
        selectedImage = nil
        capturedFallbackImage = nil
        showObjectCapture = true
        #endif
    }
    #elseif os(macOS)
    private func showImageOptions() {
        // En macOS, mostrar directamente el picker de archivos
        mediaType = .image
        model3DURL = nil
        capturedFallbackImage = nil
        showImagePicker = true
    }
    #endif
    
    private func saveAndDismiss(skipMedia: Bool) {
        isProcessing = true
        
        var completion = HabitCompletion(
            habitId: habit.id,
            date: Date(),
            note: noteText.isEmpty ? nil : noteText
        )
        
        if !skipMedia {
            #if os(iOS)
            if let modelURL = model3DURL {
                if let savedPath = completionStore.saveModel3D(from: modelURL, for: &completion) {
                    print("Model saved at: \(savedPath)")
                }
            } else if let image = selectedImage ?? capturedFallbackImage {
                _ = completionStore.saveImage(image, for: &completion)
            }
            #elseif os(macOS)
            if let image = selectedImage ?? capturedFallbackImage {
                _ = completionStore.saveImageMac(image, for: &completion)
            }
            #endif
        }
        
        completionStore.addCompletion(completion)
        
        if !noteText.isEmpty {
            store.setNote(noteText, for: habit, on: Date())
        }
        
        // Registrar en gamificación - llamar directamente al Store
        let streak = store.calculateStreak(for: habit)
        print("[HabitCompletionSheet] Recording completion - streak: \(streak), category: \(habit.iconName)")
        GamificationStore.shared.habitCompleted(streak: streak, category: habit.iconName)
        
        // Registrar foto si se añadió
        if selectedImage != nil || capturedFallbackImage != nil {
            print("[HabitCompletionSheet] Recording photo added")
            GamificationStore.shared.photoAdded()
        }
        
        // Registrar modelo 3D si se añadió
        #if os(iOS)
        if model3DURL != nil {
            print("[HabitCompletionSheet] Recording 3D model created")
            GamificationStore.shared.model3DCreated()
        }
        #endif
        
        isProcessing = false
        dismiss()
    }
}

// MARK: - Media Option Button
struct MediaOptionButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appCardBackground(for: nil))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extension
extension Color {
    static func appCardBackground(for colorScheme: ColorScheme?) -> Color {
        #if os(iOS)
        if let scheme = colorScheme {
            return scheme == .dark ? Color(.systemGray6) : Color.white
        }
        return Color(.systemBackground)
        #elseif os(macOS)
        if let scheme = colorScheme {
            return scheme == .dark ? Color(NSColor.controlBackgroundColor) : Color.white
        }
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
}
