// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

// Lets a user drop in their own PNGs to reskin the on-screen touch controller, without
// touching code or rebuilding the app. A skin is just a folder of images named after
// Dolphin's existing button/stick asset names (see TCButtonType.getImageName()), living
// under <UserFolder>/Skins/<SkinName>/. Any image the folder doesn't provide falls back
// to the app's bundled artwork, so partial/mix-and-match skins are fully supported.
@objc class TCSkinManager: NSObject {
  @objc static let shared = TCSkinManager()

  // Not @objc: Notification.Name is a plain Swift struct and isn't representable in
  // Objective-C. Only Swift observers (TCButton) need this.
  static let skinChangedNotification = Notification.Name("TCSkinChangedNotification")

  private static let kActiveSkinDefaultsKey = "TCActiveSkinName"

  private override init() {
    super.init()
  }

  @objc var skinsFolder: String {
    return UserFolderUtil.getUserFolder().stringByAppendingPathComponent("Skins")
  }

  // nil means "use the bundled default artwork".
  @objc var activeSkinName: String? {
    get {
      guard let name = UserDefaults.standard.string(forKey: TCSkinManager.kActiveSkinDefaultsKey),
            !name.isEmpty else {
        return nil
      }

      // The folder may have been deleted out from under us (e.g. via the Files app);
      // don't keep pointing at a skin that no longer exists.
      guard isSkinPresent(name) else {
        return nil
      }

      return name
    }
    set {
      UserDefaults.standard.set(newValue, forKey: TCSkinManager.kActiveSkinDefaultsKey)
      NotificationCenter.default.post(name: TCSkinManager.skinChangedNotification, object: nil)
    }
  }

  private func isSkinPresent(_ name: String) -> Bool {
    var isDir: ObjCBool = false
    let path = skinsFolder.stringByAppendingPathComponent(name)
    return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
  }

  @objc func ensureSkinsFolderExists() {
    try? FileManager.default.createDirectory(atPath: skinsFolder, withIntermediateDirectories: true)
  }

  @objc func availableSkinNames() -> [String] {
    let fm = FileManager.default

    guard let items = try? fm.contentsOfDirectory(atPath: skinsFolder) else {
      return []
    }

    return items.filter { isSkinPresent($0) }.sorted()
  }

  @objc(deleteSkinNamed:) @discardableResult func deleteSkin(named name: String) -> Bool {
    let path = skinsFolder.stringByAppendingPathComponent(name)

    guard (try? FileManager.default.removeItem(atPath: path)) != nil else {
      return false
    }

    if activeSkinName == name {
      activeSkinName = nil
    }

    return true
  }

  // Imports a skin from an arbitrary folder the user picked (e.g. via
  // UIDocumentPickerViewController), copying its contents under Skins/<name>. Returns the
  // final skin name used (de-duplicated if one already exists with that name), or nil on
  // failure.
  @objc(importSkinFromFolder:suggestedName:) func importSkin(fromFolder sourcePath: String, suggestedName: String) -> String? {
    ensureSkinsFolderExists()

    var finalName = suggestedName
    var suffix = 2
    while isSkinPresent(finalName) {
      finalName = "\(suggestedName) \(suffix)"
      suffix += 1
    }

    let destPath = skinsFolder.stringByAppendingPathComponent(finalName)

    guard (try? FileManager.default.copyItem(atPath: sourcePath, toPath: destPath)) != nil else {
      return nil
    }

    return finalName
  }

  // Creates a starter skin pre-populated with every current default button/stick image,
  // correctly named, so a user can open individual PNGs in an editor and repaint over them
  // without having to guess filenames. Returns the final skin name used, or nil on failure.
  @objc(createSkinTemplateWithSuggestedName:) func createSkinTemplate(suggestedName: String) -> String? {
    ensureSkinsFolderExists()

    var finalName = suggestedName
    var suffix = 2
    while isSkinPresent(finalName) {
      finalName = "\(suggestedName) \(suffix)"
      suffix += 1
    }

    let destFolder = skinsFolder.stringByAppendingPathComponent(finalName)

    guard (try? FileManager.default.createDirectory(atPath: destFolder, withIntermediateDirectories: true)) != nil else {
      return nil
    }

    let bundle = Bundle(for: TCSkinManager.self)
    let baseNames = Set(TCButtonType.allCases.map { $0.getImageName() })

    for base in baseNames {
      for name in [base, base + "_pressed"] {
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil),
              let data = image.pngData() else {
          continue
        }

        let path = destFolder.stringByAppendingPathComponent("\(name).png")
        try? data.write(to: URL(fileURLWithPath: path))
      }
    }

    return finalName
  }

  // Returns a skin override for `named` (e.g. "wiimote_a" or "wiimote_a_pressed"), or nil
  // if the active skin doesn't provide one (falls back to bundled artwork). The result is
  // normalized to the SAME point-size as `defaultImage` so a skin's art drops straight into
  // the existing button layout regardless of what resolution PNG the skin author exported -
  // only the pixels drawn change, not the on-screen hit box.
  @objc func image(named: String, defaultImage: UIImage) -> UIImage? {
    guard let skin = activeSkinName else {
      return nil
    }

    let path = skinsFolder.stringByAppendingPathComponent(skin).stringByAppendingPathComponent("\(named).png")

    guard let rawImage = UIImage(contentsOfFile: path), let cgImage = rawImage.cgImage else {
      return nil
    }

    let defaultPointWidth = defaultImage.size.width
    let pixelWidth = CGFloat(cgImage.width)

    guard defaultPointWidth > 0, pixelWidth > 0 else {
      return rawImage
    }

    let normalizedScale = pixelWidth / defaultPointWidth
    return UIImage(cgImage: cgImage, scale: normalizedScale, orientation: rawImage.imageOrientation)
  }
}
