// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI

// Tier 3 "glass" native SwiftUI replacement for GraphicsSettings.storyboard's
// root scene, reached from SettingsRootView's Graphics row. Same 4 rows
// (General/Enhancements/Hacks/Advanced) as the original Obj-C++
// GraphicsRootViewController, still pushing to the original storyboard-driven
// leaf screens via UIKitHostingView -- those stay Objective-C++, tightly
// coupled to Dolphin's C++ Config:: system, out of scope for this pass. Same
// approach as Tier 1/2's reskins.
struct GraphicsSettingsView: View {
  private let rows: [(title: String, identifier: String)] = [
    ("General", "GraphicsGeneralViewController"),
    ("Enhancements", "GraphicsEnhancementsViewController"),
    ("Hacks", "GraphicsHacksViewController"),
    ("Advanced", "GraphicsAdvancedViewController"),
  ]

  var body: some View {
    List {
      ForEach(rows, id: \.identifier) { row in
        NavigationLink(row.title) {
          UIKitHostingView.storyboard("GraphicsSettings", identifier: row.identifier)
            .navigationBarTitleDisplayMode(.inline)
        }
      }
    }
    .navigationTitle("Graphics")
    .background(DOLColor.backgroundPrimary)
    .scrollContentBackground(.hidden)
    .onAppear {
      // The app's only call site of PopulateBackendInfo -- load-bearing for
      // GraphicsAdvancedViewController's backend-capability-conditional rows.
      GraphicsBackendInfoBridge.populateBackendInfo()
    }
  }
}
