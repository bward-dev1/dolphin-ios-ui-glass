// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import <memory>

#import "DiscIO/Enums.h"

#import "EmulationBootType.h"

class BootParameters;
class BootSessionData;

NS_ASSUME_NONNULL_BEGIN

@interface EmulationBootParameter : NSObject

@property (nonatomic) EmulationBootType bootType;
@property (nonatomic) NSString* path;
@property (nonatomic) NSString* secondPath;
@property (nonatomic) bool isNKit;
@property (nonatomic) DiscIO::Region iplRegion;

// Set only for a NetPlay-triggered boot: transfers ownership of a BootSessionData built by
// NetPlayClient (movie/save-sync settings for this session) instead of a default-constructed
// one. Consumed (and nulled out) the first time generateDolphinBootParameter runs.
@property (nonatomic) BootSessionData* _Nullable netplayBootSessionData;

- (std::unique_ptr<BootParameters>) generateDolphinBootParameter;

@end

NS_ASSUME_NONNULL_END
