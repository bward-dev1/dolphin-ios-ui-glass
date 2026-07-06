// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "OptimizeSettingsViewController.h"

#import "DeviceProfile.h"

typedef NS_ENUM(NSInteger, OptimizeRow) {
  OptimizeRowDevice,
  OptimizeRowChip,
  OptimizeRowRAM,
  OptimizeRowCores,
  OptimizeRowJIT,
  OptimizeRowTier,
  OptimizeRowCount,
};

@implementation OptimizeSettingsViewController {
  UIButton* _applyButton;
}

- (instancetype)init {
  return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Optimize My Settings";

  [[DeviceProfile shared] refresh];

  UIView* footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 100)];

  _applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [_applyButton setTitle:@"Apply Optimized Settings" forState:UIControlStateNormal];
  _applyButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
  _applyButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_applyButton addTarget:self action:@selector(applyTapped) forControlEvents:UIControlEventTouchUpInside];
  [footer addSubview:_applyButton];

  [NSLayoutConstraint activateConstraints:@[
    [_applyButton.centerXAnchor constraintEqualToAnchor:footer.centerXAnchor],
    [_applyButton.topAnchor constraintEqualToAnchor:footer.topAnchor constant:24],
  ]];

  self.tableView.tableFooterView = footer;
}

- (void)applyTapped {
  [[DeviceProfile shared] applyOptimizedSettings];

  UIAlertController* alert =
      [UIAlertController alertControllerWithTitle:@"Settings Applied"
                                           message:[NSString stringWithFormat:@"Applied the %@ tier profile based on "
                                                    @"what was detected on this device.",
                                                    [DeviceProfile shared].tierDisplayName]
                                    preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return OptimizeRowCount;
}

- (nullable NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  return @"Detected Automatically";
}

- (nullable NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
  return [DeviceProfile shared].tierSummary;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  DeviceProfile* profile = [DeviceProfile shared];

  switch ((OptimizeRow)indexPath.row) {
  case OptimizeRowDevice:
    cell.textLabel.text = @"Device";
    cell.detailTextLabel.text = profile.deviceIdentifier;
    break;
  case OptimizeRowChip:
    cell.textLabel.text = @"Chip";
    cell.detailTextLabel.text = profile.chipName;
    break;
  case OptimizeRowRAM:
    cell.textLabel.text = @"Memory";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld MB", (long)profile.physicalMemoryMB];
    break;
  case OptimizeRowCores:
    cell.textLabel.text = @"CPU Cores";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)profile.processorCount];
    break;
  case OptimizeRowJIT:
    cell.textLabel.text = @"JIT";
    cell.detailTextLabel.text = profile.jitAvailable ? @"Available" : @"Not Available";
    break;
  case OptimizeRowTier:
  case OptimizeRowCount:
    cell.textLabel.text = @"Recommended Tier";
    cell.detailTextLabel.text = profile.tierDisplayName;
    break;
  }

  return cell;
}

@end
