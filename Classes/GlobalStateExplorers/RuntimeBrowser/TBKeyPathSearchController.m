//
//  FLEXKeyPathSearchController.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathSearchController.h"
#import "TBKeyPathTokenizer.h"
#import "TBRuntimeController.h"
#import "NSString+FLEX.h"
#import "NSArray+Functional.h"
#import "UITextField+Range.h"
#import "NSTimer+Blocks.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface TBKeyPathSearchController ()
@property (nonatomic, readonly, weak) id<TBKeyPathSearchControllerDelegate> delegate;
@property (nonatomic, readonly) NSTimer *timer;
@property (nonatomic) NSArray<NSString*> *bundlesOrClasses;
@property (nonatomic) TBKeyPath *keyPath;

/// Used to track which methods go with which classes. This is used in
/// two scenarios: (1) when the target class is absolute and has classes,
/// (this list will include the "leaf" class as well as parent classes in this case)
/// or (2) when the class key is a wildcard and we're searching methods in many
/// classes at once. Each list in \c classesToMethods correspnds to a class here.
@property (nonatomic) NSArray<NSString *> *classes;
// We use this regardless of whether the target class is absolute, just as above
@property (nonatomic) NSArray<NSArray<FLEXMethod *> *> *classesToMethods;
@end

#warning TODO there's no code to handle refreshing the table after manually appending ".bar" to "Bundle"
@implementation TBKeyPathSearchController

+ (instancetype)delegate:(id<TBKeyPathSearchControllerDelegate>)delegate {
    TBKeyPathSearchController *controller = [self new];
    controller->_bundlesOrClasses = [TBRuntimeController allBundleNames];
    controller->_delegate         = delegate;

    NSParameterAssert(delegate.tableView);
    NSParameterAssert(delegate.searchController);

    delegate.tableView.delegate   = controller;
    delegate.tableView.dataSource = controller;
    delegate.searchController.searchBar.delegate = controller;    

    return controller;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
        [self.delegate.searchController.searchBar resignFirstResponder];
    }
}

- (void)setToolbar:(TBKeyPathToolbar *)toolbar {
    _toolbar = toolbar;
    self.delegate.searchController.searchBar.inputAccessoryView = toolbar;
}

- (NSArray<NSString *> *)classesOf:(NSString *)className {
    Class baseClass = NSClassFromString(className);
    if (!baseClass) {
        return @[];
    }

    // Find classes
    NSMutableArray<NSString*> *classes = [NSMutableArray arrayWithObject:className];
    while ([baseClass superclass]) {
        [classes addObject:NSStringFromClass([baseClass superclass])];
        baseClass = [baseClass superclass];
    }

    return classes;
}

#pragma mark Key path stuff

- (void)didSelectKeyPathOption:(NSString *)text {
    [_timer invalidate]; // Still might be waiting to refresh when method is selected

    // Change "Bundle.fooba" to "Bundle.foobar."
    NSString *orig = self.delegate.searchController.searchBar.text;
    NSString *keyPath = [orig stringByReplacingLastKeyPathComponent:text];
    self.delegate.searchController.searchBar.text = keyPath;

    self.keyPath = [TBKeyPathTokenizer tokenizeString:keyPath];

    // Get classes if class was selected
    if (self.keyPath.classKey.isAbsolute && self.keyPath.methodKey.isAny) {
        [self didSelectAbsoluteClass:text];
    } else {
        self.classes = nil;
    }

    [self updateTable];
}

- (void)didSelectAbsoluteClass:(NSString *)name {
    self.classes          = [self classesOf:name];
    self.bundlesOrClasses = nil;
    self.classesToMethods = nil;
}

- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar {
    // Available since at least iOS 9, still present in iOS 13
    UITextField *field = [searchBar valueForKey:@"_searchBarTextField"];

    if ([self searchBar:searchBar shouldChangeTextInRange:field.selectedRange replacementText:text]) {
        [field replaceRange:field.selectedTextRange withText:text];
    }
}

#pragma mark - Filtering + UISearchBarDelegate

- (void)updateTable {
    // Compute the method, class, or bundle lists on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.classes) {
            // Here, our class key is 'absolute'; .classes is a list of superclasses
            // and we want to show the methods for those classes specifically
            // TODO: add caching to this somehow
            self.classesToMethods = [TBRuntimeController
                methodsForToken:self.keyPath.methodKey
                instance:self.keyPath.instanceMethods
                inClasses:self.classes
            ];
        }
        else {
            TBKeyPath *keyPath = self.keyPath;
            NSArray *models = [TBRuntimeController dataForKeyPath:keyPath];
            if (keyPath.methodKey) { // We're looking at methods
                self.bundlesOrClasses = nil;
                
                NSMutableArray *methods = models.mutableCopy;
                NSMutableArray *classes = [TBRuntimeController classesForKeyPath:keyPath];
                [self setNonEmptyMethodLists:methods withClasses:classes];
            } else { // We're looking at bundles or classes
                self.bundlesOrClasses = models;
                self.classesToMethods = nil;
            }
        }
        
        // Finally, reload the table on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate.tableView reloadData];
        });
    });
}

