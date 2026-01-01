import SwiftUI
import Combine

class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()

    @Published var bannerTitle: String = ""
    @Published var bannerMessage: String = ""
    @Published var showBanner: Bool = false

    private init() {}

    func show(title: String, message: String) {
        bannerTitle = title
        bannerMessage = message

        withAnimation {
            showBanner = true
        }

        // Ocultar banner después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showBanner = false
            }
        }
    }
}
