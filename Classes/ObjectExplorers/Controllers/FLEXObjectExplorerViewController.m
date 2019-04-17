//
//  FLEXObjectExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorerViewController.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXMultilineTableViewCell.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXPropertyEditorViewController.h"
#import "FLEXIvarEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXInstancesTableViewController.h"
#import "FLEXTableView.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, FLEXObjectExplorerScope) {
    FLEXObjectExplorerScopeNoInheritance,
    FLEXObjectExplorerScopeWithParent,
    FLEXObjectExplorerScopeAllButNSObject,
    FLEXObjectExplorerScopeNSObjectOnly
};

typedef NS_ENUM(NSUInteger, FLEXMetadataKind) {
    FLEXMetadataKindProperties,
    FLEXMetadataKindIvars,
    FLEXMetadataKindMethods,
    FLEXMetadataKindClassMethods
};

// Convenience boxes to keep runtime properties, ivars, and methods in foundation collections.
@interface FLEXPropertyBox : NSObject
@property (nonatomic, assign) objc_property_t property;
@end
@implementation FLEXPropertyBox
@end

@interface FLEXIvarBox : NSObject
@property (nonatomic, assign) Ivar ivar;
@end
@implementation FLEXIvarBox
@end

@interface FLEXMethodBox : NSObject
@property (nonatomic, assign) Method method;
@end
@implementation FLEXMethodBox
@end

@interface FLEXObjectExplorerViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray<FLEXPropertyBox *> *properties;
@property (nonatomic, strong) NSArray<FLEXPropertyBox *> *propertiesWithParent;
@property (nonatomic, strong) NSArray<FLEXPropertyBox *> *inheritedProperties;
@property (nonatomic, strong) NSArray<FLEXPropertyBox *> *NSObjectProperties;
@property (nonatomic, strong) NSArray<FLEXPropertyBox *> *filteredProperties;

@property (nonatomic, strong) NSArray<FLEXIvarBox *> *ivars;
@property (nonatomic, strong) NSArray<FLEXIvarBox *> *ivarsWithParent;
@property (nonatomic, strong) NSArray<FLEXIvarBox *> *inheritedIvars;
@property (nonatomic, strong) NSArray<FLEXIvarBox *> *NSObjectIvars;
@property (nonatomic, strong) NSArray<FLEXIvarBox *> *filteredIvars;

@property (nonatomic, strong) NSArray<FLEXMethodBox *> *methods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *methodsWithParent;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *inheritedMethods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *NSObjectMethods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *filteredMethods;

@property (nonatomic, strong) NSArray<FLEXMethodBox *> *classMethods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *classMethodsWithParent;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *inheritedClassMethods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *NSObjectClassMethods;
@property (nonatomic, strong) NSArray<FLEXMethodBox *> *filteredClassMethods;

@property (nonatomic, strong) NSArray<Class> *superclasses;
@property (nonatomic, strong) NSArray<Class> *filteredSuperclasses;

@property (nonatomic, strong) NSArray *cachedCustomSectionRowCookies;
@property (nonatomic, strong) NSIndexSet *customSectionVisibleIndexes;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *filterText;
@property (nonatomic, assign) FLEXObjectExplorerScope scope;

@end

@implementation FLEXObjectExplorerViewController

+ (void)initialize
{
    if (self == [FLEXObjectExplorerViewController class]) {
        // Initialize custom menu items for entire app
        UIMenuItem *copyObjectAddress = [[UIMenuItem alloc] initWithTitle:@"Copy Address" action:@selector(copyObjectAddress:)];
        [UIMenuController sharedMenuController].menuItems = @[copyObjectAddress];
        [[UIMenuController sharedMenuController] update];
    }
}

