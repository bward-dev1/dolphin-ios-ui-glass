// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class GameFilePtrWrapper;
@class EmulationBootParameter;

NS_ASSUME_NONNULL_BEGIN

// One row in the lobby's player list.
@interface NetPlayPlayerInfo : NSObject

@property (nonatomic, copy) NSString* name;
@property (nonatomic) NSUInteger ping;
@property (nonatomic) BOOL isHost;
@property (nonatomic, copy) NSString* gameStatusText;

@end

// Owns the live NetPlay::NetPlayServer / NetPlay::NetPlayClient for a session (host or guest)
// and bridges Dolphin's NetPlay::NetPlayUI callback interface to state this app's UI can read.
// All NetPlay:: calls happen on Dolphin's own networking thread; every property here is safe to
// read from any thread (backed by a lock) and NetPlayManagerDidUpdateNotification is always
// posted on the main queue so observers can just reload their UI without hopping threads
// themselves.
@interface NetPlayManager : NSObject

+ (instancetype)shared;

// Posted (main queue) whenever players/chat/status/hostCode/gameStarting change.
+ (NSNotificationName)didUpdateNotification;

@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) BOOL isHost;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly, copy, nullable) NSString* hostCode;
@property (nonatomic, readonly, copy) NSString* statusText;
@property (nonatomic, readonly, copy) NSArray<NSString*>* chatLog;
@property (nonatomic, readonly, copy) NSArray<NetPlayPlayerInfo*>* players;

// Becomes YES the moment the host starts the game (OnMsgStartGame). The lobby screen should
// observe this and, once true, call takePendingBootParameter and boot it.
@property (nonatomic, readonly) BOOL gameStarting;

// Starts hosting `gameFile`. useTraversal picks Dolphin's public traversal server (yields a
// short hostCode anyone can join with, no port forwarding needed); otherwise the host must
// forward `port` themselves and share their IP directly. completion fires on the main queue.
- (void)hostGameWithFile:(GameFilePtrWrapper*)gameFile
                     port:(uint16_t)port
             useTraversal:(BOOL)useTraversal
                  useUPnP:(BOOL)useUPnP
                 nickname:(NSString*)nickname
               completion:(void (^)(BOOL success, NSString* _Nullable error))completion;

// Joins a session. `address` is a traversal host code when useTraversal is YES, otherwise a
// raw IP/hostname. completion fires on the main queue.
- (void)joinWithAddress:(NSString*)address
                    port:(uint16_t)port
            useTraversal:(BOOL)useTraversal
                nickname:(NSString*)nickname
              completion:(void (^)(BOOL success, NSString* _Nullable error))completion;

- (void)sendChatMessage:(NSString*)message;

// Host-only: locks in the hosted game and tells everyone to boot it.
- (void)startGame;

// Tears down the session (server + client) and resets all published state.
- (void)stop;

// Consumes the boot request raised by gameStarting - returns nil if there isn't one pending.
// Only call once per game start; ownership of the underlying session data moves out on call.
- (nullable EmulationBootParameter*)takePendingBootParameter;

@end

NS_ASSUME_NONNULL_END
