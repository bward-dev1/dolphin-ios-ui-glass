// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@class GameFilePtrWrapper;

NS_ASSUME_NONNULL_BEGIN

// Lets the user search GameTDB's title list by name and preview/apply an alternate cover for a
// specific installed game, for when the automatic exact-ID match gets it wrong (e.g. an unusual
// homebrew or hacked disc header).
@interface CoverArtPickerViewController : UITableViewController

- (instancetype)initWithGameFileWrapper:(GameFilePtrWrapper*)gameFileWrapper;

@end

NS_ASSUME_NONNULL_END
