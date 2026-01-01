//
//  ImagePicker.swift
//  HabitApp
//
//  Shared Image picker wrapper for iOS and macOS
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
internal import UniformTypeIdentifiers
#endif

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#if os(macOS)
struct ImagePicker: View {
    @Binding var image: NSImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Seleccionar imagen")
                .font(.headline)
            
            Button("Elegir archivo...") {
                selectImage()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancelar") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(minWidth: 300, minHeight: 150)
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK, let url = panel.url {
            if let nsImage = NSImage(contentsOf: url) {
                image = nsImage
            }
        }
        dismiss()
    }
}
#endif

// MARK: - Cross-platform Image type alias
#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif
