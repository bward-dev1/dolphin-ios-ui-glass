// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "NetPlaySetupViewController.h"

#import "FoundationStringUtil.h"
#import "GameFileCacheManager.h"
#import "GameFilePtrWrapper.h"
#import "NetPlayLobbyViewController.h"
#import "NetPlayManager.h"
#import "Swift.h"

#import "UICommon/GameFile.h"

// Simple modal list to pick a game to host. Not exposed outside this file - it's only ever
// code-instantiated, never used from a storyboard.
@interface NPGamePickerViewController : UITableViewController
@property (nonatomic, copy) void (^onPick)(GameFilePtrWrapper* _Nullable);
@end

@implementation NPGamePickerViewController {
  NSArray<GameFilePtrWrapper*>* _games;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Choose a Game";
  self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                     target:self
                                                     action:@selector(cancelTapped)];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
  _games = [[GameFileCacheManager sharedManager] getGames];
}

- (void)cancelTapped {
  if (self.onPick) {
    self.onPick(nil);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _games.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  GameFilePtrWrapper* wrapper = _games[indexPath.row];
  cell.textLabel.text = CppToFoundationString(wrapper.gameFile->GetInternalName());
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  GameFilePtrWrapper* wrapper = _games[indexPath.row];
  if (self.onPick) {
    self.onPick(wrapper);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end

typedef NS_ENUM(NSInteger, NPRow) {
  NPRowNickname,
  NPRowGame,
  NPRowUseHostCode,
  NPRowAddress,  // label/placeholder switches between "Host Code" and "IP Address"
  NPRowPort,
};

@interface NetPlaySetupViewController () <UITextFieldDelegate>
@end

@implementation NetPlaySetupViewController {
  UISegmentedControl* _modeControl;
  UITextField* _nicknameField;
  UISwitch* _traversalSwitch;
  UITextField* _addressField;
  UITextField* _portField;
  UIActivityIndicatorView* _spinner;
  UIButton* _actionButton;
  UILabel* _statusLabel;

  GameFilePtrWrapper* _selectedGame;
  NSArray<NSNumber*>* _rows;
}

- (instancetype)init {
  return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"NetPlay";
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

  self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                     target:self
                                                     action:@selector(cancelTapped)];

  _modeControl = [[UISegmentedControl alloc] initWithItems:@[ @"Host", @"Join" ]];
  _modeControl.selectedSegmentIndex = 0;
  [_modeControl addTarget:self action:@selector(modeChanged) forControlEvents:UIControlEventValueChanged];

  UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
  _modeControl.translatesAutoresizingMaskIntoConstraints = NO;
  [header addSubview:_modeControl];
  [NSLayoutConstraint activateConstraints:@[
    [_modeControl.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
    [_modeControl.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
    [_modeControl.leadingAnchor constraintGreaterThanOrEqualToAnchor:header.leadingAnchor constant:16],
    [_modeControl.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-16],
  ]];
  self.tableView.tableHeaderView = header;

  _nicknameField = [self makeAccessoryTextFieldWithPlaceholder:@"Required"];
  _nicknameField.text = [self defaultNickname];
  _nicknameField.textAlignment = NSTextAlignmentRight;

  _traversalSwitch = [[UISwitch alloc] init];
  _traversalSwitch.on = YES;
  [_traversalSwitch addTarget:self action:@selector(traversalChanged) forControlEvents:UIControlEventValueChanged];

  _addressField = [self makeAccessoryTextFieldWithPlaceholder:@"Host code"];
  _addressField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
  _addressField.autocorrectionType = UITextAutocorrectionTypeNo;
  _addressField.textAlignment = NSTextAlignmentRight;

  _portField = [self makeAccessoryTextFieldWithPlaceholder:@"2626"];
  _portField.keyboardType = UIKeyboardTypeNumberPad;
  _portField.textAlignment = NSTextAlignmentRight;

  _statusLabel = [[UILabel alloc] init];
  _statusLabel.numberOfLines = 0;
  _statusLabel.font = [UIFont systemFontOfSize:14];
  _statusLabel.textColor = [UIColor secondaryLabelColor];
  _statusLabel.textAlignment = NSTextAlignmentCenter;
  _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;

  _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
  _actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
  [_actionButton addTarget:self action:@selector(actionTapped) forControlEvents:UIControlEventTouchUpInside];
  _actionButton.translatesAutoresizingMaskIntoConstraints = NO;

  _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  _spinner.hidesWhenStopped = YES;
  _spinner.translatesAutoresizingMaskIntoConstraints = NO;

  UIStackView* footerStack = [[UIStackView alloc] initWithArrangedSubviews:@[ _statusLabel, _actionButton, _spinner ]];
  footerStack.axis = UILayoutConstraintAxisVertical;
  footerStack.spacing = 12;
  footerStack.alignment = UIStackViewAlignmentCenter;
  footerStack.translatesAutoresizingMaskIntoConstraints = NO;

  UIView* footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 140)];
  [footer addSubview:footerStack];
  [NSLayoutConstraint activateConstraints:@[
    [footerStack.topAnchor constraintEqualToAnchor:footer.topAnchor constant:16],
    [footerStack.centerXAnchor constraintEqualToAnchor:footer.centerXAnchor],
    [footerStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:footer.leadingAnchor constant:16],
    [footerStack.trailingAnchor constraintLessThanOrEqualToAnchor:footer.trailingAnchor constant:-16],
  ]];
  self.tableView.tableFooterView = footer;

  [self rebuildRows];
}

- (UITextField*)makeAccessoryTextFieldWithPlaceholder:(NSString*)placeholder {
  UITextField* field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
  field.placeholder = placeholder;
  field.delegate = self;
  field.clearButtonMode = UITextFieldViewModeWhileEditing;
  [field addTarget:self action:@selector(updateActionButtonEnabled) forControlEvents:UIControlEventEditingChanged];
  return field;
}

- (NSString*)defaultNickname {
  NSString* deviceName = [UIDevice currentDevice].name;
  return deviceName.length > 0 ? deviceName : @"Player";
}

- (BOOL)isHostMode {
  return _modeControl.selectedSegmentIndex == 0;
}

- (void)cancelTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)modeChanged {
  [self rebuildRows];
}

- (void)traversalChanged {
  _addressField.placeholder = _traversalSwitch.on ? @"Host code" : @"IP address";
  [self rebuildRows];
}

// Recomputes which rows are visible for the current mode/traversal state and reloads. Host
// mode always needs a game selected; Join mode needs either a host code (traversal) or a raw
// address+port (direct connect); Host mode without traversal also needs a port to forward.
- (void)rebuildRows {
  NSMutableArray<NSNumber*>* rows = [NSMutableArray array];
  [rows addObject:@(NPRowNickname)];

  if ([self isHostMode]) {
    [rows addObject:@(NPRowGame)];
    [rows addObject:@(NPRowUseHostCode)];
    if (!_traversalSwitch.on) {
      [rows addObject:@(NPRowPort)];
    }
  } else {
    [rows addObject:@(NPRowUseHostCode)];
    [rows addObject:@(NPRowAddress)];
    if (!_traversalSwitch.on) {
      [rows addObject:@(NPRowPort)];
    }
  }

  _rows = rows;
  [self.tableView reloadData];
  [self updateActionButtonEnabled];

  [_actionButton setTitle:([self isHostMode] ? @"Host" : @"Join") forState:UIControlStateNormal];
}

- (void)chooseGameTapped {
  NPGamePickerViewController* picker = [[NPGamePickerViewController alloc] init];
  __weak NetPlaySetupViewController* weakSelf = self;
  picker.onPick = ^(GameFilePtrWrapper* _Nullable game) {
    __strong NetPlaySetupViewController* strongSelf = weakSelf;
    if (strongSelf != nil && game != nil) {
      strongSelf->_selectedGame = game;
      [strongSelf.tableView reloadData];
      [strongSelf updateActionButtonEnabled];
    }
  };
  UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:picker];
  [self presentViewController:nav animated:YES completion:nil];
}

