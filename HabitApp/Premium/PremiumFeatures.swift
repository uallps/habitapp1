//
//  PremiumFeatures.swift
//  HabitApp
//
//  Central hub for premium feature detection and management
//  This file helps with conditional compilation based on target
//

import Foundation
import SwiftUI

// MARK: - Premium Feature Manager
/// Manages premium feature availability based on target and runtime settings
public struct PremiumFeatures {
    
    /// Check if premium features are available at compile time
    public static var isCompiled: Bool {
        #if PREMIUM
        return true
        #else
        return false
        #endif
    }
    
    /// Check if premium features are enabled (compile time + runtime)
    public static var isEnabled: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.isPremiumUser
        #endif
    }
    
    /// For the free target, premium features can be unlocked via in-app purchase
    /// For the premium target, they are always available
    public static var canUpgrade: Bool {
        #if PREMIUM
        return false // Already premium
        #else
        return !AppConfig.shared.isPremiumUser
        #endif
    }
    
    // MARK: - Feature Checks
    
    public static var hasCameraAI: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.hasCameraFeature
        #endif
    }
    
    public static var hasRecaps: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.isPremiumUser
        #endif
    }
    
    public static var hasAdvancedStatistics: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.hasAdvancedStatistics
        #endif
    }
    
    public static var canAddNotes: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.canAddNotes
        #endif
    }
    
    public static var showAds: Bool {
        #if PREMIUM
        return false
        #else
        return AppConfig.shared.showAds
        #endif
    }
    
    public static var maxHabits: Int {
        #if PREMIUM
        return Int.max
        #else
        return AppConfig.shared.maxHabits
        #endif
    }
    
    public static var hasUnlimitedNotifications: Bool {
        #if PREMIUM
        return true
        #else
        return AppConfig.shared.hasUnlimitedNotifications
        #endif
    }
}

// MARK: - View Extensions for Conditional Premium Content
extension View {
    /// Conditionally shows content only if premium features are enabled
    @ViewBuilder
    func premiumOnly<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if PremiumFeatures.isEnabled {
            content()
        }
    }
    
    /// Shows fallback content when premium is not enabled
    @ViewBuilder
    func premiumOr<PremiumContent: View, FallbackContent: View>(
        @ViewBuilder premium: () -> PremiumContent,
        @ViewBuilder fallback: () -> FallbackContent
    ) -> some View {
        if PremiumFeatures.isEnabled {
            premium()
        } else {
            fallback()
        }
    }
}
