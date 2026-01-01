//
//  CameraHabitView.swift
//  HabitApp
//
//  Premium feature: Camera-based habit creation using AI
//

import SwiftUI
import PhotosUI
import AVFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CameraHabitView: View {
    @EnvironmentObject var store: HabitStore
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var openAI = OpenAIService.shared
    @Environment(\.colorScheme) var colorScheme
    
    #if os(iOS)
    @State private var selectedImage: UIImage?
    #elseif os(macOS)
    @State private var selectedImage: NSImage?
    #endif
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSuggestionSheet = false
    @State private var habitSuggestion: HabitSuggestion?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingCameraUnavailable = false
    
    #if os(iOS)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    #else
    private var isCameraAvailable: Bool {
        false // Camera not available on Mac, use file picker instead
    }
    #endif
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 44))
                                .foregroundColor(.cyan)
                        }
                        
                        Text(lang.localized("ai_camera_title"))
                            .font(.system(size: 26, weight: .bold))
                        
                        Text(lang.localized("ai_camera_subtitle"))
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Selected Image Preview
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            #if os(iOS)
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                            #elseif os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                            #endif
                            
                            Button {
                                selectedImage = nil
                                habitSuggestion = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .shadow(radius: 3)
                            }
                            .offset(x: 10, y: -10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        if selectedImage == nil {
                            #if os(iOS)
                            // Camera Button (iOS only)
                            Button {
                                checkCameraPermissionAndOpen()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 22))
                                    Text(lang.localized("take_photo"))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.cyan)
                                .cornerRadius(14)
                                .shadow(color: Color.cyan.opacity(0.4), radius: 8)
                            }
                            .buttonStyle(.plain)
                            #endif
                            
                            // Gallery Button
                            Button {
                                showingImagePicker = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 22))
                                    Text(lang.localized("choose_gallery"))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                #if os(macOS)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.cyan)
                                .cornerRadius(14)
                                .shadow(color: Color.cyan.opacity(0.4), radius: 8)
                                #else
                                .foregroundColor(.cyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.cyan.opacity(0.15))
                                .cornerRadius(14)
                                #endif
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Analyze Button
                            Button {
                                analyzeImage()
                            } label: {
                                HStack(spacing: 12) {
                                    if openAI.isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 22))
                                    }
                                    Text(openAI.isAnalyzing ? lang.localized("analyzing") : lang.localized("analyze_create_habit"))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(openAI.isAnalyzing ? Color.gray : Color.cyan)
                                .cornerRadius(14)
                                .shadow(color: Color.cyan.opacity(0.4), radius: 8)
                            }
                            .buttonStyle(.plain)
                            .disabled(openAI.isAnalyzing)
                            
                            // Retake Button
                            Button {
                                selectedImage = nil
                                habitSuggestion = nil
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 20))
                                    Text(lang.localized("retake"))
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    #if os(macOS)
                    .padding(.bottom, 120) // Extra padding for floating tab bar
                    #else
                    .padding(.bottom, 60)
                    #endif
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        #elseif os(macOS)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        #endif
        .sheet(isPresented: $showingSuggestionSheet) {
            if let suggestion = habitSuggestion {
                HabitSuggestionSheet(
                    suggestion: suggestion,
                    originalImage: selectedImage,
                    onConfirm: { habit in
                        store.addHabit(habit)
                        selectedImage = nil
                        habitSuggestion = nil
                        showingSuggestionSheet = false
                    },
                    onCancel: {
                        showingSuggestionSheet = false
                    }
                )
            }
        }
        .alert(lang.localized("error"), isPresented: $showingError) {
            Button(lang.localized("ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? lang.localized("unknown_error"))
        }
        #if os(iOS)
        .alert(lang.localized("camera_unavailable"), isPresented: $showingCameraUnavailable) {
            Button(lang.localized("ok"), role: .cancel) {}
            Button(lang.localized("open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(lang.localized("camera_unavailable_message"))
        }
        #endif
    }
    
    #if os(iOS)
    private func checkCameraPermissionAndOpen() {
        guard isCameraAvailable else {
            errorMessage = lang.localized("camera_not_available")
            showingError = true
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showingCameraUnavailable = true
                    }
                }
            }
        case .denied, .restricted:
            showingCameraUnavailable = true
        @unknown default:
            showingCameraUnavailable = true
        }
    }
    #endif
    
    private func analyzeImage() {
        guard let image = selectedImage else { return }
        
        let currentLanguage = lang.language
        
        Task {
            do {
                let suggestion = try await openAI.analyzeImage(image, language: currentLanguage)
                habitSuggestion = suggestion
                
                let existingHabit = store.habits.first { 
                    $0.name.lowercased() == suggestion.name.lowercased() 
                }
                
                if existingHabit != nil {
                    errorMessage = lang.localized("habit_exists")
                    showingError = true
                } else {
                    showingSuggestionSheet = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}


#Preview {
    CameraHabitView()
        .environmentObject(HabitStore.shared)
}
