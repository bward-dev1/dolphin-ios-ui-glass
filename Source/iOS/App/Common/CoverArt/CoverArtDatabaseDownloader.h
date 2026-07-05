// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// One entry from the bundled GameTDB title list: a disc/title ID and its display name.
@interface CoverArtTitle : NSObject
@property (nonatomic, copy) NSString* gameID;
@property (nonatomic, copy) NSString* name;
@end

// Downloads GameTDB cover art for EVERY game DiscIO/wiitdb.txt knows about - not just the ones
// currently installed - so the library browses with real box art even before you own a game
// (or just for completeness). Writes into the exact same on-disk cover cache
// UICommon::GameFile::DownloadDefaultCover() already uses, so anything downloaded here is
// picked up automatically the next time a game list rescan runs; already-cached covers are
// skipped, so re-running this after installing more games only fetches what's missing.
@interface CoverArtDatabaseDownloader : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, readonly) NSInteger totalCount;
@property (nonatomic, readonly) NSInteger completedCount;

// Counts how many covers are missing without downloading anything, for a "this will fetch
// about N images" estimate before the user commits. Runs synchronously; call off the main
// thread if the caller cares about not blocking briefly (parses a ~10k line file).
- (NSInteger)countMissingCovers;

// progressHandler is called on the main queue after every completed (or skipped) entry.
// completionHandler is called on the main queue once with whether the run finished the whole
// list (NO) or was cancelled partway through (YES).
- (void)startWithProgressHandler:(void (^)(NSInteger completed, NSInteger total))progressHandler
               completionHandler:(void (^)(BOOL wasCancelled))completionHandler;

- (void)cancel;

// Every title the bundled GameTDB list knows about - used to let a user search for and pick a
// specific alternate cover when the automatic exact-ID match got it wrong (e.g. a disc with
// unusual/homebrew header data). Runs synchronously; call off the main thread if the caller
// cares about not blocking briefly.
- (NSArray<CoverArtTitle*>*)allTitles;

// Fetches the raw PNG bytes for a specific GameTDB ID directly (bypassing the on-disk cache -
// this is for previewing a candidate cover before committing to it, not for the normal
// per-installed-game download path). Calls completionHandler on the main queue with the image
// data, or nil on failure.
- (void)fetchCoverForGameID:(NSString*)gameID completionHandler:(void (^)(NSData* _Nullable imageData))completionHandler;

@end

NS_ASSUME_NONNULL_END
