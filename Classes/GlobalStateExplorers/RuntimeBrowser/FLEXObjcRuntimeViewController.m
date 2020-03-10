//
//  FLEXObjcRuntimeViewController.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXObjcRuntimeViewController.h"
#import "FLEXKeyPathSearchController.h"
#import "FLEXRuntimeBrowserToolbar.h"
#import "UIGestureRecognizer+Blocks.h"
#import "FLEXTableView.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXAlert.h"

@interface FLEXObjcRuntimeViewController () <FLEXKeyPathSearchControllerDelegate>

@property (nonatomic, readonly ) FLEXKeyPathSearchController *keyPathController;
@property (nonatomic, readonly ) UIView *promptView;

@end

@implementation FLEXObjcRuntimeViewController

#pragma mark - Setup, view events

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Search bar stuff, must be first because this creates self.searchController
    self.showsSearchBar = YES;
    self.showSearchBarInitially = YES;
    // Using pinSearchBar on this screen causes a weird visual
    // thing on the next view controller that gets pushed.
    //
    // self.pinSearchBar = YES;
    self.searchController.searchBar.placeholder = @"UIKit*.UIView.-setFrame:";

    // Search controller stuff
    // key path controller automatically assigns itself as the delegate of the search bar
    // To avoid a retain cycle below, use local variables
    UISearchBar *searchBar = self.searchController.searchBar;
    FLEXKeyPathSearchController *keyPathController = [FLEXKeyPathSearchController delegate:self];
    _keyPathController = keyPathController;
    _keyPathController.toolbar = [FLEXRuntimeBrowserToolbar toolbarWithHandler:^(NSString *text, BOOL suggestion) {
        if (suggestion) {
            [keyPathController didSelectKeyPathOption:text];
        } else {
            [keyPathController didPressButton:text insertInto:searchBar];
        }
    } suggestions:keyPathController.suggestions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // This doesn't work unless it's wrapped in this dispatch_async call
        [self.searchController.searchBar becomeFirstResponder];
    });
}


#pragma mark Delegate stuff

- (void)didSelectImagePath:(NSString *)path shortName:(NSString *)shortName {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(shortName);
        make.message(@"No NSBundle associated with this path:\n\n");
        make.message(path);

        make.button(@"Copy Path").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = path;
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

- (void)didSelectBundle:(NSBundle *)bundle {
    NSParameterAssert(bundle);
    FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:bundle];
    [self.navigationController pushViewController:explorer animated:YES];
}

- (void)didSelectClass:(Class)cls {
    NSParameterAssert(cls);
    FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:cls];
    [self.navigationController pushViewController:explorer animated:YES];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"📚  Runtime Browser";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    UIViewController *controller = [self new];
    controller.title = [self globalsEntryTitle:row];
    return controller;
}

@end