- (void)loadView
{
    self.tableView = [[FLEXTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = [FLEXUtility searchBarPlaceholderText];
    self.searchBar.delegate = self;
    self.searchBar.showsScopeBar = YES;
    [self refreshScopeTitles];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidRefresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload the entire table view rather than just the visible cells because the filtered rows
    // may have changed (i.e. a change in the description row that causes it to get filtered out).
    [self updateTableData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar endEditing:YES];
}

- (void)refreshControlDidRefresh:(id)sender
{
    [self updateTableData];
    [self.refreshControl endRefreshing];
}


#pragma mark - Search

- (void)refreshScopeTitles
{
    if (!self.searchBar) return;

    Class parent = [self.object superclass];
    Class parentSuper = [parent superclass];

    NSMutableArray *scopes = [NSMutableArray arrayWithObject:@"Base"];
    if (parent) {
        [scopes addObject:@"+ Parent"];
    }
    if (parentSuper && parentSuper != [NSObject class]) {
        [scopes addObject:@"+ Inherited"];
    }
    if ([self.object isKindOfClass:[NSObject class]]) {
        [scopes addObject:@"NSObject"];
    }

    self.searchBar.scopeButtonTitles = scopes;
    [self.searchBar sizeToFit];
    [self updateTableData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.scope = selectedScope;
    [self updateDisplayedData];
}

- (NSArray *)metadata:(FLEXMetadataKind)metadataKind forScope:(FLEXObjectExplorerScope)scope
{
    switch (metadataKind) {
        case FLEXMetadataKindProperties:
            switch (self.scope) {
                case FLEXObjectExplorerScopeNoInheritance:
                    return self.properties;
                case FLEXObjectExplorerScopeWithParent:
                    return self.propertiesWithParent;
                case FLEXObjectExplorerScopeAllButNSObject:
                    return self.inheritedProperties;
                case FLEXObjectExplorerScopeNSObjectOnly:
                    return self.NSObjectProperties;
            }
        case FLEXMetadataKindIvars:
            switch (self.scope) {
                case FLEXObjectExplorerScopeNoInheritance:
                    return self.ivars;
                case FLEXObjectExplorerScopeWithParent:
                    return self.ivarsWithParent;
                case FLEXObjectExplorerScopeAllButNSObject:
                    return self.inheritedIvars;
                case FLEXObjectExplorerScopeNSObjectOnly:
                    return self.NSObjectIvars;
            }
        case FLEXMetadataKindMethods:
            switch (self.scope) {
                case FLEXObjectExplorerScopeNoInheritance:
                    return self.methods;
                case FLEXObjectExplorerScopeWithParent:
                    return self.methodsWithParent;
                case FLEXObjectExplorerScopeAllButNSObject:
                    return self.inheritedMethods;
                case FLEXObjectExplorerScopeNSObjectOnly:
                    return self.NSObjectMethods;
            }
        case FLEXMetadataKindClassMethods:
            switch (self.scope) {
                case FLEXObjectExplorerScopeNoInheritance:
                    return self.classMethods;
                case FLEXObjectExplorerScopeWithParent:
                    return self.classMethodsWithParent;
                case FLEXObjectExplorerScopeAllButNSObject:
                    return self.inheritedClassMethods;
                case FLEXObjectExplorerScopeNSObjectOnly:
                    return self.NSObjectClassMethods;
            }
    }
}

- (NSInteger)totalCountOfMetadata:(FLEXMetadataKind)metadataKind forScope:(FLEXObjectExplorerScope)scope
{
    return [self metadata:metadataKind forScope:scope].count;
}

#pragma mark - Setter overrides

- (void)setObject:(id)object
{
    _object = object;
    // Use [object class] here rather than object_getClass because we don't want to show the KVO prefix for observed objects.
    self.title = [[object class] description];
    [self refreshScopeTitles];
}

- (void)setFilterText:(NSString *)filterText
{
    if (_filterText != filterText || ![_filterText isEqual:filterText]) {
        _filterText = filterText;
        [self updateDisplayedData];
    }
}


#pragma mark - Reloading

- (void)updateTableData
{
    [self updateCustomData];
    [self updateProperties];
    [self updateIvars];
    [self updateMethods];
    [self updateClassMethods];
    [self updateSuperclasses];
    [self updateDisplayedData];
}

- (void)updateDisplayedData
{
    [self updateFilteredCustomData];
    [self updateFilteredProperties];
    [self updateFilteredIvars];
    [self updateFilteredMethods];
    [self updateFilteredClassMethods];
    [self updateFilteredSuperclasses];
    
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (BOOL)shouldShowDescription
{
    // Not if we have filter text that doesn't match the desctiption.
    if (self.filterText.length) {
        NSString *description = [self displayedObjectDescription];
        return [description rangeOfString:self.filterText options:NSCaseInsensitiveSearch].length > 0;
    }
    
    return YES;
}

- (NSString *)displayedObjectDescription {
    NSString *desc = [FLEXUtility safeDescriptionForObject:self.object];

    if (!desc.length) {
        NSString *address = [FLEXUtility addressOfObject:self.object];
        desc = [NSString stringWithFormat:@"Object at %@ returned empty description", address];
    }

    return desc;
}


#pragma mark - Properties

- (void)updateProperties
{
    Class class = [self.object class];
    self.properties = [[self class] propertiesForClass:class];
    self.propertiesWithParent = [self.properties arrayByAddingObjectsFromArray:[[self class] propertiesForClass:[class superclass]]];
    self.inheritedProperties = [self.properties arrayByAddingObjectsFromArray:[[self class] inheritedPropertiesForClass:class]];
    self.NSObjectProperties = [[self class] propertiesForClass:[NSObject class]];
}

+ (NSArray<FLEXPropertyBox *> *)propertiesForClass:(Class)class
{
    if (!class) {
        return @[];
    }
    
    NSMutableArray<FLEXPropertyBox *> *boxedProperties = [NSMutableArray array];
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(class, &propertyCount);
    if (propertyList) {
        for (unsigned int i = 0; i < propertyCount; i++) {
            FLEXPropertyBox *propertyBox = [[FLEXPropertyBox alloc] init];
            propertyBox.property = propertyList[i];
            [boxedProperties addObject:propertyBox];
        }
        free(propertyList);
    }
    return boxedProperties;
}

/// Skips NSObject
+ (NSArray<FLEXPropertyBox *> *)inheritedPropertiesForClass:(Class)class
{
    NSMutableArray<FLEXPropertyBox *> *inheritedProperties = [NSMutableArray array];
    while ((class = [class superclass]) && class != [NSObject class]) {
        [inheritedProperties addObjectsFromArray:[self propertiesForClass:class]];
    }
    return inheritedProperties;
}

- (void)updateFilteredProperties
{
    NSArray<FLEXPropertyBox *> *candidateProperties = [self metadata:FLEXMetadataKindProperties forScope:self.scope];
    
    NSArray<FLEXPropertyBox *> *unsortedFilteredProperties = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray<FLEXPropertyBox *> *mutableUnsortedFilteredProperties = [NSMutableArray array];
        for (FLEXPropertyBox *propertyBox in candidateProperties) {
            NSString *prettyName = [FLEXRuntimeUtility prettyNameForProperty:propertyBox.property];
            if ([prettyName rangeOfString:self.filterText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [mutableUnsortedFilteredProperties addObject:propertyBox];
            }
        }
        unsortedFilteredProperties = mutableUnsortedFilteredProperties;
    } else {
        unsortedFilteredProperties = candidateProperties;
    }
    
    self.filteredProperties = [unsortedFilteredProperties sortedArrayUsingComparator:^NSComparisonResult(FLEXPropertyBox *propertyBox1, FLEXPropertyBox *propertyBox2) {
        NSString *name1 = [NSString stringWithUTF8String:property_getName(propertyBox1.property)];
        NSString *name2 = [NSString stringWithUTF8String:property_getName(propertyBox2.property)];
        return [name1 caseInsensitiveCompare:name2];
    }];
}

- (NSString *)titleForPropertyAtIndex:(NSInteger)index
{
    FLEXPropertyBox *propertyBox = self.filteredProperties[index];
    return [FLEXRuntimeUtility prettyNameForProperty:propertyBox.property];
}

- (id)valueForPropertyAtIndex:(NSInteger)index
{
    id value = nil;
    if ([self canHaveInstanceState]) {
        FLEXPropertyBox *propertyBox = self.filteredProperties[index];
        NSString *typeString = [FLEXRuntimeUtility typeEncodingForProperty:propertyBox.property];
        const FLEXTypeEncoding *encoding = [typeString cStringUsingEncoding:NSUTF8StringEncoding];
        value = [FLEXRuntimeUtility valueForProperty:propertyBox.property onObject:self.object];
        value = [FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:value type:encoding];
    }
    return value;
}


#pragma mark - Ivars

- (void)updateIvars
{
    Class class = [self.object class];
    self.ivars = [[self class] ivarsForClass:class];
    self.ivarsWithParent = [self.ivars arrayByAddingObjectsFromArray:[[self class] ivarsForClass:[class superclass]]];
    self.inheritedIvars = [self.ivars arrayByAddingObjectsFromArray:[[self class] inheritedIvarsForClass:class]];
    self.NSObjectIvars = [[self class] ivarsForClass:[NSObject class]];
}

+ (NSArray<FLEXIvarBox *> *)ivarsForClass:(Class)class
{
    if (!class) {
        return @[];
    }
    NSMutableArray<FLEXIvarBox *> *boxedIvars = [NSMutableArray array];
    unsigned int ivarCount = 0;
    Ivar *ivarList = class_copyIvarList(class, &ivarCount);
    if (ivarList) {
        for (unsigned int i = 0; i < ivarCount; i++) {
            FLEXIvarBox *ivarBox = [[FLEXIvarBox alloc] init];
            ivarBox.ivar = ivarList[i];
            [boxedIvars addObject:ivarBox];
        }
        free(ivarList);
    }
    return boxedIvars;
}

/// Skips NSObject
+ (NSArray<FLEXIvarBox *> *)inheritedIvarsForClass:(Class)class
{
    NSMutableArray<FLEXIvarBox *> *inheritedIvars = [NSMutableArray array];
    while ((class = [class superclass]) && class != [NSObject class]) {
        [inheritedIvars addObjectsFromArray:[self ivarsForClass:class]];
    }
    return inheritedIvars;
}

- (void)updateFilteredIvars
{
    NSArray<FLEXIvarBox *> *candidateIvars = [self metadata:FLEXMetadataKindIvars forScope:self.scope];
    
    NSArray<FLEXIvarBox *> *unsortedFilteredIvars = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray<FLEXIvarBox *> *mutableUnsortedFilteredIvars = [NSMutableArray array];
        for (FLEXIvarBox *ivarBox in candidateIvars) {
            NSString *prettyName = [FLEXRuntimeUtility prettyNameForIvar:ivarBox.ivar];
            if ([prettyName rangeOfString:self.filterText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [mutableUnsortedFilteredIvars addObject:ivarBox];
            }
        }
        unsortedFilteredIvars = mutableUnsortedFilteredIvars;
    } else {
        unsortedFilteredIvars = candidateIvars;
    }
    
    self.filteredIvars = [unsortedFilteredIvars sortedArrayUsingComparator:^NSComparisonResult(FLEXIvarBox *ivarBox1, FLEXIvarBox *ivarBox2) {
        NSString *name1 = [NSString stringWithUTF8String:ivar_getName(ivarBox1.ivar)];
        NSString *name2 = [NSString stringWithUTF8String:ivar_getName(ivarBox2.ivar)];
        return [name1 caseInsensitiveCompare:name2];
    }];
}

- (NSString *)titleForIvarAtIndex:(NSInteger)index
{
    FLEXIvarBox *ivarBox = self.filteredIvars[index];
    return [FLEXRuntimeUtility prettyNameForIvar:ivarBox.ivar];
}

- (id)valueForIvarAtIndex:(NSInteger)index
{
    id value = nil;
    if ([self canHaveInstanceState]) {
        FLEXIvarBox *ivarBox = self.filteredIvars[index];
        const FLEXTypeEncoding *encoding = ivar_getTypeEncoding(ivarBox.ivar);
        value = [FLEXRuntimeUtility valueForIvar:ivarBox.ivar onObject:self.object];
        value = [FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:value type:encoding];
    }
    return value;
}


#pragma mark - Methods

- (void)updateMethods
{
    Class class = [self.object class];
    self.methods = [[self class] methodsForClass:class];
    self.methodsWithParent = [self.methods arrayByAddingObjectsFromArray:[[self class] methodsForClass:[class superclass]]];
    self.inheritedMethods = [self.methods arrayByAddingObjectsFromArray:[[self class] inheritedMethodsForClass:class]];
    self.NSObjectMethods = [[self class] methodsForClass:[NSObject class]];
}

- (void)updateFilteredMethods
{
    NSArray<FLEXMethodBox *> *candidateMethods = [self metadata:FLEXMetadataKindMethods forScope:self.scope];
    self.filteredMethods = [self filteredMethodsFromMethods:candidateMethods areClassMethods:NO];
}

- (void)updateClassMethods
{
    const char *className = [NSStringFromClass([self.object class]) UTF8String];
    Class metaClass = objc_getMetaClass(className);
    self.classMethods = [[self class] methodsForClass:metaClass];
    self.classMethodsWithParent = [self.classMethods arrayByAddingObjectsFromArray:[[self class] methodsForClass:[metaClass superclass]]];
    self.inheritedClassMethods = [self.classMethods arrayByAddingObjectsFromArray:[[self class] inheritedMethodsForClass:metaClass]];
    self.NSObjectClassMethods = [[self class] methodsForClass:[NSObject class]];
}

- (void)updateFilteredClassMethods
{
    NSArray<FLEXMethodBox *> *candidateMethods = [self metadata:FLEXMetadataKindClassMethods forScope:self.scope];
    self.filteredClassMethods = [self filteredMethodsFromMethods:candidateMethods areClassMethods:YES];
}

+ (NSArray<FLEXMethodBox *> *)methodsForClass:(Class)class
{
    if (!class) {
        return @[];
    }
    
    NSMutableArray<FLEXMethodBox *> *boxedMethods = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(class, &methodCount);
    if (methodList) {
        for (unsigned int i = 0; i < methodCount; i++) {
            FLEXMethodBox *methodBox = [[FLEXMethodBox alloc] init];
            methodBox.method = methodList[i];
            [boxedMethods addObject:methodBox];
        }
        free(methodList);
    }
    return boxedMethods;
}

/// Skips NSObject
+ (NSArray<FLEXMethodBox *> *)inheritedMethodsForClass:(Class)class
{
    NSMutableArray<FLEXMethodBox *> *inheritedMethods = [NSMutableArray array];
    while ((class = [class superclass]) && class != [NSObject class]) {
        [inheritedMethods addObjectsFromArray:[self methodsForClass:class]];
    }
    return inheritedMethods;
}

- (NSArray<FLEXMethodBox *> *)filteredMethodsFromMethods:(NSArray<FLEXMethodBox *> *)methods areClassMethods:(BOOL)areClassMethods
{
    NSArray<FLEXMethodBox *> *candidateMethods = methods;
    NSArray<FLEXMethodBox *> *unsortedFilteredMethods = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray<FLEXMethodBox *> *mutableUnsortedFilteredMethods = [NSMutableArray array];
        for (FLEXMethodBox *methodBox in candidateMethods) {
            NSString *prettyName = [FLEXRuntimeUtility prettyNameForMethod:methodBox.method isClassMethod:areClassMethods];
            if ([prettyName rangeOfString:self.filterText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [mutableUnsortedFilteredMethods addObject:methodBox];
            }
        }
        unsortedFilteredMethods = mutableUnsortedFilteredMethods;
    } else {
        unsortedFilteredMethods = candidateMethods;
    }
    
    NSArray<FLEXMethodBox *> *sortedFilteredMethods = [unsortedFilteredMethods sortedArrayUsingComparator:^NSComparisonResult(FLEXMethodBox *methodBox1, FLEXMethodBox *methodBox2) {
        NSString *name1 = NSStringFromSelector(method_getName(methodBox1.method));
        NSString *name2 = NSStringFromSelector(method_getName(methodBox2.method));
        return [name1 caseInsensitiveCompare:name2];
    }];
    
    return sortedFilteredMethods;
}

- (NSString *)titleForMethodAtIndex:(NSInteger)index
{
    FLEXMethodBox *methodBox = self.filteredMethods[index];
    return [FLEXRuntimeUtility prettyNameForMethod:methodBox.method isClassMethod:NO];
}

- (NSString *)titleForClassMethodAtIndex:(NSInteger)index
{
    FLEXMethodBox *classMethodBox = self.filteredClassMethods[index];
    return [FLEXRuntimeUtility prettyNameForMethod:classMethodBox.method isClassMethod:YES];
}


#pragma mark - Superclasses

+ (NSArray<Class> *)superclassesForClass:(Class)class
{
    NSMutableArray<Class> *superClasses = [NSMutableArray array];
    while ((class = [class superclass])) {
        [superClasses addObject:class];
    }
    return superClasses;
}

- (void)updateSuperclasses
{
    self.superclasses = [[self class] superclassesForClass:[self.object class]];
}

- (void)updateFilteredSuperclasses
{
    if ([self.filterText length] > 0) {
        NSMutableArray<Class> *filteredSuperclasses = [NSMutableArray array];
        for (Class superclass in self.superclasses) {
            if ([NSStringFromClass(superclass) rangeOfString:self.filterText options:NSCaseInsensitiveSearch].length > 0) {
                [filteredSuperclasses addObject:superclass];
            }
        }
        self.filteredSuperclasses = filteredSuperclasses;
    } else {
        self.filteredSuperclasses = self.superclasses;
    }
}


#pragma mark - Table View Data Helpers

- (NSArray<NSNumber *> *)possibleExplorerSections
{
    static NSArray<NSNumber *> *possibleSections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        possibleSections = @[@(FLEXObjectExplorerSectionDescription),
                             @(FLEXObjectExplorerSectionCustom),
                             @(FLEXObjectExplorerSectionProperties),
                             @(FLEXObjectExplorerSectionIvars),
                             @(FLEXObjectExplorerSectionMethods),
                             @(FLEXObjectExplorerSectionClassMethods),
                             @(FLEXObjectExplorerSectionSuperclasses),
                             @(FLEXObjectExplorerSectionReferencingInstances)];
    });
    return possibleSections;
}

- (NSArray<NSNumber *> *)visibleExplorerSections
{
    NSMutableArray<NSNumber *> *visibleSections = [NSMutableArray array];
    
    for (NSNumber *possibleSection in [self possibleExplorerSections]) {
        FLEXObjectExplorerSection explorerSection = [possibleSection unsignedIntegerValue];
        if ([self numberOfRowsForExplorerSection:explorerSection] > 0) {
            [visibleSections addObject:possibleSection];
        }
    }
    
    return visibleSections;
}

- (NSString *)sectionTitleWithBaseName:(NSString *)baseName totalCount:(NSUInteger)totalCount filteredCount:(NSUInteger)filteredCount
{
    NSString *sectionTitle = nil;
    if (totalCount == filteredCount) {
        sectionTitle = [baseName stringByAppendingFormat:@" (%lu)", (unsigned long)totalCount];
    } else {
        sectionTitle = [baseName stringByAppendingFormat:@" (%lu of %lu)", (unsigned long)filteredCount, (unsigned long)totalCount];
    }
    return sectionTitle;
}

- (FLEXObjectExplorerSection)explorerSectionAtIndex:(NSInteger)sectionIndex
{
    return [[[self visibleExplorerSections] objectAtIndex:sectionIndex] unsignedIntegerValue];
}

- (NSInteger)numberOfRowsForExplorerSection:(FLEXObjectExplorerSection)section
{
    NSInteger numberOfRows = 0;
    switch (section) {
        case FLEXObjectExplorerSectionDescription:
            numberOfRows = [self shouldShowDescription] ? 1 : 0;
            break;
            
        case FLEXObjectExplorerSectionCustom:
            numberOfRows = [self.customSectionVisibleIndexes count];
            break;
            
        case FLEXObjectExplorerSectionProperties:
            numberOfRows = [self.filteredProperties count];
            break;
            
        case FLEXObjectExplorerSectionIvars:
            numberOfRows = [self.filteredIvars count];
            break;
            
        case FLEXObjectExplorerSectionMethods:
            numberOfRows = [self.filteredMethods count];
            break;
            
        case FLEXObjectExplorerSectionClassMethods:
            numberOfRows = [self.filteredClassMethods count];
            break;
            
        case FLEXObjectExplorerSectionSuperclasses:
            numberOfRows = [self.filteredSuperclasses count];
            break;
            
        case FLEXObjectExplorerSectionReferencingInstances:
            // Hide this section if there is fliter text since there's nothing searchable (only 1 row, always the same).
            numberOfRows = [self.filterText length] == 0 ? 1 : 0;
            break;
    }
    return numberOfRows;
}

- (NSString *)titleForRow:(NSInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    NSString *title = nil;
    switch (section) {
        case FLEXObjectExplorerSectionDescription:
            title = [self displayedObjectDescription];
            break;
            
        case FLEXObjectExplorerSectionCustom:
            title = [self customSectionTitleForRowCookie:[self customSectionRowCookieForVisibleRow:row]];
            break;
            
        case FLEXObjectExplorerSectionProperties:
            title = [self titleForPropertyAtIndex:row];
            break;
            
        case FLEXObjectExplorerSectionIvars:
            title = [self titleForIvarAtIndex:row];
            break;
            
        case FLEXObjectExplorerSectionMethods:
            title = [self titleForMethodAtIndex:row];
            break;
            
        case FLEXObjectExplorerSectionClassMethods:
            title = [self titleForClassMethodAtIndex:row];
            break;
            
        case FLEXObjectExplorerSectionSuperclasses:
            title = NSStringFromClass(self.filteredSuperclasses[row]);
            break;
            
        case FLEXObjectExplorerSectionReferencingInstances:
            title = @"Other objects with ivars referencing this object";
            break;
    }
    return title;
}

- (NSString *)subtitleForRow:(NSInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    NSString *subtitle = nil;
    switch (section) {
        case FLEXObjectExplorerSectionDescription:
            break;
            
        case FLEXObjectExplorerSectionCustom:
            subtitle = [self customSectionSubtitleForRowCookie:[self customSectionRowCookieForVisibleRow:row]];
            break;
            
        case FLEXObjectExplorerSectionProperties:
            subtitle = [self canHaveInstanceState] ? [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[self valueForPropertyAtIndex:row]] : nil;
            break;
            
        case FLEXObjectExplorerSectionIvars:
            subtitle = [self canHaveInstanceState] ? [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[self valueForIvarAtIndex:row]] : nil;
            break;
            
        case FLEXObjectExplorerSectionMethods:
            break;
            
        case FLEXObjectExplorerSectionClassMethods:
            break;
            
        case FLEXObjectExplorerSectionSuperclasses:
            break;
            
        case FLEXObjectExplorerSectionReferencingInstances:
            break;
    }
    return subtitle;
}

- (BOOL)canDrillInToRow:(NSInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    BOOL canDrillIn = NO;
    switch (section) {
        case FLEXObjectExplorerSectionDescription:
            break;
            
        case FLEXObjectExplorerSectionCustom:
            canDrillIn = [self customSectionCanDrillIntoRowWithCookie:[self customSectionRowCookieForVisibleRow:row]];
            break;
            
        case FLEXObjectExplorerSectionProperties: {
            if ([self canHaveInstanceState]) {
                FLEXPropertyBox *propertyBox = self.filteredProperties[row];
                objc_property_t property = propertyBox.property;
                id currentValue = [self valueForPropertyAtIndex:row];
                BOOL canEdit = [FLEXPropertyEditorViewController canEditProperty:property currentValue:currentValue];
                BOOL canExplore = currentValue != nil;
                canDrillIn = canEdit || canExplore;
            }
        }   break;
            
        case FLEXObjectExplorerSectionIvars: {
            if ([self canHaveInstanceState]) {
                FLEXIvarBox *ivarBox = self.filteredIvars[row];
                Ivar ivar = ivarBox.ivar;
                id currentValue = [self valueForIvarAtIndex:row];
                BOOL canEdit = [FLEXIvarEditorViewController canEditIvar:ivar currentValue:currentValue];
                BOOL canExplore = currentValue != nil;
                canDrillIn = canEdit || canExplore;
            }
        }   break;
            
        case FLEXObjectExplorerSectionMethods:
            canDrillIn = [self canCallInstanceMethods];
            break;
            
        case FLEXObjectExplorerSectionClassMethods:
            canDrillIn = YES;
            break;
            
        case FLEXObjectExplorerSectionSuperclasses:
            canDrillIn = YES;
            break;
            
        case FLEXObjectExplorerSectionReferencingInstances:
            canDrillIn = YES;
            break;
    }
    return canDrillIn;
}

- (BOOL)sectionHasActions:(NSInteger)section
{
    return [self explorerSectionAtIndex:section] == FLEXObjectExplorerSectionDescription;
}

- (NSString *)titleForExplorerSection:(FLEXObjectExplorerSection)section
{
    NSString *title = nil;
    switch (section) {
        case FLEXObjectExplorerSectionDescription: {
            title = @"Description";
        } break;
            
        case FLEXObjectExplorerSectionCustom: {
            title = [self customSectionTitle];
        } break;
            
        case FLEXObjectExplorerSectionProperties: {
            NSUInteger totalCount = [self totalCountOfMetadata:FLEXMetadataKindProperties forScope:self.scope];
            title = [self sectionTitleWithBaseName:@"Properties" totalCount:totalCount filteredCount:[self.filteredProperties count]];
        } break;
            
        case FLEXObjectExplorerSectionIvars: {
            NSUInteger totalCount = [self totalCountOfMetadata:FLEXMetadataKindIvars forScope:self.scope];
            title = [self sectionTitleWithBaseName:@"Ivars" totalCount:totalCount filteredCount:[self.filteredIvars count]];
        } break;
            
        case FLEXObjectExplorerSectionMethods: {
            NSUInteger totalCount = [self totalCountOfMetadata:FLEXMetadataKindMethods forScope:self.scope];
            title = [self sectionTitleWithBaseName:@"Methods" totalCount:totalCount filteredCount:[self.filteredMethods count]];
        } break;
            
        case FLEXObjectExplorerSectionClassMethods: {
            NSUInteger totalCount = [self totalCountOfMetadata:FLEXMetadataKindClassMethods forScope:self.scope];
            title = [self sectionTitleWithBaseName:@"Class Methods" totalCount:totalCount filteredCount:[self.filteredClassMethods count]];
        } break;
            
        case FLEXObjectExplorerSectionSuperclasses: {
            title = [self sectionTitleWithBaseName:@"Superclasses" totalCount:[self.superclasses count] filteredCount:[self.filteredSuperclasses count]];
        } break;
            
        case FLEXObjectExplorerSectionReferencingInstances: {
            title = @"Object Graph";
        } break;
    }
    return title;
}

- (UIViewController *)drillInViewControllerForRow:(NSUInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    UIViewController *viewController = nil;
    switch (section) {
        case FLEXObjectExplorerSectionDescription:
            break;
            
        case FLEXObjectExplorerSectionCustom:
            viewController = [self customSectionDrillInViewControllerForRowCookie:[self customSectionRowCookieForVisibleRow:row]];
            break;
            
        case FLEXObjectExplorerSectionProperties: {
            FLEXPropertyBox *propertyBox = self.filteredProperties[row];
            objc_property_t property = propertyBox.property;
            id currentValue = [self valueForPropertyAtIndex:row];
            if ([FLEXPropertyEditorViewController canEditProperty:property currentValue:currentValue]) {
                viewController = [[FLEXPropertyEditorViewController alloc] initWithTarget:self.object property:property];
            } else if (currentValue) {
                viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
            }
        } break;
            
        case FLEXObjectExplorerSectionIvars: {
            FLEXIvarBox *ivarBox = self.filteredIvars[row];
            Ivar ivar = ivarBox.ivar;
            id currentValue = [self valueForIvarAtIndex:row];
            if ([FLEXIvarEditorViewController canEditIvar:ivar currentValue:currentValue]) {
                viewController = [[FLEXIvarEditorViewController alloc] initWithTarget:self.object ivar:ivar];
            } else if (currentValue) {
                viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
            }
        } break;
            
        case FLEXObjectExplorerSectionMethods: {
            FLEXMethodBox *methodBox = self.filteredMethods[row];
            Method method = methodBox.method;
            viewController = [[FLEXMethodCallingViewController alloc] initWithTarget:self.object method:method];
        } break;
            
        case FLEXObjectExplorerSectionClassMethods: {
            FLEXMethodBox *methodBox = self.filteredClassMethods[row];
            Method method = methodBox.method;
            viewController = [[FLEXMethodCallingViewController alloc] initWithTarget:[self.object class] method:method];
        } break;
            
        case FLEXObjectExplorerSectionSuperclasses: {
            Class superclass = self.filteredSuperclasses[row];
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:superclass];
        } break;
            
        case FLEXObjectExplorerSectionReferencingInstances: {
            viewController = [FLEXInstancesTableViewController instancesTableViewControllerForInstancesReferencingObject:self.object];
        } break;
    }
    return viewController;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self visibleExplorerSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:section];
    return [self numberOfRowsForExplorerSection:explorerSection];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:section];
    return [self titleForExplorerSection:explorerSection];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];

    BOOL isCustomSection = explorerSection == FLEXObjectExplorerSectionCustom;
    BOOL useDescriptionCell = explorerSection == FLEXObjectExplorerSectionDescription;
    NSString *cellIdentifier = useDescriptionCell ? kFLEXMultilineTableViewCellIdentifier : @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if (useDescriptionCell) {
            cell = [[FLEXMultilineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
            cell.textLabel.font = cellFont;
            cell.detailTextLabel.font = cellFont;
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
    }


    UIView *customView;
    if (isCustomSection) {
        customView = [self customViewForRowCookie:[self customSectionRowCookieForVisibleRow:indexPath.row]];
        if (customView) {
            [cell.contentView addSubview:customView];
        }
    }

    cell.textLabel.text = [self titleForRow:indexPath.row inExplorerSection:explorerSection];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row inExplorerSection:explorerSection];
    cell.accessoryType = [self canDrillInToRow:indexPath.row inExplorerSection:explorerSection] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];
    CGFloat height = self.tableView.rowHeight;
    if (explorerSection == FLEXObjectExplorerSectionDescription) {
        NSString *text = [self titleForRow:indexPath.row inExplorerSection:explorerSection];
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName : [FLEXUtility defaultTableViewCellLabelFont] }];
        CGFloat preferredHeight = [FLEXMultilineTableViewCell preferredHeightWithAttributedText:attributedText inTableViewWidth:self.tableView.frame.size.width style:tableView.style showsAccessory:NO];
        height = MAX(height, preferredHeight);
    } else if (explorerSection == FLEXObjectExplorerSectionCustom) {
        id cookie = [self customSectionRowCookieForVisibleRow:indexPath.row];
        height = [self heightForCustomViewRowForRowCookie:cookie];
    }
    
    return height;
}


