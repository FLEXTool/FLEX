//
//  TBKeyPathViewController.m
//  TBTweakViewController
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathViewController.h"
#import "TBKeyPathSearchController.h"
#import "TBKeyPathToolbar.h"
#import "UIGestureRecognizer+Blocks.h"
//#import "TBCodeFontCell.h"


@interface TBKeyPathViewController () <TBKeyPathSearchControllerDelegate>

@property (nonatomic, readonly ) TBKeyPathSearchController *searchController;
@property (nonatomic, readonly ) UIView *promptView;
@property (nonatomic, readwrite) UITableView *tableView;
@property (nonatomic, readwrite) UISearchBar *searchBar;

// .@property (nonatomic, readonly) void (^callback)();

@end

@implementation TBKeyPathViewController
@dynamic navigationController;

#pragma mark - Setup, view events

- (void)loadView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.searchBar = [UISearchBar new];
    self.view = self.tableView;
    [self.searchBar sizeToFit];

    self.tableView.tableHeaderView = self.searchBar;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Choose Hook";

    // Search controller stuff
    _searchController = [TBKeyPathSearchController delegate:self];
    _searchController.toolbar = [TBKeyPathToolbar toolbarWithHandler:^(NSString *buttonTitle) {
        [self.searchController didPressButton:buttonTitle insertInto:self.searchBar];
    }];

    // Search bar stuff
    self.searchBar.delegate    = self.searchController;
    self.searchBar.placeholder = @"UIKit*.UIView.-setFrame:";
    self.searchBar.inputAccessoryView = self.searchController.toolbar;

    // Table view stuff
    self.tableView.rowHeight = UITableViewAutomaticDimension;
//    [self.tableView registerCell:[TBCodeFontCell class]];

    // Long press gesture for classes
    [self.tableView addGestureRecognizer:[UILongPressGestureRecognizer action:^(UIGestureRecognizer *gesture) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
            [self.searchController longPressedRect:cell.frame at:ip];
        }
    }]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.searchBar resignFirstResponder];
}

#pragma mark Delegate stuff

- (void)didSelectMethod:(FLEXMethod *)method {

}


#pragma mark Long press action

- (NSString *)longPressItemSELPrefix { return @"tb_"; }

- (void)didSelectSuperclass:(NSString *)title {
    [self.searchController didSelectSuperclass:title];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [@((char*)(void*)action) hasPrefix:self.longPressItemSELPrefix];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if ([super methodSignatureForSelector:sel]) {
        return [super methodSignatureForSelector:sel];
    }

    return [super methodSignatureForSelector:@selector(didSelectSuperclass:)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *title = NSStringFromSelector([invocation selector]);
    NSRange match = [title rangeOfString:self.longPressItemSELPrefix];
    if (match.location == 0) {
        [self didSelectSuperclass:[title substringFromIndex:3]];
    } else {
        [super forwardInvocation:invocation];
    }
}

@end