/// Assign .classes and .classesToMethods after removing empty sections
- (void)setNonEmptyMethodLists:(NSMutableArray<NSArray *> *)methods withClasses:(NSMutableArray *)classes {
    // Remove sections with no methods
    NSIndexSet *allEmpty = [methods indexesOfObjectsPassingTest:^BOOL(NSArray *list, NSUInteger idx, BOOL *stop) {
        return list.count == 0;
    }];
    [methods removeObjectsAtIndexes:allEmpty];
    [classes removeObjectsAtIndexes:allEmpty];
    
    self.classes = classes;
    self.classesToMethods = methods;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Check if character is even legal
    if (![TBKeyPathTokenizer allowedInKeyPath:text]) {
        return NO;
    }
    
    BOOL terminatedToken = NO;
    BOOL isAppending = range.length == 0 && range.location == searchBar.text.length;
    if (isAppending && [text isEqualToString:@"."]) {
        terminatedToken = YES;
    }

    // Actually parse input
    @try {
        text = [searchBar.text stringByReplacingCharactersInRange:range withString:text] ?: text;
        self.keyPath = [TBKeyPathTokenizer tokenizeString:text];
        if (self.keyPath.classKey.isAbsolute && terminatedToken) {
            [self didSelectAbsoluteClass:self.keyPath.classKey.string];
        }
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
            self.classes = nil;
        }

        _timer = [NSTimer fireSecondsFromNow:0.15 block:^{
            [self updateTable];
        }];
    }
    // ... or remove all rows
    else {
        _bundlesOrClasses = [TBRuntimeController allBundleNames];
        _classesToMethods = nil;
        _classes = nil;
        _keyPath = nil;
        [self.delegate.tableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.keyPath = [TBKeyPath empty];
    [self updateTable];
}

/// Restore key path when going "back" and activating search bar again
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.text = self.keyPath.description;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_timer invalidate];
    [searchBar resignFirstResponder];
    [self updateTable];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.classes.count ?: 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.classes.count ? 1 : self.bundlesOrClasses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView
        dequeueReusableCellWithIdentifier:kFLEXMultilineDetailCell
        forIndexPath:indexPath
    ];
    
    if (self.bundlesOrClasses.count) {
        cell.accessoryType        = UITableViewCellAccessoryDetailButton;
        cell.textLabel.text       = self.bundlesOrClasses[indexPath.row];
        cell.detailTextLabel.text = nil;
        if (self.keyPath.classKey) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    // One row per section
    else if (self.classes.count) {
        NSArray<FLEXMethod *> *methods = self.classesToMethods[indexPath.section];
        NSMutableString *summary = [NSMutableString new];
        [methods enumerateObjectsUsingBlock:^(FLEXMethod *method, NSUInteger idx, BOOL *stop) {
            NSString *format = nil;
            if (idx == methods.count-1) {
                format = @"%@%@";
                *stop = YES;
            } else if (idx < 3) {
                format = @"%@%@\n";
            } else {
                format = @"%@%@\n…";
                *stop = YES;
            }

            [summary appendFormat:format, method.isInstanceMethod ? @"-" : @"+", method.selectorString];
        }];

        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text       = self.classes[indexPath.section];
        cell.detailTextLabel.text = summary.length ? summary : nil;

    }
    else {
        @throw NSInternalInconsistencyException;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.classes || self.keyPath.methodKey) {
        return @" ";
    } else if (self.bundlesOrClasses) {
        NSInteger count = self.bundlesOrClasses.count;
        if (self.keyPath.classKey) {
            return FLEXPluralString(count, @"classes", @"class");
        } else {
            return FLEXPluralString(count, @"bundles", @"bundle");
        }
    }

    return [self.delegate tableView:tableView titleForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.classes || self.keyPath.methodKey) {
        if (section == 0) {
            return 55;
        }

        return 0;
    }

    return 55;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.bundlesOrClasses) {
        NSString *bundleSuffixOrClass = self.bundlesOrClasses[indexPath.row];
        if (self.keyPath.classKey) {
            NSParameterAssert(NSClassFromString(bundleSuffixOrClass));
            [self.delegate didSelectClass:NSClassFromString(bundleSuffixOrClass)];
        } else {
            // Selected a bundle
            [self didSelectKeyPathOption:bundleSuffixOrClass];
        }
    } else {
        if (self.classes) {
            Class cls = NSClassFromString(self.classes[indexPath.section]);
            NSParameterAssert(cls);
            [self.delegate didSelectClass:cls];
        } else {
            @throw NSInternalInconsistencyException;
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *bundleSuffixOrClass = self.bundlesOrClasses[indexPath.row];
    NSString *imagePath = [TBRuntimeController imagePathWithShortName:bundleSuffixOrClass];
    NSBundle *bundle = [NSBundle bundleWithPath:imagePath.stringByDeletingLastPathComponent];

    if (bundle) {
        [self.delegate didSelectBundle:bundle];
    } else {
        [self.delegate didSelectImagePath:imagePath shortName:bundleSuffixOrClass];
    }
}

@end

