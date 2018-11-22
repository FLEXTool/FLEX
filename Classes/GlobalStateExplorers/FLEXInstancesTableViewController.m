//
//  FLEXInstancesTableViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXInstancesTableViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import <malloc/malloc.h>


@interface FLEXInstancesTableViewController ()

/// Array of [[section], [section], ...]
/// where [section] is [["row title", instance], ["row title", instance], ...]
@property (nonatomic) NSArray<FLEXObjectRef *> *instances;
@property (nonatomic) NSArray<NSArray<FLEXObjectRef*>*> *sections;
@property (nonatomic) NSArray<NSString *> *sectionTitles;
@property (nonatomic) NSArray<NSPredicate *> *predicates;
@property (nonatomic, readonly) NSInteger maxSections;

@end

@implementation FLEXInstancesTableViewController

- (id)initWithReferences:(NSArray<FLEXObjectRef *> *)references {
    return [self initWithReferences:references predicates:nil sectionTitles:nil];
}

- (id)initWithReferences:(NSArray<FLEXObjectRef *> *)references
              predicates:(NSArray<NSPredicate *> *)predicates
           sectionTitles:(NSArray<NSString *> *)sectionTitles {
    NSParameterAssert(predicates.count == sectionTitles.count);

    self = [super init];
    if (self) {
        self.instances = references;
        self.predicates = predicates;
        self.sectionTitles = sectionTitles;

        if (predicates.count) {
            [self buildSections];
        } else {
            self.sections = @[references];
        }
    }

    return self;
}

+ (instancetype)instancesTableViewControllerForClassName:(NSString *)className
{
    const char *classNameCString = [className UTF8String];
    NSMutableArray *instances = [NSMutableArray array];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
            // Note: objects of certain classes crash when retain is called. It is up to the user to avoid tapping into instance lists for these classes.
            // Ex. OS_dispatch_queue_specific_queue
            // In the future, we could provide some kind of warning for classes that are known to be problematic.
            if (malloc_size((__bridge const void *)(object)) > 0) {
                [instances addObject:object];
            }
        }
    }];
    NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances];
    FLEXInstancesTableViewController *viewController = [[self alloc] initWithReferences:references];
    viewController.title = [NSString stringWithFormat:@"%@ (%lu)", className, (unsigned long)[instances count]];
    return viewController;
}

+ (instancetype)instancesTableViewControllerForInstancesReferencingObject:(id)object
{
    NSMutableArray<FLEXObjectRef *> *instances = [NSMutableArray array];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id tryObject, __unsafe_unretained Class actualClass) {
        // Skip Swift objects
        if ([actualClass isKindOfClass:NSClassFromString(@"SwiftObject")]) {
            return;
        }
        
        // Get all the ivars on the object. Start with the class and and travel up the inheritance chain.
        // Once we find a match, record it and move on to the next object. There's no reason to find multiple matches within the same object.
        Class tryClass = actualClass;
        while (tryClass) {
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(tryClass, &ivarCount);
            for (unsigned int ivarIndex = 0; ivarIndex < ivarCount; ivarIndex++) {
                Ivar ivar = ivars[ivarIndex];
                const char *typeEncoding = ivar_getTypeEncoding(ivar);
                if (typeEncoding[0] == @encode(id)[0] || typeEncoding[0] == @encode(Class)[0]) {
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    uintptr_t *fieldPointer = (__bridge void *)tryObject + offset;
                    if (*fieldPointer == (uintptr_t)(__bridge void *)object) {
                        [instances addObject:[FLEXObjectRef referencing:tryObject ivar:@(ivar_getName(ivar))]];
                        return;
                    }
                }
            }
            tryClass = class_getSuperclass(tryClass);
        }
    }];

    NSArray<NSPredicate *> *predicates = [self defaultPredicates];
    NSArray<NSString *> *sectionTitles = [self defaultSectionTitles];
    FLEXInstancesTableViewController *viewController = [[self alloc] initWithReferences:instances
                                                                             predicates:predicates
                                                                          sectionTitles:sectionTitles];
    viewController.title = [NSString stringWithFormat:@"Referencing %@ %p", NSStringFromClass(object_getClass(object)), object];
    return viewController;
}

+ (NSPredicate *)defaultPredicateForSection:(NSInteger)section
{
    // These are the types of references that we typically don't care about.
    // We want this list of "object-ivar pairs" split into two sections.
    BOOL(^isObserver)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
        NSString *row = ref.reference;
        return [row isEqualToString:@"__NSObserver object"] ||
               [row isEqualToString:@"_CFXNotificationObjcObserverRegistration _object"];
    };

    /// These are common AutoLayout related references we also rarely care about.
    BOOL(^isConstraintRelated)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
        static NSSet *ignored = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ignored = [NSSet setWithArray:@[
                @"NSLayoutConstraint _container",
                @"NSContentSizeLayoutConstraint _container",
                @"NSAutoresizingMaskLayoutConstraint _container",
                @"MASViewConstraint _installedView",
                @"MASLayoutConstraint _container",
                @"MASViewAttribute _view"
            ]];
        });

        NSString *row = ref.reference;
        return ([row hasPrefix:@"NSLayout"] && [row hasSuffix:@" _referenceItem"]) ||
               ([row hasPrefix:@"NSIS"] && [row hasSuffix:@" _delegate"])  ||
               ([row hasPrefix:@"_NSAutoresizingMask"] && [row hasSuffix:@" _referenceItem"]) ||
               [ignored containsObject:row];
    };

    BOOL(^isEssential)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
        return !(isObserver(ref, bindings) || isConstraintRelated(ref, bindings));
    };

    switch (section) {
        case 0: return [NSPredicate predicateWithBlock:isEssential];
        case 1: return [NSPredicate predicateWithBlock:isConstraintRelated];
        case 2: return [NSPredicate predicateWithBlock:isObserver];

        default: return nil;
    }
}

+ (NSArray<NSPredicate *> *)defaultPredicates {
    return @[[self defaultPredicateForSection:0],
             [self defaultPredicateForSection:1],
             [self defaultPredicateForSection:2]];
}

+ (NSArray<NSString *> *)defaultSectionTitles {
    return @[@"", @"AutoLayout", @"Trivial"];
}

- (void)buildSections
{
    NSInteger maxSections = self.maxSections;
    NSMutableArray *sections = [NSMutableArray array];
    for (NSInteger i = 0; i < maxSections; i++) {
        NSPredicate *predicate = self.predicates[i];
        [sections addObject:[self.instances filteredArrayUsingPredicate:predicate]];
    }

    self.sections = sections;
}

- (NSInteger)maxSections {
    return self.predicates.count ?: 1;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.maxSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        cell.textLabel.font = cellFont;
        cell.detailTextLabel.font = cellFont;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    FLEXObjectRef *row = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = row.reference;
    cell.detailTextLabel.text = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:row.object];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.sectionTitles.count) {
        // Return nil instead of empty strings
        NSString *title = self.sectionTitles[section];
        if (title.length) {
            return title;
        }
    }

    return nil;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id instance = self.instances[indexPath.row].object;
    FLEXObjectExplorerViewController *drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:instance];
    [self.navigationController pushViewController:drillInViewController animated:YES];
}

@end
