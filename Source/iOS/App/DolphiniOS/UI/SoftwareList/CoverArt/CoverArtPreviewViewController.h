// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@class GameFilePtrWrapper;
@class CoverArtTitle;

NS_ASSUME_NONNULL_BEGIN

// Fetches and previews a single candidate cover, and on confirmation saves it as the custom
// cover override for a specific game (the same "<name>.cover.png" file
// UICommon::GameFile::CustomCoverChanged() already looks for, so it takes effect immediately on
// the next game list rescan - no new override mechanism needed).
@interface CoverArtPreviewViewController : UIViewController

- (instancetype)initWithGameFileWrapper:(GameFilePtrWrapper*)gameFileWrapper title:(CoverArtTitle*)title;

@end

NS_ASSUME_NONNULL_END