#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];
    return [self canDrillInToRow:indexPath.row inExplorerSection:explorerSection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];
    UIViewController *detailViewController = [self drillInViewControllerForRow:indexPath.row inExplorerSection:explorerSection];
    if (detailViewController) {
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionHasActions:indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];
    switch (explorerSection) {
        case FLEXObjectExplorerSectionDescription:
            return action == @selector(copy:) || action == @selector(copyObjectAddress:);

        default:
            return NO;
    }
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:action withObject:indexPath];
#pragma clang diagnostic pop
}


#pragma mark - UIMenuController

/// Prevent the search bar from trying to use us as a responder
///
/// Our table cells will use the UITableViewDelegate methods
/// to make sure we can perform the actions we want to
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

- (void)copy:(NSIndexPath *)indexPath
{
    FLEXObjectExplorerSection explorerSection = [self explorerSectionAtIndex:indexPath.section];
    NSString *stringToCopy = @"";

    NSString *title = [self titleForRow:indexPath.row inExplorerSection:explorerSection];
    if (title.length) {
        stringToCopy = [stringToCopy stringByAppendingString:title];
    }

    NSString *subtitle = [self subtitleForRow:indexPath.row inExplorerSection:explorerSection];
    if (subtitle.length) {
        if (stringToCopy.length) {
            stringToCopy = [stringToCopy stringByAppendingString:@"\n\n"];
        }
        stringToCopy = [stringToCopy stringByAppendingString:subtitle];
    }

    [UIPasteboard generalPasteboard].string = stringToCopy;
}

