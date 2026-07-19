// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI
import UIKit

// Tier 3 "glass" native SwiftUI replacement for the Settings tab. Same
// three sections/rows and the same navigation targets as the original
// storyboard-driven SettingsRootViewController — About/Config/Graphics/
// Controllers/Debug are still their original Obj-C++/storyboard
// implementations, reached here through UIKitHostingView rather than a
// UIKit push/present call, since this whole tier's navigation is native
// SwiftUI (NavigationStack) instead of UIKit's UINavigationController.
struct SettingsRootView: View {
  // About is a sheet, not a NavigationLink: its original storyboard-declared
  // Done button relies on an unwind segue targeting `unwindToSettings:` on
  // the presenting SettingsRootViewController. That UIKit view controller
  // no longer exists in Tier 3's pure-SwiftUI Settings tab, so the unwind
  // would never resolve — the button would render but silently do nothing.
  // AboutSheetView (below) constructs AboutViewController directly and
  // replaces its Done button with one that calls SwiftUI's dismiss action.
  @State private var isShowingAbout = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          LabeledContent("Version", value: VersionManager.shared().appVersion.userFacing)
          LabeledContent("Dolphin Core", value: VersionManager.shared().coreVersion)

          Button("About") {
            isShowingAbout = true
          }
          .foregroundStyle(DOLColor.textPrimary)

          Button("Help") {
            UIApplication.shared.open(URL(string: "https://oatmealdome.me/dolphinios/")!)
          }
          .foregroundStyle(DOLColor.accentSolid)
        }

        Section {
          NavigationLink("Config") {
            ConfigSettingsView()
          }
          NavigationLink("Graphics") {
            GraphicsSettingsView()
          }
          NavigationLink("Controllers") {
            UIKitHostingView.storyboard("ControllersSettings")
              .navigationBarTitleDisplayMode(.inline)
          }
          NavigationLink("Cover Art") {
            UIKitHostingView { CoverArtSettingsViewController() }
              .navigationBarTitleDisplayMode(.inline)
          }
          NavigationLink("App Icon") {
            UIKitHostingView { AppIconSelectorViewController() }
              .navigationBarTitleDisplayMode(.inline)
          }
          NavigationLink("Optimize My Settings") {
            UIKitHostingView { OptimizeSettingsViewController() }
              .navigationBarTitleDisplayMode(.inline)
          }
        }

        Section {
          NavigationLink("Debug") {
            UIKitHostingView.storyboard("DebugSettings")
              .navigationBarTitleDisplayMode(.inline)
          }
        }
      }
      .navigationTitle("Settings")
      .background(DOLColor.backgroundPrimary)
      .scrollContentBackground(.hidden)
    }
    .sheet(isPresented: $isShowingAbout) {
      AboutSheetView()
    }
  }
}

// Wraps the original AboutViewController directly (not the storyboard's
// own nav-controller-with-formSheet-and-unwind-button scene) so a working
// Done button can be attached — see the comment on isShowingAbout above.
private struct AboutSheetView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    UIKitHostingView {
      // AboutViewController's entire UI (scroll view, logo, labels, Source
      // Code button) is defined in AboutSettings.storyboard's IB canvas —
      // plain AboutViewController() init would produce an empty view. Pull
      // the real instance out of the storyboard's initial nav controller,
      // then discard that wrapper (its formSheet style + broken unwind
      // button) and re-wrap in a fresh nav controller with a working Done.
      let storyboard = UIStoryboard(name: "AboutSettings", bundle: nil)
      let originalNav = storyboard.instantiateInitialViewController() as! UINavigationController
      let aboutViewController = originalNav.viewControllers.first as! AboutViewController

      let nav = UINavigationController(rootViewController: aboutViewController)
      aboutViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
        systemItem: .done,
        primaryAction: UIAction { [dismiss] _ in dismiss() }
      )
      return nav
    }
  }
}
