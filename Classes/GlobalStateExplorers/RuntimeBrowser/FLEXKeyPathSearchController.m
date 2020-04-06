//
//  FLEXKeyPathSearchController.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXKeyPathSearchController.h"
#import "FLEXRuntimeKeyPathTokenizer.h"
#import "FLEXRuntimeController.h"
#import "NSString+FLEX.h"
#import "NSArray+FLEX.h"
#import "UITextField+Range.h"
#import "NSTimer+FLEX.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXKeyPathSearchController ()
@property (nonatomic, readonly, weak) id<FLEXKeyPathSearchControllerDelegate> delegate;
@property (nonatomic) NSTimer *timer;
/// If \c keyPath is \c nil or if it only has a \c bundleKey, this is
/// a list of bundle key path components like \c UICatalog or \c UIKit\.framework
/// If \c keyPath has more than a \c bundleKey then it is a list of class names.
@property (nonatomic) NSArray<NSString *> *bundlesOrClasses;
/// nil when search bar is empty
@property (nonatomic) FLEXRuntimeKeyPath *keyPath;

@property (nonatomic, readonly) NSString *emptySuggestion;

/// Used to track which methods go with which classes. This is used in
/// two scenarios: (1) when the target class is absolute and has classes,
/// (this list will include the "leaf" class as well as parent classes in this case)
/// or (2) when the class key is a wildcard and we're searching methods in many
/// classes at once. Each list in \c classesToMethods correspnds to a class here.
@property (nonatomic) NSArray<NSString *> *classes;
/// A filtered version of \c classes used when searching for a specific attribute.
/// Classes with no matching ivars/properties/methods are not shown.
@property (nonatomic) NSArray<NSString *> *filteredClasses;
// We use this regardless of whether the target class is absolute, just as above
@property (nonatomic) NSArray<NSArray<FLEXMethod *> *> *classesToMethods;
@end

@implementation FLEXKeyPathSearchController

+ (instancetype)delegate:(id<FLEXKeyPathSearchControllerDelegate>)delegate {
    FLEXKeyPathSearchController *controller = [self new];
    controller->_bundlesOrClasses = [FLEXRuntimeController allBundleNames];
    controller->_delegate         = delegate;
    controller->_emptySuggestion  = NSBundle.mainBundle.executablePath.lastPathComponent;

    NSParameterAssert(delegate.tableView);
    NSParameterAssert(delegate.searchController);

    delegate.tableView.delegate   = controller;
    delegate.tableView.dataSource = controller;
    
    UISearchBar *searchBar = delegate.searchController.searchBar;
    searchBar.delegate = controller;   
    searchBar.keyboardType = UIKeyboardTypeWebSearch;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    if (@available(iOS 11, *)) {
        searchBar.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    }

    return controller;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
        [self.delegate.searchController.searchBar resignFirstResponder];
    }
}

- (void)setToolbar:(FLEXRuntimeBrowserToolbar *)toolbar {
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

    self.keyPath = [FLEXRuntimeKeyPathTokenizer tokenizeString:keyPath];

    // Get classes if class was selected
    if (self.keyPath.classKey.isAbsolute && self.keyPath.methodKey.isAny) {
        [self didSelectAbsoluteClass:text];
    } else {
        self.classes = nil;
        self.filteredClasses = nil;
    }

    [self updateTable];
}

- (void)didSelectAbsoluteClass:(NSString *)name {
    self.classes          = [self classesOf:name];
    self.filteredClasses  = self.classes;
    self.bundlesOrClasses = nil;
    self.classesToMethods = nil;
}

- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar {
    [self.toolbar setKeyPath:self.keyPath suggestions:nil];
    
    // Available since at least iOS 9, still present in iOS 13
    UITextField *field = [searchBar valueForKey:@"_searchBarTextField"];

    if ([self searchBar:searchBar shouldChangeTextInRange:field.selectedRange replacementText:text]) {
        [field replaceRange:field.selectedTextRange withText:text];
    }
}

- (NSArray<NSString *> *)suggestions {
    if (self.bundlesOrClasses) {
        if (self.classes) {
            if (self.classesToMethods) {
                // We have selected a class and are searching metadata
                return nil;
            }
            
            // We are currently searching classes
            return [self.filteredClasses flex_subArrayUpto:10];
        }
        
        if (!self.keyPath) {
            // Search bar is empty
            return @[self.emptySuggestion];
        }
        
        // We are currently searching bundles
        return [self.bundlesOrClasses flex_subArrayUpto:10];
    }
    
    // We have nothing at all to even search
    return nil;
}

#pragma mark - Filtering + UISearchBarDelegate

