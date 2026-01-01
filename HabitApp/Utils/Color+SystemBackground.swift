//
//  Color+SystemBackground.swift
//  HabitApp
//

import SwiftUI

extension Color {
    
    // Main background (light gray in light mode, dark in dark mode)
    static func appBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
        }
    }
    
    // Card/Secondary background (slightly different from main)
    static func appCardBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(red: 0.17, green: 0.17, blue: 0.18) // #2C2C2E
        } else {
            return Color.white
        }
    }
    
    // Tertiary background for nested elements
    static func appTertiaryBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(red: 0.23, green: 0.23, blue: 0.24) // #3A3A3C
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
        }
    }
    
    // Legacy compatibility - keeping old names but with unified colors
    static var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(red: 1, green: 1, blue: 1) // White for light mode default
        #endif
    }
    
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(red: 0.95, green: 0.95, blue: 0.97)
        #endif
    }

    static var label: Color {
        #if os(iOS)
        return Color(UIColor.label)
        #elseif os(macOS)
        return Color(NSColor.labelColor)
        #endif
    }

    static var secondaryLabel: Color {
        #if os(iOS)
        return Color(UIColor.secondaryLabel)
        #elseif os(macOS)
        return Color(NSColor.secondaryLabelColor)
        #endif
    }
}
