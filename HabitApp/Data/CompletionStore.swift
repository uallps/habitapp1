import Foundation
import SwiftUI
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class CompletionStore: ObservableObject {
    static let shared = CompletionStore()
    
    @Published var completions: [HabitCompletion] = []
    
    private let fileName = "completions.json"
    private let fileURL: URL
    private let mediaDirectory: URL
    
    #if os(iOS)
    private var imageCache = NSCache<NSString, UIImage>()
    #elseif os(macOS)
    private var imageCache = NSCache<NSString, NSImage>()
    #endif
    
    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = directory.appendingPathComponent(fileName)
        mediaDirectory = directory.appendingPathComponent("HabitMedia", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 50 * 1024 * 1024
        
        loadCompletions()
    }
    
    // MARK: - CRUD
    func addCompletion(_ completion: HabitCompletion) {
        removeCompletion(for: completion.habitId, on: completion.date)
        completions.append(completion)
        saveCompletions()
    }
    
    func updateCompletion(_ completion: HabitCompletion) {
        if let index = completions.firstIndex(where: { $0.id == completion.id }) {
            completions[index] = completion
            saveCompletions()
        }
    }
    
    func getCompletion(for habitId: UUID, on date: Date) -> HabitCompletion? {
        let calendar = Calendar.current
        return completions.first { completion in
            completion.habitId == habitId &&
            calendar.isDate(completion.date, inSameDayAs: date)
        }
    }
    
    func getCompletions(for date: Date) -> [HabitCompletion] {
        let calendar = Calendar.current
        return completions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getCompletions(for habitId: UUID) -> [HabitCompletion] {
        return completions.filter { $0.habitId == habitId }
    }
    
    func getCompletionsInRange(from startDate: Date, to endDate: Date) -> [HabitCompletion] {
        return completions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func removeCompletion(for habitId: UUID, on date: Date) {
        let calendar = Calendar.current
        if let index = completions.firstIndex(where: { completion in
            completion.habitId == habitId &&
            calendar.isDate(completion.date, inSameDayAs: date)
        }) {
            let completion = completions[index]
            deleteMediaFiles(for: completion)
            if let path = completion.imagePath {
                imageCache.removeObject(forKey: path as NSString)
            }
            completions.remove(at: index)
            saveCompletions()
        }
    }
    
    func deleteCompletion(_ completion: HabitCompletion) {
        deleteMediaFiles(for: completion)
        if let path = completion.imagePath {
            imageCache.removeObject(forKey: path as NSString)
        }
        completions.removeAll { $0.id == completion.id }
        saveCompletions()
    }
    
    func deleteAllCompletions() {
        for completion in completions {
            deleteMediaFiles(for: completion)
        }
        completions.removeAll()
        saveCompletions()
        
        imageCache.removeAllObjects()
        
        try? FileManager.default.removeItem(at: mediaDirectory)
        try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Media Management
    #if os(iOS)
    func saveImage(_ image: UIImage, for completion: inout HabitCompletion) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let filename = "\(completion.id.uuidString)_image.jpg"
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            completion.imagePath = filename
            completion.mediaType = .image
            imageCache.setObject(image, forKey: filename as NSString)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    #elseif os(macOS)
    func saveImageMac(_ image: NSImage, for completion: inout HabitCompletion) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else { return nil }
        let filename = "\(completion.id.uuidString)_image.jpg"
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            completion.imagePath = filename
            completion.mediaType = .image
            imageCache.setObject(image, forKey: filename as NSString)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    #endif
    
    func saveModel3D(from sourceURL: URL, for completion: inout HabitCompletion) -> String? {
        let filename = "\(completion.id.uuidString)_model.usdz"
        let destinationURL = mediaDirectory.appendingPathComponent(filename)
        
        do {
            // Remove existing file if any
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Check if source exists
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                print("Source model file does not exist: \(sourceURL.path)")
                return nil
            }
            
            // If source is already in our media directory, just rename it
            if sourceURL.deletingLastPathComponent().path == mediaDirectory.path {
                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            }
            
            completion.model3DPath = filename
            completion.mediaType = .model3D
            
            print("Model saved successfully to: \(destinationURL.path)")
            return filename
        } catch {
            print("Error saving 3D model: \(error)")
            return nil
        }
    }
    
    func getImageURL(for completion: HabitCompletion) -> URL? {
        guard let path = completion.imagePath else { return nil }
        return mediaDirectory.appendingPathComponent(path)
    }
    
    func getModel3DURL(for completion: HabitCompletion) -> URL? {
        guard let path = completion.model3DPath else { return nil }
        let url = mediaDirectory.appendingPathComponent(path)
        
        // Verify file exists
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        
        print("Model file not found at: \(url.path)")
        return nil
    }
    
    #if os(iOS)
    func loadImage(for completion: HabitCompletion) -> UIImage? {
        guard let path = completion.imagePath else { return nil }
        
        if let cached = imageCache.object(forKey: path as NSString) {
            return cached
        }
        
        let url = mediaDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        
        imageCache.setObject(image, forKey: path as NSString)
        return image
    }
    
    func loadImageAsync(for completion: HabitCompletion) async -> UIImage? {
        guard let path = completion.imagePath else { return nil }
        
        if let cached = imageCache.object(forKey: path as NSString) {
            return cached
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let url = self.mediaDirectory.appendingPathComponent(path)
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                Task { @MainActor in
                    self.imageCache.setObject(image, forKey: path as NSString)
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    #elseif os(macOS)
    func loadImage(for completion: HabitCompletion) -> NSImage? {
        guard let path = completion.imagePath else { return nil }
        
        if let cached = imageCache.object(forKey: path as NSString) {
            return cached
        }
        
        let url = mediaDirectory.appendingPathComponent(path)
        guard let image = NSImage(contentsOf: url) else { return nil }
        
        imageCache.setObject(image, forKey: path as NSString)
        return image
    }
    
    func loadImageAsync(for completion: HabitCompletion) async -> NSImage? {
        guard let path = completion.imagePath else { return nil }
        
        if let cached = imageCache.object(forKey: path as NSString) {
            return cached
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let url = self.mediaDirectory.appendingPathComponent(path)
                guard let image = NSImage(contentsOf: url) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                Task { @MainActor in
                    self.imageCache.setObject(image, forKey: path as NSString)
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    #endif
    
    private func deleteMediaFiles(for completion: HabitCompletion) {
        if let imagePath = completion.imagePath {
            let imageURL = mediaDirectory.appendingPathComponent(imagePath)
            try? FileManager.default.removeItem(at: imageURL)
        }
        if let modelPath = completion.model3DPath {
            let modelURL = mediaDirectory.appendingPathComponent(modelPath)
            try? FileManager.default.removeItem(at: modelURL)
        }
    }
    
    // MARK: - Persistence
    private func saveCompletions() {
        let completionsToSave = completions
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(completionsToSave)
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
                print("Error saving completions: \(error)")
            }
        }
    }
    
    private func loadCompletions() {
        do {
            let data = try Data(contentsOf: fileURL)
            completions = try JSONDecoder().decode([HabitCompletion].self, from: data)
        } catch {
            completions = []
        }
    }
    
    // MARK: - Statistics
    func getCompletedHabitsCount(in range: DateInterval) -> Int {
        let completionsInRange = completions.filter { $0.date >= range.start && $0.date < range.end }
        var uniqueCompletions = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for completion in completionsInRange {
            let key = "\(completion.habitId.uuidString)_\(dateFormatter.string(from: completion.date))"
            uniqueCompletions.insert(key)
        }
        
        return uniqueCompletions.count
    }
    
    func getUniqueCompletionsPerDay(in range: DateInterval) -> [Date: Set<UUID>] {
        var result: [Date: Set<UUID>] = [:]
        let calendar = Calendar.current
        
        let completionsInRange = completions.filter { $0.date >= range.start && $0.date < range.end }
        
        for completion in completionsInRange {
            let day = calendar.startOfDay(for: completion.date)
            if result[day] == nil {
                result[day] = Set<UUID>()
            }
            result[day]?.insert(completion.habitId)
        }
        
        return result
    }
    
    func getMediaCount(in range: DateInterval, type: HabitCompletion.MediaType? = nil) -> Int {
        return completions.filter { completion in
            completion.date >= range.start &&
            completion.date < range.end &&
            (type == nil ? completion.hasMedia : completion.mediaType == type)
        }.count
    }
    
    func getFeaturedImages(in range: DateInterval, limit: Int = 6) -> [HabitCompletion] {
        return completions
            .filter { $0.date >= range.start && $0.date < range.end && $0.imagePath != nil }
            .prefix(limit)
            .map { $0 }
    }
}
