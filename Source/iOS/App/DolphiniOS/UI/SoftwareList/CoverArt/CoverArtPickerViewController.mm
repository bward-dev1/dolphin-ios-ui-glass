// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "CoverArtPickerViewController.h"

#import "CoverArtDatabaseDownloader.h"
#import "CoverArtPreviewViewController.h"
#import "GameFilePtrWrapper.h"

#import "UICommon/GameFile.h"

@interface CoverArtPickerViewController () <UISearchResultsUpdating>
@end

@implementation CoverArtPickerViewController {
  GameFilePtrWrapper* _gameFileWrapper;
  UISearchController* _searchController;
  NSArray<CoverArtTitle*>* _allTitles;
  NSArray<CoverArtTitle*>* _filteredTitles;
}

- (instancetype)initWithGameFileWrapper:(GameFilePtrWrapper*)gameFileWrapper {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    _gameFileWrapper = gameFileWrapper;
    _filteredTitles = @[];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Change Cover";

  self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                     target:self
                                                     action:@selector(cancelTapped)];

  _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
  _searchController.searchResultsUpdater = self;
  _searchController.obscuresBackgroundDuringPresentation = NO;
  _searchController.searchBar.placeholder = @"Search by game name";
  self.navigationItem.searchController = _searchController;
  self.navigationItem.hidesSearchBarWhenScrolling = NO;
  self.definesPresentationContext = YES;

  __weak CoverArtPickerViewController* weakSelf = self;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSArray<CoverArtTitle*>* titles = [[CoverArtDatabaseDownloader shared] allTitles];
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.allTitles = titles;
    });
  });
}

- (void)setAllTitles:(NSArray<CoverArtTitle*>*)allTitles {
  _allTitles = allTitles;
}

- (void)cancelTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController*)searchController {
  NSString* query = [searchController.searchBar.text
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  if (query.length < 2 || _allTitles == nil) {
    _filteredTitles = @[];
  } else {
    NSMutableArray<CoverArtTitle*>* matches = [NSMutableArray array];
    for (CoverArtTitle* title in _allTitles) {
      if ([title.name rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
        [matches addObject:title];
        if (matches.count >= 200) {
          break;
        }
      }
    }
    _filteredTitles = matches;
  }

  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _filteredTitles.count;
}

- (nullable NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
  if (_allTitles == nil) {
    return @"Loading GameTDB's title list...";
  }
  if (_filteredTitles.count == 0) {
    return @"Type at least 2 characters to search.";
  }
  return @"Results are capped at 200 - keep typing to narrow it down.";
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
  }

  CoverArtTitle* title = _filteredTitles[indexPath.row];
  cell.textLabel.text = title.name;
  cell.detailTextLabel.text = title.gameID;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  CoverArtTitle* title = _filteredTitles[indexPath.row];
  CoverArtPreviewViewController* preview =
      [[CoverArtPreviewViewController alloc] initWithGameFileWrapper:_gameFileWrapper title:title];
  [self.navigationController pushViewController:preview animated:YES];
}

@end