- (void)copyObjectAddress:(NSIndexPath *)indexPath
{
    [UIPasteboard generalPasteboard].string = [FLEXUtility addressOfObject:self.object];
}


#pragma mark - Custom Section

- (void)updateCustomData
{
    self.cachedCustomSectionRowCookies = [self customSectionRowCookies];
}

- (void)updateFilteredCustomData
{
    NSIndexSet *filteredIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.cachedCustomSectionRowCookies count])];
    if ([self.filterText length] > 0) {
        filteredIndexSet = [filteredIndexSet indexesPassingTest:^BOOL(NSUInteger index, BOOL *stop) {
            BOOL matches = NO;
            NSString *rowTitle = [self customSectionTitleForRowCookie:self.cachedCustomSectionRowCookies[index]];
            if ([rowTitle rangeOfString:self.filterText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matches = YES;
            }
            return matches;
        }];
    }
    self.customSectionVisibleIndexes = filteredIndexSet;
}

- (id)customSectionRowCookieForVisibleRow:(NSUInteger)row
{
    return [[self.cachedCustomSectionRowCookies objectsAtIndexes:self.customSectionVisibleIndexes] objectAtIndex:row];
}


#pragma mark - Subclasses Can Override

- (NSString *)customSectionTitle
{
    return nil;
}

- (NSArray *)customSectionRowCookies
{
    return nil;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    return nil;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return nil;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return NO;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    return nil;
}

- (UIView *)customViewForRowCookie:(id)rowCookie
{
    return nil;
}

- (CGFloat)heightForCustomViewRowForRowCookie:(id)rowCookie
{
    return self.tableView.rowHeight;
}

- (BOOL)canHaveInstanceState
{
    return YES;
}

- (BOOL)canCallInstanceMethods
{
    return YES;
}

@end
