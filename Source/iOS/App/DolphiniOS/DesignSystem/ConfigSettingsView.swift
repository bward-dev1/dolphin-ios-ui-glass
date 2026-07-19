// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI

// Tier 3 "glass" native SwiftUI replacement for ConfigSettings.storyboard's
// root scene (which previously had no backing class at all -- pure static
// IB cells + segues), reached from SettingsRootView's Config row. Same 6
// rows (General/Interface/Audio/GameCube/Wii/Advanced) as Tier 1/2's
// reskins, still pushing to the original storyboard-driven leaf screens via
// UIKitHostingView -- those stay Obj-C++, tightly coupled to Dolphin's C++
// Config:: system, out of scope for this pass.
struct ConfigSettingsView: View {
  private let rows: [(title: String, identifier: String)] = [
    ("General", "ConfigGeneralViewController"),
    ("Interface", "ConfigInterfaceViewController"),
    ("Audio", "ConfigSoundViewController"),
    ("GameCube", "ConfigGameCubeViewController"),
    ("Wii", "ConfigWiiViewController"),
    ("Advanced", "ConfigAdvancedViewController"),
  ]

  var body: some View {
    List {
      ForEach(rows, id: \.identifier) { row in
        NavigationLink(row.title) {
          UIKitHostingView.storyboard("ConfigSettings", identifier: row.identifier)
            .navigationBarTitleDisplayMode(.inline)
        }
      }
    }
    .navigationTitle("Config")
    .background(DOLColor.backgroundPrimary)
    .scrollContentBackground(.hidden)
  }
}