- (void)updateTable {
    // Compute the method, class, or bundle lists on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.classes) {
            // Here, our class key is 'absolute'; .classes is a list of superclasses
            // and we want to show the methods for those classes specifically
            // TODO: add caching to this somehow
            NSMutableArray *methods = [FLEXRuntimeController
                methodsForToken:self.keyPath.methodKey
                instance:self.keyPath.instanceMethods
                inClasses:self.classes
            ].mutableCopy;
            
            // Remove classes without results if we're searching for a method
            //
            // Note: this will remove classes without any methods or overrides
            // even if the query doesn't specify a method, like `*.*.`
            if (self.keyPath.methodKey) {
                [self setNonEmptyMethodLists:methods withClasses:self.classes.mutableCopy];
            } else {
                self.filteredClasses = self.classes;
            }
        }
        else {
            FLEXRuntimeKeyPath *keyPath = self.keyPath;
            NSArray *models = [FLEXRuntimeController dataForKeyPath:keyPath];
            if (keyPath.methodKey) { // We're looking at methods
                self.bundlesOrClasses = nil;
                
                NSMutableArray *methods = models.mutableCopy;
                NSMutableArray<NSString *> *classes = [
                    FLEXRuntimeController classesForKeyPath:keyPath
                ];
                self.classes = classes;
                [self setNonEmptyMethodLists:methods withClasses:classes];
            } else { // We're looking at bundles or classes
                self.bundlesOrClasses = models;
                self.classesToMethods = nil;
            }
        }
        
        // Finally, reload the table on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateToolbarButtons];
            [self.delegate.tableView reloadData];
        });
    });
}

- (void)updateToolbarButtons {
    // Update toolbar buttons
    [self.toolbar setKeyPath:self.keyPath suggestions:self.suggestions];
}

/// Assign assign .filteredClasses and .classesToMethods after removing empty sections
- (void)setNonEmptyMethodLists:(NSMutableArray<NSArray<FLEXMethod *> *> *)methods
                   withClasses:(NSMutableArray<NSString *> *)classes {
    // Remove sections with no methods
    NSIndexSet *allEmpty = [methods indexesOfObjectsPassingTest:^BOOL(NSArray *list, NSUInteger idx, BOOL *stop) {
        return list.count == 0;
    }];
    [methods removeObjectsAtIndexes:allEmpty];
    [classes removeObjectsAtIndexes:allEmpty];
    
    self.filteredClasses = classes;
    self.classesToMethods = methods;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Check if character is even legal
    if (![FLEXRuntimeKeyPathTokenizer allowedInKeyPath:text]) {
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
        self.keyPath = [FLEXRuntimeKeyPathTokenizer tokenizeString:text];
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

    // Schedule update timer
    if (searchText.length) {
        if (!self.keyPath.methodKey) {
            self.classes = nil;
            self.filteredClasses = nil;
        }

        self.timer = [NSTimer fireSecondsFromNow:0.15 block:^{
            [self updateTable];
        }];
    }
    // ... or remove all rows
    else {
        _bundlesOrClasses = [FLEXRuntimeController allBundleNames];
        _classesToMethods = nil;
        _classes = nil;
        _keyPath = nil;
        [self updateToolbarButtons];
        [self.delegate.tableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.keyPath = FLEXRuntimeKeyPath.empty;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredClasses.count ?: self.bundlesOrClasses.count;
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
    else if (self.filteredClasses.count) {
        NSArray<FLEXMethod *> *methods = self.classesToMethods[indexPath.row];
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
        cell.textLabel.text       = self.filteredClasses[indexPath.row];
        if (@available(iOS 10, *)) {
            cell.detailTextLabel.text = summary.length ? summary : nil;
        }

    }
    else {
        @throw NSInternalInconsistencyException;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.filteredClasses || self.keyPath.methodKey) {
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
    if (self.filteredClasses || self.keyPath.methodKey) {
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
        if (self.filteredClasses.count) {
            Class cls = NSClassFromString(self.filteredClasses[indexPath.row]);
            NSParameterAssert(cls);
            [self.delegate didSelectClass:cls];
        } else {
            @throw NSInternalInconsistencyException;
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *bundleSuffixOrClass = self.bundlesOrClasses[indexPath.row];
    NSString *imagePath = [FLEXRuntimeController imagePathWithShortName:bundleSuffixOrClass];
    NSBundle *bundle = [NSBundle bundleWithPath:imagePath.stringByDeletingLastPathComponent];

    if (bundle) {
        [self.delegate didSelectBundle:bundle];
    } else {
        [self.delegate didSelectImagePath:imagePath shortName:bundleSuffixOrClass];
    }
}

@end

