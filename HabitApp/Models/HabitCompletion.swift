import Foundation

struct HabitCompletion: Identifiable, Codable {
    var id = UUID()
    var habitId: UUID
    var date: Date
    var note: String?
    var imagePath: String?      // Path to saved image
    var model3DPath: String?    // Path to saved USDZ model
    var mediaType: MediaType?
    
    enum MediaType: String, Codable {
        case image
        case model3D
    }
}

// Extension for managing completion media
extension HabitCompletion {
    var hasMedia: Bool {
        return imagePath != nil || model3DPath != nil
    }
    
    var mediaIcon: String {
        switch mediaType {
        case .image: return "photo.fill"
        case .model3D: return "cube.fill"
        case .none: return "doc.fill"
        }
    }
}