- (void)updateActionButtonEnabled {
  BOOL nicknameOk = _nicknameField.text.length > 0;
  BOOL ready;

  if ([self isHostMode]) {
    ready = nicknameOk && _selectedGame != nil;
  } else {
    ready = nicknameOk && _addressField.text.length > 0;
  }

  _actionButton.enabled = ready;
}

- (uint16_t)portValue {
  NSInteger value = _portField.text.integerValue;
  if (value <= 0 || value > 65535) {
    return 2626;
  }
  return (uint16_t)value;
}

- (void)actionTapped {
  _actionButton.enabled = NO;
  [_spinner startAnimating];
  _statusLabel.text = @"Connecting...";

  __weak NetPlaySetupViewController* weakSelf = self;
  void (^completion)(BOOL, NSString* _Nullable) = ^(BOOL success, NSString* _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NetPlaySetupViewController* strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }

      [strongSelf->_spinner stopAnimating];

      if (success) {
        NetPlayLobbyViewController* lobby = [[NetPlayLobbyViewController alloc] init];
        [strongSelf.navigationController pushViewController:lobby animated:YES];
      } else {
        strongSelf->_actionButton.enabled = YES;
        strongSelf->_statusLabel.text = error ?: @"Something went wrong.";
      }
    });
  };

  if ([self isHostMode]) {
    [[NetPlayManager shared] hostGameWithFile:_selectedGame
                                          port:[self portValue]
                                  useTraversal:_traversalSwitch.on
                                       useUPnP:!_traversalSwitch.on
                                      nickname:_nicknameField.text
                                    completion:completion];
  } else {
    [[NetPlayManager shared] joinWithAddress:_addressField.text
                                         port:[self portValue]
                                 useTraversal:_traversalSwitch.on
                                     nickname:_nicknameField.text
                                   completion:completion];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _rows.count;
}

- (nullable NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  return [self isHostMode] ? @"Host a Game" : @"Join a Game";
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.accessoryView = nil;

  NPRow row = (NPRow)_rows[indexPath.row].integerValue;
  switch (row) {
  case NPRowNickname:
    cell.textLabel.text = @"Nickname";
    cell.accessoryView = _nicknameField;
    break;
  case NPRowGame:
    cell.textLabel.text = _selectedGame != nil
        ? CppToFoundationString(_selectedGame.gameFile->GetInternalName())
        : @"Choose a Game...";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    break;
  case NPRowUseHostCode:
    cell.textLabel.text = @"Use Host Code";
    cell.accessoryView = _traversalSwitch;
    break;
  case NPRowAddress:
    cell.textLabel.text = _traversalSwitch.on ? @"Host Code" : @"IP Address";
    cell.accessoryView = _addressField;
    break;
  case NPRowPort:
    cell.textLabel.text = @"Port";
    cell.accessoryView = _portField;
    break;
  }

  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  NPRow row = (NPRow)_rows[indexPath.row].integerValue;
  if (row == NPRowGame) {
    [self chooseGameTapped];
  }
}

@end
