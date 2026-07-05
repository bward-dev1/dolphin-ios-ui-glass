// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GameLibraryPreferences.h"

static NSString* const kFavoritesKey = @"GameLibraryFavoriteGameIDs";
static NSString* const kLastPlayedKey = @"GameLibraryLastPlayedByGameID";
static NSString* const kSortModeKey = @"GameLibrarySortMode";
static NSString* const kFavoritesOnlyKey = @"GameLibraryFavoritesOnly";

@implementation GameLibraryPreferences

+ (instancetype)shared {
  static GameLibraryPreferences* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[GameLibraryPreferences alloc] init];
  });
  return instance;
}

- (GameLibrarySortMode)sortMode {
  return (GameLibrarySortMode)[[NSUserDefaults standardUserDefaults] integerForKey:kSortModeKey];
}

- (void)setSortMode:(GameLibrarySortMode)sortMode {
  [[NSUserDefaults standardUserDefaults] setInteger:sortMode forKey:kSortModeKey];
}

- (BOOL)favoritesOnly {
  return [[NSUserDefaults standardUserDefaults] boolForKey:kFavoritesOnlyKey];
}

- (void)setFavoritesOnly:(BOOL)favoritesOnly {
  [[NSUserDefaults standardUserDefaults] setBool:favoritesOnly forKey:kFavoritesOnlyKey];
}

- (BOOL)isFavoriteGameID:(NSString*)gameID {
  NSArray<NSString*>* favorites = [[NSUserDefaults standardUserDefaults] arrayForKey:kFavoritesKey];
  return [favorites containsObject:gameID];
}

- (void)setFavorite:(BOOL)favorite forGameID:(NSString*)gameID {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray<NSString*>* favorites =
      [([defaults arrayForKey:kFavoritesKey] ?: @[]) mutableCopy];

  if (favorite) {
    if (![favorites containsObject:gameID]) {
      [favorites addObject:gameID];
    }
  } else {
    [favorites removeObject:gameID];
  }

  [defaults setObject:favorites forKey:kFavoritesKey];
}

- (void)recordPlayedGameID:(NSString*)gameID {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary<NSString*, NSNumber*>* lastPlayed =
      [([defaults dictionaryForKey:kLastPlayedKey] ?: @{}) mutableCopy];

  lastPlayed[gameID] = @([[NSDate date] timeIntervalSince1970]);

  [defaults setObject:lastPlayed forKey:kLastPlayedKey];
}

- (NSTimeInterval)lastPlayedTimeForGameID:(NSString*)gameID {
  NSDictionary<NSString*, NSNumber*>* lastPlayed =
      [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastPlayedKey];
  return lastPlayed[gameID].doubleValue;
}

@end
