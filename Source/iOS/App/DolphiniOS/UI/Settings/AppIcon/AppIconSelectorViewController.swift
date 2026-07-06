// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

// Lets the user switch between the default app icon and a set of bundled alternates
// (UIApplication.setAlternateIconName). Options are just a name -> (alternate name, preview
// image) table; nil alternate name means "the default/primary icon".
class AppIconSelectorViewController: UITableViewController {
  private struct IconOption {
    let alternateName: String?
    let displayName: String
    let previewImageName: String
  }

  private let options: [IconOption] = [
    IconOption(alternateName: nil, displayName: "Default (Rainbow)", previewImageName: "AppIcon-Default-Preview"),
    IconOption(alternateName: "Gold", displayName: "Gold Premium", previewImageName: "AppIcon-Gold-Preview"),
    IconOption(alternateName: "MidnightPro", displayName: "Midnight Pro", previewImageName: "AppIcon-MidnightPro-Preview"),
    IconOption(alternateName: "NeonSpecial", displayName: "Neon Special", previewImageName: "AppIcon-NeonSpecial-Preview"),
    IconOption(alternateName: "ClassicBlue", displayName: "Classic Blue", previewImageName: "AppIcon-ClassicBlue-Preview"),
    IconOption(alternateName: "MonoDeluxe", displayName: "Monochrome Deluxe", previewImageName: "AppIcon-MonoDeluxe-Preview"),
    IconOption(alternateName: "RainbowMidnight", displayName: "Rainbow Midnight", previewImageName: "AppIcon-RainbowMidnight-Preview"),
  ]

  init() {
    super.init(style: .insetGrouped)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "App Icon"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return options.count
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return UIApplication.shared.supportsAlternateIcons
      ? nil
      : "This device doesn't support alternate app icons."
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let option = options[indexPath.row]

    cell.textLabel?.text = option.displayName
    cell.imageView?.image = UIImage(named: option.previewImageName)

    if let imageView = cell.imageView {
      imageView.layer.cornerRadius = 8
      imageView.layer.masksToBounds = true
      imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    }

    let isCurrent = UIApplication.shared.alternateIconName == option.alternateName
    cell.accessoryType = isCurrent ? .checkmark : .none
    cell.selectionStyle = .default

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    guard UIApplication.shared.supportsAlternateIcons else {
      return
    }

    let option = options[indexPath.row]
    guard UIApplication.shared.alternateIconName != option.alternateName else {
      return
    }

    UIApplication.shared.setAlternateIconName(option.alternateName) { [weak self] error in
      guard error == nil else {
        return
      }
      self?.tableView.reloadData()
    }
  }
}
