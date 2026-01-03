//
//  AdsModuleImpl.swift
//  HabitApp
//
//  Módulo de Anuncios - Implementación
//  Autor: Avilés
//  
//  Este módulo gestiona la visualización de anuncios en la versión gratuita.
//  Se inyecta mediante el patrón Protocol + Dependency Injection.
//

import SwiftUI
import Combine
#if os(iOS)
import GoogleMobileAds
#endif

// MARK: - Ads Module Implementation
@MainActor
final class AdsModuleImpl: NSObject, AdsModuleProtocol, ObservableObject {
    
    // MARK: - Module Metadata
    static var moduleId: String = "com.habitapp.module.ads"
    static var moduleName: String = "Ads Module"
    static var moduleAuthor: String = "Avilés"
    static var moduleVersion: String = "1.0.0"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = false
    @Published var isAdLoaded: Bool = false
    @Published var isShowingAd: Bool = false
    @Published var adLoadAttempts: Int = 0
    
    // MARK: - Ad Configuration
    private struct AdUnitIDs {
        static let appID = "ca-app-pub-3940256099942544~1458002511"
        static let interstitial = "ca-app-pub-3940256099942544/1033173712"
    }
    
    #if os(iOS)
    private var interstitialAd: InterstitialAd?
    #endif
    
    private var onAdDismissed: (() -> Void)?
    
    // MARK: - Protocol Properties
    var isAdMobConfigured: Bool {
        #if os(iOS)
        let configured = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String != nil
        return configured
        #else
        return false
        #endif
    }
    
    var shouldShowAds: Bool {
        #if PREMIUM
        return false
        #else
        return AppConfig.shared.showAds
        #endif
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        print("[\(Self.moduleName)] Module instance created")
    }
    
    // MARK: - Module Lifecycle
    func initialize() {
        guard !isEnabled else { return }
        
        print("[\(Self.moduleName)] Initializing...")
        
        #if os(iOS)
        if isAdMobConfigured && shouldShowAds {
            MobileAds.shared.start { [weak self] status in
                print("[\(Self.moduleName)] AdMob SDK initialized")
                Task { @MainActor in
                    self?.loadInterstitialAd()
                }
            }
        }
        #endif
        
        isEnabled = true
        print("[\(Self.moduleName)] Initialized successfully")
    }
    
    func cleanup() {
        print("[\(Self.moduleName)] Cleaning up...")
        #if os(iOS)
        interstitialAd = nil
        #endif
        isAdLoaded = false
        isEnabled = false
    }
    
    // MARK: - Ad Loading
    func loadInterstitialAd() {
        #if os(iOS)
        adLoadAttempts += 1
        
        guard shouldShowAds else {
            print("[\(Self.moduleName)] Ads disabled (Premium mode)")
            return
        }
        
        guard isAdMobConfigured else {
            print("[\(Self.moduleName)] AdMob not configured in Info.plist")
            return
        }
        
        print("[\(Self.moduleName)] Loading interstitial ad (attempt \(adLoadAttempts))...")
        
        let request = Request()
        InterstitialAd.load(with: AdUnitIDs.interstitial, request: request) { [weak self] ad, error in
            Task { @MainActor in
                if let error = error {
                    print("[\(Self.moduleName)] Error loading ad: \(error.localizedDescription)")
                    self?.isAdLoaded = false
                    
                    // Retry after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self?.loadInterstitialAd()
                    }
                    return
                }
                
                print("[\(Self.moduleName)] Ad loaded successfully")
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isAdLoaded = true
            }
        }
        #endif
    }
    
    // MARK: - Ad Display
    func showInterstitialAd(from rootViewController: Any?, completion: (() -> Void)?) {
        #if os(iOS)
        guard shouldShowAds else {
            print("[\(Self.moduleName)] Ads disabled, skipping")
            completion?()
            return
        }
        
        guard isAdLoaded, let ad = interstitialAd else {
            print("[\(Self.moduleName)] No ad loaded")
            completion?()
            loadInterstitialAd()
            return
        }
        
        guard let viewController = rootViewController as? UIViewController else {
            print("[\(Self.moduleName)] Invalid view controller")
            completion?()
            return
        }
        
        onAdDismissed = completion
        isShowingAd = true
        
        print("[\(Self.moduleName)] Showing interstitial ad...")
        ad.present(from: viewController)
        #else
        completion?()
        #endif
    }
}

// MARK: - Full Screen Content Delegate
#if os(iOS)
extension AdsModuleImpl: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("[\(Self.moduleName)] Ad dismissed")
            isShowingAd = false
            isAdLoaded = false
            onAdDismissed?()
            onAdDismissed = nil
            loadInterstitialAd()
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("[\(Self.moduleName)] Ad failed to present: \(error.localizedDescription)")
            isShowingAd = false
            onAdDismissed?()
            onAdDismissed = nil
            loadInterstitialAd()
        }
    }
}
#endif

// MARK: - Factory
struct AdsModuleFactory: ModuleFactoryProtocol {
    typealias ModuleType = AdsModuleImpl
    
    static func create() -> AdsModuleImpl {
        return AdsModuleImpl()
    }
}
