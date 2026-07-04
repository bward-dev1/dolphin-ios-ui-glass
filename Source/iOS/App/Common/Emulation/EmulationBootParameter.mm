// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationBootParameter.h"

#import "Core/Boot/Boot.h"
#import "Core/CommonTitles.h"

#import "FoundationStringUtil.h"

@implementation EmulationBootParameter

- (std::unique_ptr<BootParameters>) generateDolphinBootParameter {
  std::unique_ptr<BootParameters> boot;
  
  if (self.bootType == EmulationBootTypeFile) {
    std::vector<std::string> paths = {FoundationToCppString(self.path)};

    if (self.secondPath != nil) {
      paths.push_back(FoundationToCppString(self.secondPath));
    }

    if (self.netplayBootSessionData != nullptr) {
      // Take ownership of the session data NetPlayClient built for this boot (movie/save-sync
      // settings), rather than a default-constructed one.
      std::unique_ptr<BootSessionData> session(self.netplayBootSessionData);
      self.netplayBootSessionData = nullptr;
      boot = BootParameters::GenerateFromFile(paths, std::move(*session));
    } else {
      boot = BootParameters::GenerateFromFile(paths, BootSessionData());
    }
  } else if (self.bootType == EmulationBootTypeSystemMenu) {
    boot = std::make_unique<BootParameters>(BootParameters::NANDTitle{Titles::SYSTEM_MENU});
  } else {
    boot = std::make_unique<BootParameters>(BootParameters::IPL{self.iplRegion});
  }
  
  return boot;
}

@end
