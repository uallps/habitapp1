import SwiftUI
import Combine
#if os(iOS)
import GoogleMobileAds
#endif

// MARK: - Ad Manager para Google AdMob
@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
   
    struct AdUnitIDs {
        static let appID = "ca-app-pub-3940256099942544~1458002511"
        static let interstitial = "ca-app-pub-3940256099942544/1033173712"
    }
   
    #if os(iOS)
    private var interstitialAd: InterstitialAd?
    #endif
   
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var adLoadAttempts = 0
   
    private var onAdDismissed: (() -> Void)?
   
    var isAdMobConfigured: Bool {
        #if os(iOS)
        let configured = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String != nil
        print("[v0] AdMob configurado en Info.plist: \(configured)")
        return configured
        #else
        print("[v0] AdMob no disponible en macOS")
        return false
        #endif
    }
   
    private override init() {
        super.init()
        print("[v0] AdManager inicializado")
        print("[v0] showAds desde AppConfig: \(AppConfig.shared.showAds)")
        print("[v0] isAdMobConfigured: \(isAdMobConfigured)")
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadInterstitialAd()
        }
    }
   
    // MARK: - Inicializar SDK manualmente
    func initializeSDK() {
        #if os(iOS)
        print("[v0] Intentando inicializar SDK de AdMob...")
        if isAdMobConfigured {
            MobileAds.shared.start { status in
                print("[v0] SDK de AdMob inicializado - Estado: \(status)")
                Task { @MainActor in
                    self.loadInterstitialAd()
                }
            }
        } else {
            print("[v0] ERROR: GADApplicationIdentifier no está en Info.plist")
        }
        #endif
    }
   
    // MARK: - Cargar anuncio intersticial
    func loadInterstitialAd() {
        #if os(iOS)
        adLoadAttempts += 1
        print("[v0] ========================================")
        print("[v0] Intentando cargar anuncio intersticial...")
        print("[v0] Intento número: \(adLoadAttempts)")
        print("[v0] showAds: \(AppConfig.shared.showAds)")
        print("[v0] isAdMobConfigured: \(isAdMobConfigured)")
       
        guard AppConfig.shared.showAds else {
            print("[v0] ERROR: showAds es false, no se cargan anuncios (versión Premium)")
            return
        }
       
        guard isAdMobConfigured else {
            print("[v0] ERROR: AdMob NO está configurado en Info.plist")
            return
        }
       
        print("[v0] Creando Request para ad unit: \(AdUnitIDs.interstitial)")
        let request = Request()
       
        InterstitialAd.load(with: AdUnitIDs.interstitial, request: request) { [weak self] ad, error in
            Task { @MainActor in
                if let error = error {
                    print("[v0] ERROR cargando anuncio: \(error.localizedDescription)")
                    print("[v0] Código de error: \((error as NSError).code)")
                    print("[v0] Dominio de error: \((error as NSError).domain)")
                    self?.isAdLoaded = false
                   
                    print("[v0] Reintentando carga en 5 segundos...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self?.loadInterstitialAd()
                    }
                    return
                }
               
                print("[v0] ÉXITO: Anuncio intersticial cargado correctamente")
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isAdLoaded = true
                print("[v0] isAdLoaded ahora es: \(self?.isAdLoaded ?? false)")
                print("[v0] ========================================")
            }
        }
        #else
        print("[v0] Anuncios no disponibles en macOS")
        #endif
    }
   
    // MARK: - Mostrar anuncio intersticial
    func showInterstitialAd(from viewController: Any? = nil, onDismiss: (() -> Void)? = nil) {
        print("[v0] ========================================")
        print("[v0] showInterstitialAd() llamado")
        print("[v0] showAds: \(AppConfig.shared.showAds)")
        print("[v0] isAdLoaded: \(isAdLoaded)")
        print("[v0] isAdMobConfigured: \(isAdMobConfigured)")
       
        #if os(iOS)
        guard AppConfig.shared.showAds else {
            print("[v0] showAds es false, ejecutando onDismiss directamente")
            onDismiss?()
            return
        }
       
        guard isAdMobConfigured else {
            print("[v0] AdMob no configurado, ejecutando onDismiss directamente")
            onDismiss?()
            return
        }
       
        self.onAdDismissed = onDismiss
       
        guard let ad = interstitialAd else {
            print("[v0] ERROR: El anuncio NO está listo (interstitialAd es nil)")
            print("[v0] Cargando uno nuevo y ejecutando onDismiss...")
            loadInterstitialAd()
            onDismiss?()
            return
        }
       
        print("[v0] Anuncio disponible, buscando rootViewController...")
       
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
           
            print("[v0] ViewController encontrado: \(type(of: topVC))")
            print("[v0] Mostrando anuncio...")
            isShowingAd = true
            ad.present(from: topVC)
        } else {
            print("[v0] ERROR: No se pudo obtener rootViewController")
            onDismiss?()
        }
        #else
        print("[v0] macOS: ejecutando onDismiss directamente")
        onDismiss?()
        #endif
        print("[v0] ========================================")
    }
}

// MARK: - FullScreenContentDelegate
#if os(iOS)
extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[v0] Anuncio cerrado por el usuario")
        Task { @MainActor in
            self.isShowingAd = false
            self.interstitialAd = nil
            self.isAdLoaded = false
            self.onAdDismissed?()
            self.onAdDismissed = nil
            print("[v0] Cargando nuevo anuncio después de cerrar...")
            self.loadInterstitialAd()
        }
    }
   
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[v0] ERROR mostrando anuncio: \(error.localizedDescription)")
        Task { @MainActor in
            self.isShowingAd = false
            self.interstitialAd = nil
            self.isAdLoaded = false
            self.onAdDismissed?()
            self.onAdDismissed = nil
            self.loadInterstitialAd()
        }
    }
   
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[v0] ÉXITO: Anuncio a punto de mostrarse en pantalla completa")
    }
   
    nonisolated func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("[v0] Impresión del anuncio registrada")
    }
   
    nonisolated func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("[v0] Click en el anuncio registrado")
    }
}
#endif
