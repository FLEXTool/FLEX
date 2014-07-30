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
#import "FLEXDescriptionTableViewCell.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXPropertyEditorViewController.h"
#import "FLEXIvarEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXInstancesTableViewController.h"
#import <objc/runtime.h>

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

static const NSInteger kFLEXObjectExplorerScopeNoInheritanceIndex = 0;
static const NSInteger kFLEXObjectExplorerScopeIncludeInheritanceIndex = 1;

@interface FLEXObjectExplorerViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *properties;
@property (nonatomic, strong) NSArray *inheritedProperties;
@property (nonatomic, strong) NSArray *filteredProperties;

@property (nonatomic, strong) NSArray *ivars;
@property (nonatomic, strong) NSArray *inheritedIvars;
@property (nonatomic, strong) NSArray *filteredIvars;

@property (nonatomic, strong) NSArray *methods;
@property (nonatomic, strong) NSArray *inheritedMethods;
@property (nonatomic, strong) NSArray *filteredMethods;

@property (nonatomic, strong) NSArray *classMethods;
@property (nonatomic, strong) NSArray *inheritedClassMethods;
@property (nonatomic, strong) NSArray *filteredClassMethods;

@property (nonatomic, strong) NSArray *superclasses;
@property (nonatomic, strong) NSArray *filteredSuperclasses;

@property (nonatomic, strong) NSArray *cachedCustomSectionRowCookies;
@property (nonatomic, strong) NSIndexSet *customSectionVisibleIndexes;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *filterText;
@property (nonatomic, assign) BOOL includeInheritance;

@end

@implementation FLEXObjectExplorerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    // Force grouped style
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = [FLEXUtility searchBarPlaceholderText];
    self.searchBar.delegate = self;
    self.searchBar.showsScopeBar = YES;
    self.searchBar.scopeButtonTitles = @[@"No Inheritance", @"Include Inheritance"];
    [self.searchBar sizeToFit];
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

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.filterText = searchText;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    if (selectedScope == kFLEXObjectExplorerScopeIncludeInheritanceIndex) {
        self.includeInheritance = YES;
    } else if (selectedScope == kFLEXObjectExplorerScopeNoInheritanceIndex) {
        self.includeInheritance = NO;
    }
}

#pragma mark - Setter overrides

- (void)setObject:(id)object
{
    _object = object;
    // Use [object class] here rather than object_getClass because we don't want to show the KVO prefix for observed objects.
    self.title = [[object class] description];
    [self updateTableData];
}

- (void)setIncludeInheritance:(BOOL)includeInheritance
{
    if (_includeInheritance != includeInheritance) {
        _includeInheritance = includeInheritance;
        [self updateDisplayedData];
    }
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
    BOOL showDescription = YES;
    
    // Not if it's empty or nil.
    NSString *descripition = [FLEXUtility safeDescriptionForObject:self.object];
    if (showDescription) {
        showDescription = [descripition length] > 0;
    }
    
    // Not if we have filter text that doesn't match the desctiption.
    if (showDescription && [self.filterText length] > 0) {
        showDescription = [descripition rangeOfString:self.filterText options:NSCaseInsensitiveSearch].length > 0;
    }
    
    return showDescription;
}


#pragma mark - Properties

- (void)updateProperties
{
    Class class = [self.object class];
    self.properties = [[self class] propertiesForClass:class];
    self.inheritedProperties = [[self class] inheritedPropertiesForClass:class];
}

