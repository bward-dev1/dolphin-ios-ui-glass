// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsBackendInfoBridge.h"

#import "VideoCommon/VideoBackendBase.h"

@implementation GraphicsBackendInfoBridge

+ (void)populateBackendInfo {
  WindowSystemInfo wsi;
  wsi.type = WindowSystemType::iOS;

  VideoBackendBase::PopulateBackendInfo(wsi);
}

@end
