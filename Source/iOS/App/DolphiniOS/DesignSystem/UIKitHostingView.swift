// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI
import UIKit

// Generic bridge for hosting an existing UIKit screen (storyboard-instantiated
// or plain alloc/init) inside Tier 3's SwiftUI navigation. Every Settings
// leaf screen (Config/Graphics/Controllers/Debug/About/CoverArt/AppIcon/
// Optimize) is still the original, fully-functional Obj-C++/UIKit
// implementation — Tier 3's navigation shell is native SwiftUI, but reuses
// that logic as-is rather than reimplementing it, same discipline as Tier 1
// keeping leaf screens storyboard-driven under a new shell.
struct UIKitHostingView: UIViewControllerRepresentable {
  let makeViewController: () -> UIViewController

  func makeUIViewController(context: Context) -> UIViewController {
    makeViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // Wrapped screens manage their own state; nothing to push down from SwiftUI.
  }
}

// Convenience for storyboard-instantiated screens, mirroring the pattern
// used throughout the Tier 1 "classic" reskin
// (UIStoryboard(name:bundle:).instantiateViewController(withIdentifier:)).
extension UIKitHostingView {
  static func storyboard(_ name: String, identifier: String? = nil) -> UIKitHostingView {
    UIKitHostingView {
      let storyboard = UIStoryboard(name: name, bundle: nil)
      if let identifier {
        return storyboard.instantiateViewController(withIdentifier: identifier)
      }
      return storyboard.instantiateInitialViewController()!
    }
  }
}