+ (NSArray *)propertiesForClass:(Class)class
{
    NSMutableArray *boxedProperties = [NSMutableArray array];
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

+ (NSArray *)inheritedPropertiesForClass:(Class)class
{
    NSMutableArray *inheritedProperties = [NSMutableArray array];
    while ((class = [class superclass])) {
        [inheritedProperties addObjectsFromArray:[self propertiesForClass:class]];
    }
    return inheritedProperties;
}

- (void)updateFilteredProperties
{
    NSArray *candidateProperties = self.properties;
    if (self.includeInheritance) {
        candidateProperties = [candidateProperties arrayByAddingObjectsFromArray:self.inheritedProperties];
    }
    
    NSArray *unsortedFilteredProperties = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray *mutableUnsortedFilteredProperties = [NSMutableArray array];
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
    FLEXPropertyBox *propertyBox = [self.filteredProperties objectAtIndex:index];
    return [FLEXRuntimeUtility prettyNameForProperty:propertyBox.property];
}

- (id)valueForPropertyAtIndex:(NSInteger)index
{
    id value = nil;
    if ([self canHaveInstanceState]) {
        FLEXPropertyBox *propertyBox = [self.filteredProperties objectAtIndex:index];
        value = [FLEXRuntimeUtility valueForProperty:propertyBox.property onObject:self.object];
    }
    return value;
}


#pragma mark - Ivars

- (void)updateIvars
{
    Class class = [self.object class];
    self.ivars = [[self class] ivarsForClass:class];
    self.inheritedIvars = [[self class] inheritedIvarsForClass:class];
}

+ (NSArray *)ivarsForClass:(Class)class
{
    NSMutableArray *boxedIvars = [NSMutableArray array];
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

+ (NSArray *)inheritedIvarsForClass:(Class)class
{
    NSMutableArray *inheritedIvars = [NSMutableArray array];
    while ((class = [class superclass])) {
        [inheritedIvars addObjectsFromArray:[self ivarsForClass:class]];
    }
    return inheritedIvars;
}

- (void)updateFilteredIvars
{
    NSArray *candidateIvars = self.ivars;
    if (self.includeInheritance) {
        candidateIvars = [candidateIvars arrayByAddingObjectsFromArray:self.inheritedIvars];
    }
    
    NSArray *unsortedFilteredIvars = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray *mutableUnsortedFilteredIvars = [NSMutableArray array];
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
    FLEXIvarBox *ivarBox = [self.filteredIvars objectAtIndex:index];
    return [FLEXRuntimeUtility prettyNameForIvar:ivarBox.ivar];
}

- (id)valueForIvarAtIndex:(NSInteger)index
{
    id value = nil;
    if ([self canHaveInstanceState]) {
        FLEXIvarBox *ivarBox = [self.filteredIvars objectAtIndex:index];
        value = [FLEXRuntimeUtility valueForIvar:ivarBox.ivar onObject:self.object];
    }
    return value;
}


#pragma mark - Methods

- (void)updateMethods
{
    Class class = [self.object class];
    self.methods = [[self class] methodsForClass:class];
    self.inheritedMethods = [[self class] inheritedMethodsForClass:class];
}

- (void)updateFilteredMethods
{
    self.filteredMethods = [self filteredMethodsFromMethods:self.methods inheritedMethods:self.inheritedMethods areClassMethods:NO];
}

- (void)updateClassMethods
{
    const char *className = [NSStringFromClass([self.object class]) UTF8String];
    Class metaClass = objc_getMetaClass(className);
    self.classMethods = [[self class] methodsForClass:metaClass];
    self.inheritedClassMethods = [[self class] inheritedMethodsForClass:metaClass];
}

- (void)updateFilteredClassMethods
{
    self.filteredClassMethods = [self filteredMethodsFromMethods:self.classMethods inheritedMethods:self.inheritedClassMethods areClassMethods:YES];
}

+ (NSArray *)methodsForClass:(Class)class
{
    NSMutableArray *boxedMethods = [NSMutableArray array];
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

+ (NSArray *)inheritedMethodsForClass:(Class)class
{
    NSMutableArray *inheritedMethods = [NSMutableArray array];
    while ((class = [class superclass])) {
        [inheritedMethods addObjectsFromArray:[self methodsForClass:class]];
    }
    return inheritedMethods;
}

- (NSArray *)filteredMethodsFromMethods:(NSArray *)methods inheritedMethods:(NSArray *)inheritedMethods areClassMethods:(BOOL)areClassMethods
{
    NSArray *candidateMethods = methods;
    if (self.includeInheritance) {
        candidateMethods = [candidateMethods arrayByAddingObjectsFromArray:inheritedMethods];
    }
    
    NSArray *unsortedFilteredMethods = nil;
    if ([self.filterText length] > 0) {
        NSMutableArray *mutableUnsortedFilteredMethods = [NSMutableArray array];
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
    
    NSArray *sortedFilteredMethods = [unsortedFilteredMethods sortedArrayUsingComparator:^NSComparisonResult(FLEXMethodBox *methodBox1, FLEXMethodBox *methodBox2) {
        NSString *name1 = NSStringFromSelector(method_getName(methodBox1.method));
        NSString *name2 = NSStringFromSelector(method_getName(methodBox2.method));
        return [name1 caseInsensitiveCompare:name2];
    }];
    
    return sortedFilteredMethods;
}

- (NSString *)titleForMethodAtIndex:(NSInteger)index
{
    FLEXMethodBox *methodBox = [self.filteredMethods objectAtIndex:index];
    return [FLEXRuntimeUtility prettyNameForMethod:methodBox.method isClassMethod:NO];
}

- (NSString *)titleForClassMethodAtIndex:(NSInteger)index
{
    FLEXMethodBox *classMethodBox = [self.filteredClassMethods objectAtIndex:index];
    return [FLEXRuntimeUtility prettyNameForMethod:classMethodBox.method isClassMethod:YES];
}


#pragma mark - Superclasses

+ (NSArray *)superclassesForClass:(Class)class
{
    NSMutableArray *superClasses = [NSMutableArray array];
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
        NSMutableArray *filteredSuperclasses = [NSMutableArray array];
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

- (NSArray *)possibleExplorerSections
{
    static NSArray *possibleSections = nil;
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

- (NSArray *)visibleExplorerSections
{
    NSMutableArray *visibleSections = [NSMutableArray array];
    
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
            title = [FLEXUtility safeDescriptionForObject:self.object];
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
            title = NSStringFromClass([self.filteredSuperclasses objectAtIndex:row]);
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
                objc_property_t property = [[self.filteredProperties objectAtIndex:row] property];
                id currentValue = [self valueForPropertyAtIndex:row];
                BOOL canEdit = [FLEXPropertyEditorViewController canEditProperty:property currentValue:currentValue];
                BOOL canExplore = currentValue != nil;
                canDrillIn = canEdit || canExplore;
            }
        }   break;
            
        case FLEXObjectExplorerSectionIvars: {
            if ([self canHaveInstanceState]) {
                Ivar ivar = [[self.filteredIvars objectAtIndex:row] ivar];
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
            NSUInteger totalCount = [self.properties count];
            if (self.includeInheritance) {
                totalCount += [self.inheritedProperties count];
            }
            title = [self sectionTitleWithBaseName:@"Properties" totalCount:totalCount filteredCount:[self.filteredProperties count]];
        } break;
            
        case FLEXObjectExplorerSectionIvars: {
            NSUInteger totalCount = [self.ivars count];
            if (self.includeInheritance) {
                totalCount += [self.inheritedIvars count];
            }
            title = [self sectionTitleWithBaseName:@"Ivars" totalCount:totalCount filteredCount:[self.filteredIvars count]];
        } break;
            
        case FLEXObjectExplorerSectionMethods: {
            NSUInteger totalCount = [self.methods count];
            if (self.includeInheritance) {
                totalCount += [self.inheritedMethods count];
            }
            title = [self sectionTitleWithBaseName:@"Methods" totalCount:totalCount filteredCount:[self.filteredMethods count]];
        } break;
            
        case FLEXObjectExplorerSectionClassMethods: {
            NSUInteger totalCount = [self.classMethods count];
            if (self.includeInheritance) {
                totalCount += [self.inheritedClassMethods count];
            }
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
            objc_property_t property = [[self.filteredProperties objectAtIndex:row] property];
            id currentValue = [self valueForPropertyAtIndex:row];
            if ([FLEXPropertyEditorViewController canEditProperty:property currentValue:currentValue]) {
                viewController = [[FLEXPropertyEditorViewController alloc] initWithTarget:self.object property:property];
            } else if (currentValue) {
                viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
            }
        } break;
            
        case FLEXObjectExplorerSectionIvars: {
            Ivar ivar = [[self.filteredIvars objectAtIndex:row] ivar];
            id currentValue = [self valueForIvarAtIndex:row];
            if ([FLEXIvarEditorViewController canEditIvar:ivar currentValue:currentValue]) {
                viewController = [[FLEXIvarEditorViewController alloc] initWithTarget:self.object ivar:ivar];
            } else if (currentValue) {
                viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
            }
        } break;
            
        case FLEXObjectExplorerSectionMethods: {
            Method method = [[self.filteredMethods objectAtIndex:row] method];
            viewController = [[FLEXMethodCallingViewController alloc] initWithTarget:self.object method:method];
        } break;
            
        case FLEXObjectExplorerSectionClassMethods: {
            Method method = [[self.filteredClassMethods objectAtIndex:row] method];
            viewController = [[FLEXMethodCallingViewController alloc] initWithTarget:[self.object class] method:method];
        } break;
            
        case FLEXObjectExplorerSectionSuperclasses: {
            Class superclass = [self.filteredSuperclasses objectAtIndex:row];
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
    
    BOOL useDescriptionCell = explorerSection == FLEXObjectExplorerSectionDescription;
    NSString *cellIdentifier = useDescriptionCell ? @"descriptionCell" : @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if (useDescriptionCell) {
            cell = [[FLEXDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
            cell.textLabel.font = cellFont;
            cell.detailTextLabel.font = cellFont;
            cell.detailTextLabel.textColor = [UIColor grayColor];
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
        CGFloat preferredHeight = [FLEXDescriptionTableViewCell preferredHeightWithText:text inTableViewWidth:self.tableView.frame.size.width];
        height = MAX(height, preferredHeight);
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
            NSString *rowTitle = [self customSectionTitleForRowCookie:[self.cachedCustomSectionRowCookies objectAtIndex:index]];
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

- (BOOL)canHaveInstanceState
{
    return YES;
}

- (BOOL)canCallInstanceMethods
{
    return YES;
}

@end
