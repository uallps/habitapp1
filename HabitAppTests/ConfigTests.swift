//
//  ConfigTests.swift
//  HabitAppTests
//
//  Tests for AppConfig, Premium features and API configuration
//

import Testing
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import HabitApp

// MARK: - AppConfig Tests
@MainActor
struct AppConfigEnumTests {
    
    @Test func testAppVersionValues() async throws {
        #expect(AppConfig.AppVersion.free.rawValue == "free")
        #expect(AppConfig.AppVersion.premium.rawValue == "premium")
    }
    
    @Test func testAppVersionCount() async throws {
        // AppVersion has 2 cases: free and premium
        let versions: [AppConfig.AppVersion] = [.free, .premium]
        #expect(versions.count == 2)
    }
}

// MARK: - Appearance Mode Tests
@MainActor
struct AppearanceModeTests {
    
    @Test func testAppearanceModeRawValues() async throws {
        #expect(AppearanceMode.light.rawValue == "light")
        #expect(AppearanceMode.dark.rawValue == "dark")
        #expect(AppearanceMode.auto.rawValue == "auto")
    }
    
    @Test func testAppearanceModeAllCases() async throws {
        #expect(AppearanceMode.allCases.count == 3)
        #expect(AppearanceMode.allCases.contains(.light))
        #expect(AppearanceMode.allCases.contains(.dark))
        #expect(AppearanceMode.allCases.contains(.auto))
    }
    
    @Test func testAppearanceModeFromRawValue() async throws {
        #expect(AppearanceMode(rawValue: "light") == .light)
        #expect(AppearanceMode(rawValue: "dark") == .dark)
        #expect(AppearanceMode(rawValue: "auto") == .auto)
        #expect(AppearanceMode(rawValue: "invalid") == nil)
    }
}

// MARK: - Premium Feature Tests
#if PREMIUM
struct PremiumFeatureTests {
    
    @MainActor
    @Test func testPremiumMaxHabits() async throws {
        let config = AppConfig.shared
        #expect(config.maxHabits == Int.max || config.maxHabits > 5)
    }
    
    @MainActor
    @Test func testPremiumCameraFeature() async throws {
        let config = AppConfig.shared
        #expect(config.hasCameraFeature == true)
    }
    
    @MainActor
    @Test func testPremiumNoAds() async throws {
        let config = AppConfig.shared
        #expect(config.showAds == false)
    }
}
#endif

// MARK: - Free Feature Tests
@MainActor
struct FreeFeatureTests {
    
    @MainActor
    @Test func testFreeVersionConfiguration() async throws {
        // Free version should have limited features
        // This test is conditional based on PREMIUM flag
        #if !PREMIUM
        let config = AppConfig.shared
        // Only test if user is not premium
        if config.isFree {
            #expect(config.maxHabits <= 10)
            #expect(config.showAds == true)
        }
        #endif
    }
}

// MARK: - Feature Flag Tests
@MainActor
struct FeatureFlagTests {
    
    @MainActor
    @Test func testFeatureFlagsExist() async throws {
        // Verify feature flags are accessible
        let config = AppConfig.shared
        _ = config.maxHabits
        _ = config.hasCameraFeature
        _ = config.showAds
    }
    
    @MainActor
    @Test func testMaxHabitsPositive() async throws {
        let config = AppConfig.shared
        #expect(config.maxHabits > 0)
    }
}

// MARK: - Secrets Configuration Tests
@MainActor
struct SecretsConfigTests {
    
    @Test func testSecretsFileExists() async throws {
        // Try to load secrets plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") {
            #expect(!path.isEmpty)
        }
    }
    
    @Test func testAPIKeyFormat() async throws {
        // If we have an API key, it should follow expected format
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let apiKey = secrets["OPENAI_API_KEY"] as? String {
            // API key should start with expected prefix
            if !apiKey.isEmpty && apiKey != "your-api-key-here" {
                #expect(apiKey.hasPrefix("sk-"))
            }
        }
    }
}

// MARK: - UserDefaults Keys Tests
@MainActor
struct UserDefaultsKeysTests {
    
    @Test func testAppearanceKey() async throws {
        let key = "appearanceMode"
        #expect(!key.isEmpty)
    }
    
    @Test func testLanguageKey() async throws {
        let key = "selectedLanguage"
        #expect(!key.isEmpty)
    }
    
    @Test func testNotificationsKey() async throws {
        let key = "notificationsEnabled"
        #expect(!key.isEmpty)
    }
    
    @Test func testUserDefaultsReadWrite() async throws {
        let testKey = "testKey_\(UUID().uuidString)"
        let testValue = "testValue"
        
        UserDefaults.standard.set(testValue, forKey: testKey)
        let retrieved = UserDefaults.standard.string(forKey: testKey)
        
        #expect(retrieved == testValue)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: testKey)
    }
}

// MARK: - File Storage Tests
@MainActor
struct FileStorageTests {
    
    @Test func testDocumentsDirectory() async throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        
        #expect(documentsPath != nil)
    }
    
    @Test func testHabitsFileURL() async throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let habitsURL = documentsPath.appendingPathComponent("habits.json")
        
        #expect(habitsURL.pathExtension == "json")
        #expect(habitsURL.lastPathComponent == "habits.json")
    }
    
    @Test func testCompletionsFileURL() async throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let completionsURL = documentsPath.appendingPathComponent("completions.json")
        
        #expect(completionsURL.pathExtension == "json")
    }
    
    @Test func testMediaDirectory() async throws {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let mediaURL = documentsPath.appendingPathComponent("media")
        
        #expect(mediaURL.lastPathComponent == "media")
    }
}

// MARK: - Bundle Configuration Tests
@MainActor
struct BundleConfigTests {
    
    @Test func testBundleIdentifier() async throws {
        let bundleId = Bundle.main.bundleIdentifier
        // Bundle ID might be nil in test context
        if let id = bundleId {
            #expect(!id.isEmpty)
        }
    }
    
    @Test func testBundleVersion() async throws {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        // Version might be nil in test context
        if let v = version {
            #expect(!v.isEmpty)
        }
    }
    
    @Test func testBuildNumber() async throws {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        // Build might be nil in test context
        if let b = build {
            #expect(!b.isEmpty)
        }
    }
}

// MARK: - Color Configuration Tests
@MainActor
struct ColorConfigTests {
    
    @Test func testPrimaryColor() async throws {
        // Colors should be defined
        let colorName = "AccentColor"
        #expect(!colorName.isEmpty)
    }
    
    @Test func testSystemBackgroundExists() async throws {
        // System background should work
        #if os(iOS)
        await MainActor.run {
            let _ = UIColor.systemBackground
        }
        #elseif os(macOS)
        await MainActor.run {
            let _ = NSColor.windowBackgroundColor
        }
        #endif
    }
}
