import SwiftUI
import UserNotifications
#if os(iOS)
import GoogleMobileAds
#endif

@main
struct HabitAppApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var store = HabitStore.shared
    @StateObject private var appConfig = AppConfig.shared

    init() {
        #if os(iOS)
        print("[v0] ========================================")
        print("[v0] Inicializando HabitAppApp...")
        print("[v0] Verificando GADApplicationIdentifier...")
       
        if let appId = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String {
            print("[v0] GADApplicationIdentifier encontrado: \(appId)")
            print("[v0] Iniciando Google Mobile Ads SDK...")
           
            MobileAds.shared.start { status in
                print("[v0] Google Mobile Ads SDK inicializado")
                print("[v0] Estado de adaptadores: \(status.adapterStatusesByClassName)")
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("[v0] Forzando carga inicial del anuncio...")
                    AdManager.shared.loadInterstitialAd()
                }
            }
        } else {
            print("[v0] ⚠️ ERROR: GADApplicationIdentifier NO está en Info.plist")
            print("[v0] Los anuncios estarán deshabilitados")
        }
        print("[v0] ========================================")
        #endif
       
        #if os(iOS) || os(macOS)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
       
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if let error = error {
                print("Error solicitando permisos de notificación: \(error.localizedDescription)")
            } else {
                print("Permiso de notificaciones: \(success)")
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, languageManager.currentLocale)
                .onAppear {
                    store.rescheduleAllNotifications()
                }
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 650)
                #endif
        }
        #if os(macOS)
        .windowStyle(.automatic)
        #endif
    }
}
