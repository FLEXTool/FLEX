//
//  TBKeyPathSearchController.m
//  TBTweakViewController
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathSearchController.h"
#import "TBKeyPathTokenizer.h"
#import "TBRuntimeController.h"
//#import "TBCodeFontCell.h"
#import "NSString+KeyPaths.h"
#import "Categories.h"

#import "TBConfigureHookViewController.h"
#import "TBTweakManager.h"
#import "TBMethodHook.h"


@interface TBKeyPathSearchController ()
@property (nonatomic, readonly, weak) id<TBKeyPathSearchControllerDelegate> delegate;
@property (nonatomic, readonly) NSTimer *timer;
@property (nonatomic) NSArray<NSString*> *bundlesOrClasses;
@property (nonatomic) TBKeyPath *keyPath;

// We use this when the target class is not absolute
@property (nonatomic) NSArray<FLEXMethod*> *methods;

// We use these when the target class is absolute and has superclasses.
// Contrary to the name, superclasses contains the origin class name as well.
@property (nonatomic) NSArray<NSString*> *superclasses;
@property (nonatomic) NSDictionary<NSString*, NSArray*> *classesToMethods;
@end

#warning TODO there's no code to handle refreshing the table after manually appending ".bar" to "Bundle"
@implementation TBKeyPathSearchController

+ (instancetype)delegate:(id<TBKeyPathSearchControllerDelegate>)delegate {
    TBKeyPathSearchController *controller = [self new];
    controller->_bundlesOrClasses = [TBRuntimeController allBundleNames];
    controller->_delegate         = delegate;

    NSParameterAssert(delegate.tableView);
    NSParameterAssert(delegate.searchBar);

    delegate.tableView.delegate   = controller;
    delegate.tableView.dataSource = controller;
    delegate.searchBar.delegate   = controller;

    return controller;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
        [self.delegate.searchBar resignFirstResponder];
    }
}

#pragma mark Long press on class cell

