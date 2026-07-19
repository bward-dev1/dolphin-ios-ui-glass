// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI
import UIKit

// Tier 3 "glass" root shell — native SwiftUI TabView, replacing
// Main.storyboard's UITabBarController entirely (unlike Tier 1's
// DOLTabBarController, which is still a UIKit UITabBarController just
// built in code). Under iOS 26, TabView adopts the system's native Liquid
// Glass tab bar automatically — no custom appearance code needed, unlike
// Tier 1's hand-rolled UITabBarAppearance glass simulation.
//
// The Games tab still hosts the original storyboard-driven
// SoftwareListiOSViewController (collection view, cover art, favorites/sort
// menu, NetPlay entry point, disc-swap detection, etc. — all real,
// recently-shipped logic) via UIKitHostingView, wrapped in its own
// UINavigationController since that screen's push/present flows
// (properties, cover art picker, emulation) expect a UIKit nav stack.
// Rebuilding the game library itself in native SwiftUI is future work, not
// this foundation increment.
struct RootAppView: View {
  var body: some View {
    TabView {
      GamesTabView()
        .tabItem {
          Label("Games", systemImage: "square.grid.2x2")
        }

      SettingsRootView()
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
    .tint(DOLColor.accentSolid)
  }
}

private struct GamesTabView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UINavigationController {
    let storyboard = UIStoryboard(name: "SoftwareList", bundle: nil)
    let nav = storyboard.instantiateViewController(withIdentifier: "softwareListRoot") as! UINavigationController
    return nav
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
