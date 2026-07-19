// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI
import UIKit

// Tier 3 "glass" design tokens — SwiftUI-native implementation of the
// canonical spec in DESIGN_TOKENS.md, targeting iOS 26+ exclusively (the
// whole target's deployment floor is 26.0, so no @available guards are
// needed within this file). Values are hand-ported from Tier 1's
// DOLColor/DOLTypography/DOLSpacing/DOLRadius (dolphin-ios-ui, same
// relative path, same values) — this file's glassCard(_:) uses the real
// .glassEffect()/GlassEffectContainer APIs instead of Tier 1's hand-rolled
// UIVisualEffectView or Tier 2's .ultraThinMaterial simulation.

enum DOLColor {
  static let backgroundPrimary = Color(light: "#F5F6F8", dark: "#0B0C10")
  static let backgroundSecondary = Color(light: "#FFFFFF", dark: "#16171C")

  static let accentSolid = Color(light: "#2455FF", dark: "#4B7CFF")
  static let accentGradient = LinearGradient(
    colors: [Color(hex: "#3217FF"), Color(hex: "#1792FF")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let textPrimary = Color(light: "#101114", dark: "#F2F3F5")
  static let textSecondary = Color(light: "#5B5F6B", dark: "#9BA0AC")

  static let borderHairline = Color(
    light: Color.black.opacity(0.08),
    dark: Color.white.opacity(0.10)
  )

  static let destructive = Color(light: "#E5484D", dark: "#F2555A")
  static let success = Color(light: "#2FB673", dark: "#3ECB86")
}

enum DOLSpacing {
  static let xs: CGFloat = 4
  static let sm: CGFloat = 8
  static let md: CGFloat = 16
  static let lg: CGFloat = 24
  static let xl: CGFloat = 40
}

enum DOLRadius {
  static let sm: CGFloat = 8
  static let md: CGFloat = 14
  static let lg: CGFloat = 22
  static let pill: CGFloat = 999
}

enum DOLTypography {
  static let display = Font.largeTitle.bold()
  static let title = Font.title2.weight(.semibold)
  static let headline = Font.headline.weight(.semibold)
  static let body = Font.body
  static let caption = Font.footnote
}

enum DOLMotion {
  static let durationFast: TimeInterval = 0.18
  static let durationStandard: TimeInterval = 0.32
  static let durationSlow: TimeInterval = 0.5

  static let spring = Animation.spring(response: 0.4, dampingFraction: 0.86)
}

// MARK: - Native Liquid Glass

// Real .glassEffect()/GlassEffectContainer usage — see the "Native Liquid
// Glass usage" section of DESIGN_TOKENS.md. Wrap multiple glassCard(_:)
// views that should morph together in a single GlassEffectContainer at the
// call site; this modifier only handles the single-element case.
struct GlassCardBackground: ViewModifier {
  var cornerRadius: CGFloat = DOLRadius.md

  func body(content: Content) -> some View {
    content
      .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

extension View {
  func glassCard(cornerRadius: CGFloat = DOLRadius.md) -> some View {
    modifier(GlassCardBackground(cornerRadius: cornerRadius))
  }
}

// MARK: - Color helpers

private extension Color {
  init(light: String, dark: String) {
    self.init(uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
    })
  }

  init(light: Color, dark: Color) {
    self.init(uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
    })
  }

  init(hex: String) {
    self.init(uiColor: UIColor(hex: hex))
  }
}

private extension UIColor {
  convenience init(hex: String) {
    var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    sanitized = sanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0
    Scanner(string: sanitized).scanHexInt64(&rgb)

    let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(rgb & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b, alpha: 1.0)
  }
}
