// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Obj-C-visible wrapper around VideoBackendBase::PopulateBackendInfo, a
// plain C++ call Swift can't make directly (no C++ interop enabled in this
// project). GraphicsSettingsView calls this before any Graphics sub-screen
// reads capability flags off g_backend_info -- this is the app's only call
// site of PopulateBackendInfo, load-bearing for GraphicsAdvancedViewController's
// backend-capability-conditional rows. Same bridge as Tier 1/2's reskins.
@interface GraphicsBackendInfoBridge : NSObject

+ (void)populateBackendInfo;

@end

NS_ASSUME_NONNULL_END
