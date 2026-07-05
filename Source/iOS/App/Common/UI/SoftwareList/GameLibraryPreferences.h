// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GameLibrarySortMode) {
  GameLibrarySortModeName,
  GameLibrarySortModeRecentlyPlayed,
  GameLibrarySortModeFavoritesFirst,
};

// Small NSUserDefaults-backed store for library organization state that has nothing to do with
// a game's own file/metadata - which games are starred, and when each was last played. Keyed by
// each game's own GetGameID(), which is stable across rescans/reimports (unlike an array index).
@interface GameLibraryPreferences : NSObject

+ (instancetype)shared;

@property (nonatomic) GameLibrarySortMode sortMode;
@property (nonatomic) BOOL favoritesOnly;

- (BOOL)isFavoriteGameID:(NSString*)gameID;
- (void)setFavorite:(BOOL)favorite forGameID:(NSString*)gameID;

- (void)recordPlayedGameID:(NSString*)gameID;
// 0 if the game has never been recorded as played.
- (NSTimeInterval)lastPlayedTimeForGameID:(NSString*)gameID;

@end

NS_ASSUME_NONNULL_END