- (void)longPressedRect:(CGRect)rect at:(NSIndexPath *)indexPath {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = [self menuItemsForRow:indexPath.row];
    if (menuController.menuItems) {
        [self.delegate.searchBar resignFirstResponder];
        [menuController setTargetRect:rect inView:self.delegate.tableView];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (NSArray *)menuItemsForRow:(NSUInteger)row {
    if (!self.keyPath.methodKey && self.keyPath.classKey) {
        NSArray<NSString*> *superclasses = [self superclassesOf:self.bundlesOrClasses[row]];

        // Map to UIMenuItems, will delegate call into didSelectKeyPathOption:
        return [superclasses flex_mapped:^id(NSString *cls, NSUInteger idx) {
            NSString *sel = [self.delegate.longPressItemSELPrefix stringByAppendingString:cls];
            return [[UIMenuItem alloc] initWithTitle:cls action:NSSelectorFromString(sel)];
        }];
    }

    return nil;
}

- (NSArray<NSString*> *)superclassesOf:(NSString *)className {
    Class baseClass = NSClassFromString(className);

    // Find superclasses
    NSMutableArray<NSString*> *superclasses = [NSMutableArray array];
    while ([baseClass superclass]) {
        [superclasses addObject:NSStringFromClass([baseClass superclass])];
        baseClass = [baseClass superclass];
    }

    return superclasses;
}

#pragma mark Key path stuff

- (void)didSelectSuperclass:(NSString *)name {
    NSString *bundle = [TBRuntimeController shortBundleNameForClass:name];
    bundle = [bundle stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    NSString *newText = [NSString stringWithFormat:@"%@.%@.", bundle, name];
    self.delegate.searchBar.text = newText;

    // Update list
    self.keyPath = [TBKeyPathTokenizer tokenizeString:newText];
    [self didSelectAbsoluteClass:name];
    [self updateTable];
}

- (void)didSelectKeyPathOption:(NSString *)text {
    [_timer invalidate]; // Still might be waiting to refresh when method is selected

    // Change "Bundle.fooba" to "Bundle.foobar."
    NSString *orig = self.delegate.searchBar.text;
    NSString *keyPath = [orig stringByReplacingLastKeyPathComponent:text];
    self.delegate.searchBar.text = keyPath;

    self.keyPath = [TBKeyPathTokenizer tokenizeString:keyPath];

    // Get superclasses if class was selected
    if (self.keyPath.classKey.isAbsolute && self.keyPath.methodKey.isAny) {
        [self didSelectAbsoluteClass:text];
    } else {
        self.superclasses = nil;
    }

    [self updateTable];
}

- (void)didSelectMethod:(FLEXMethod *)method {
    // If the user selects a method implemented only by a superclass,
    // we're going to be adding a method. We need to take the given
    // method and change it's target class to the base class.
    Class target = NSClassFromString(self.keyPath.classKey.string);
    if (self.keyPath.classKey.isAbsolute && method.targetClass != target) {
        #warning TODO clean this up
        method = [FLEXMethod method:method.objc_method class:target isInstanceMethod:method.isInstanceMethod];
    }

    [self.delegate didSelectMethod:method];
}

- (void)didSelectAbsoluteClass:(NSString *)name {
    NSMutableArray *superclasses = [NSMutableArray array];
    [superclasses addObject:name];
    [superclasses addObjectsFromArray:[self superclassesOf:name]];
    self.superclasses     = superclasses;
    self.bundlesOrClasses = nil;
    self.methods          = nil;
}

- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar {
    UITextField *field = [searchBar valueForKey:@"_searchField"];

    if ([self searchBar:searchBar shouldChangeTextInRange:field.selectedRange replacementText:text]) {
        [field replaceRange:field.selectedTextRange withText:text];
    }
}

#pragma mark - Filtering + UISearchBarDelegate

- (void)updateTable {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.superclasses) {
            // Compute methods list, reload table
            self.classesToMethods = [TBRuntimeController methodsForToken:_keyPath.methodKey
                                                                instance:_keyPath.instanceMethods
                                                               inClasses:_superclasses];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate.tableView reloadData];
            });
        }
        else {
            NSArray *models = [TBRuntimeController dataForKeyPath:_keyPath];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (_keyPath.methodKey) {
                    _bundlesOrClasses = nil;
                    _methods = models;
                } else {
                    _bundlesOrClasses = models;
                    _methods = nil;
                }

                [self.delegate.tableView reloadData];
            });
        }
    });
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Check if character is even legal
    if (![TBKeyPathTokenizer allowedInKeyPath:text]) {
        return NO;
    }

    // Actually parse input
    @try {
        text = [searchBar.text stringByReplacingCharactersInRange:range withString:text] ?: text;
        self.keyPath = [TBKeyPathTokenizer tokenizeString:text];
    } @catch (id e) {
        return NO;
    }

    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [_timer invalidate];

    // Update toolbar buttons
    [self.toolbar setKeyPath:self.keyPath animated:YES];

    // Schedule update timer
    if (searchText.length) {
        if (!self.keyPath.methodKey) {
            self.superclasses = nil;
        }

        _timer = [NSTimer fireSecondsFromNow:0.15 block:^{
            [self updateTable];
        }];
    }
    // ... or remove all rows
    else {
        _bundlesOrClasses = [TBRuntimeController allBundleNames];
        _methods = nil;
        [self.delegate.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_timer invalidate];
    [searchBar resignFirstResponder];
    [self updateTable];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _superclasses.count ?: 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_superclasses) {
        return _classesToMethods[_superclasses[section]].count;
    }

    NSArray *models = (id)_bundlesOrClasses ?: (id)_methods;
    return models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [TBCodeFontCell dequeue:tableView indexPath:indexPath];
    if (self.bundlesOrClasses) {
        cell.accessoryType        = UITableViewCellAccessoryNone;
        cell.textLabel.text       = self.bundlesOrClasses[indexPath.row];
        cell.detailTextLabel.text = nil;
    }
    else if (self.superclasses) {
        NSString *className       = self.superclasses[indexPath.section];
        FLEXMethod *method          = self.classesToMethods[className][indexPath.row];
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text       = method.fullName;
        cell.detailTextLabel.text = method.selectorString;
    }
    else {
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text       = self.methods[indexPath.row].fullName;
        cell.detailTextLabel.text = self.methods[indexPath.row].selectorString;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.superclasses) {
        return [self.superclasses[section] stringByAppendingString:@" methods"];
    }

    return nil;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.bundlesOrClasses) {
        tableView.contentOffset = CGPointMake(0, - self.delegate.searchBar.frame.size.height - 20);
        [self didSelectKeyPathOption:self.bundlesOrClasses[indexPath.row]];
    } else {
        if (self.superclasses) {
            NSString *superclass = self.superclasses[indexPath.section];
            [self didSelectMethod:self.classesToMethods[superclass][indexPath.row]];
        } else {
            assert(indexPath.section == 0);
            [self didSelectMethod:self.methods[indexPath.row]];
        }
    }
}

@end

