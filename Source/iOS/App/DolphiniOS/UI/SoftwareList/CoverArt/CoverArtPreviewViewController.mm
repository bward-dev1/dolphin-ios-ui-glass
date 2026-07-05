// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "CoverArtPreviewViewController.h"

#import "CoverArtDatabaseDownloader.h"
#import "GameFilePtrWrapper.h"

#import "UICommon/GameFile.h"

#import "FoundationStringUtil.h"

@implementation CoverArtPreviewViewController {
  GameFilePtrWrapper* _gameFileWrapper;
  CoverArtTitle* _title;
  NSData* _imageData;

  UIImageView* _imageView;
  UIActivityIndicatorView* _spinner;
  UILabel* _statusLabel;
}

- (instancetype)initWithGameFileWrapper:(GameFilePtrWrapper*)gameFileWrapper title:(CoverArtTitle*)title {
  self = [super init];
  if (self) {
    _gameFileWrapper = gameFileWrapper;
    _title = title;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = _title.name;
  self.view.backgroundColor = [UIColor systemBackgroundColor];

  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:@"Use This Cover"
                                        style:UIBarButtonItemStyleDone
                                       target:self
                                       action:@selector(useThisCoverTapped)];
  self.navigationItem.rightBarButtonItem.enabled = NO;

  _imageView = [[UIImageView alloc] init];
  _imageView.contentMode = UIViewContentModeScaleAspectFit;
  _imageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_imageView];

  _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  _spinner.translatesAutoresizingMaskIntoConstraints = NO;
  [_spinner startAnimating];
  [self.view addSubview:_spinner];

  _statusLabel = [[UILabel alloc] init];
  _statusLabel.font = [UIFont systemFontOfSize:14];
  _statusLabel.textColor = [UIColor secondaryLabelColor];
  _statusLabel.textAlignment = NSTextAlignmentCenter;
  _statusLabel.numberOfLines = 0;
  _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_statusLabel];

  [NSLayoutConstraint activateConstraints:@[
    [_imageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24],
    [_imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
    [_imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
    [_imageView.heightAnchor constraintEqualToConstant:320],

    [_spinner.centerXAnchor constraintEqualToAnchor:_imageView.centerXAnchor],
    [_spinner.centerYAnchor constraintEqualToAnchor:_imageView.centerYAnchor],

    [_statusLabel.topAnchor constraintEqualToAnchor:_imageView.bottomAnchor constant:16],
    [_statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
    [_statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
  ]];

  __weak CoverArtPreviewViewController* weakSelf = self;
  [[CoverArtDatabaseDownloader shared] fetchCoverForGameID:_title.gameID
                                          completionHandler:^(NSData* _Nullable imageData) {
    [weakSelf handleFetchedImageData:imageData];
  }];
}

- (void)handleFetchedImageData:(NSData*)imageData {
  [_spinner stopAnimating];

  if (imageData == nil) {
    _statusLabel.text = @"Couldn't fetch this cover. GameTDB may not have art for this specific title.";
    return;
  }

  UIImage* image = [UIImage imageWithData:imageData];
  if (image == nil) {
    _statusLabel.text = @"GameTDB returned something that isn't a valid image for this title.";
    return;
  }

  _imageData = imageData;
  _imageView.image = image;
  _statusLabel.text = nil;
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)useThisCoverTapped {
  if (_imageData == nil) {
    return;
  }

  NSString* fullPath = CppToFoundationString(_gameFileWrapper.gameFile->GetFilePath());
  NSString* directory = [fullPath stringByDeletingLastPathComponent];
  NSString* nameWithoutExtension = [[fullPath lastPathComponent] stringByDeletingPathExtension];
  NSString* overridePath =
      [directory stringByAppendingPathComponent:[nameWithoutExtension stringByAppendingString:@".cover.png"]];

  NSError* error = nil;
  BOOL success = [_imageData writeToFile:overridePath options:NSDataWritingAtomic error:&error];

  UIAlertController* alert;
  if (success) {
    alert = [UIAlertController alertControllerWithTitle:@"Cover Updated"
                                                 message:@"This game will use the new cover the next time the "
                                                         @"library refreshes."
                                          preferredStyle:UIAlertControllerStyleAlert];
  } else {
    alert = [UIAlertController alertControllerWithTitle:@"Couldn't Save Cover"
                                                 message:@"Failed to write the cover file next to the ROM. Make "
                                                         @"sure the app has write access to that folder."
                                          preferredStyle:UIAlertControllerStyleAlert];
  }

  __weak CoverArtPreviewViewController* weakSelf = self;
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
    [weakSelf dismissEntireFlow];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissEntireFlow {
  UIViewController* presenter = self;
  while (presenter.presentingViewController != nil) {
    presenter = presenter.presentingViewController;
  }
  [presenter dismissViewControllerAnimated:YES completion:nil];
}

@end
