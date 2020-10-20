//
//  FLEXObjectListViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXObjectListViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXMutableListSection.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "NSString+FLEX.h"
#import "NSObject+FLEX_Reflection.h"
#import "FLEXTableViewCell.h"
#import <malloc/malloc.h>


@interface FLEXObjectListViewController ()
@property (nonatomic, copy) NSArray<FLEXMutableListSection *> *sections;
@property (nonatomic, copy) NSArray<FLEXMutableListSection *> *allSections;

@property (nonatomic, readonly) NSArray<FLEXObjectRef *> *references;
@property (nonatomic, readonly) NSArray<NSPredicate *> *predicates;
@property (nonatomic, readonly) NSArray<NSString *> *sectionTitles;

@end

@implementation FLEXObjectListViewController
@dynamic sections, allSections;

#pragma mark - Reference Grouping

+ (NSPredicate *)defaultPredicateForSection:(NSInteger)section {
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


#pragma mark - Initialization

- (id)initWithReferences:(NSArray<FLEXObjectRef *> *)references {
    return [self initWithReferences:references predicates:nil sectionTitles:nil];
}

- (id)initWithReferences:(NSArray<FLEXObjectRef *> *)references
              predicates:(NSArray<NSPredicate *> *)predicates
           sectionTitles:(NSArray<NSString *> *)sectionTitles {
    NSParameterAssert(predicates.count == sectionTitles.count);

    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _references = references;
        _predicates = predicates;
        _sectionTitles = sectionTitles;
    }

    return self;
}

+ (UIViewController *)instancesOfClassWithName:(NSString *)className {
    const char *classNameCString = className.UTF8String;
    NSMutableArray *instances = [NSMutableArray new];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
            // Note: objects of certain classes crash when retain is called.
            // It is up to the user to avoid tapping into instance lists for these classes.
            // Ex. OS_dispatch_queue_specific_queue
            // In the future, we could provide some kind of warning for classes that are known to be problematic.
            if (malloc_size((__bridge const void *)(object)) > 0) {
                [instances addObject:object];
            }
        }
    }];

    NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances];
    if (references.count == 1) {
        return [FLEXObjectExplorerFactory
                explorerViewControllerForObject:references.firstObject.object
        ];
    }

    FLEXObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"%@ (%lu)", className, (unsigned long)instances.count];
    return controller;
}

+ (instancetype)subclassesOfClassWithName:(NSString *)className {
    NSArray<Class> *classes = FLEXGetAllSubclasses(NSClassFromString(className), NO);
    NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingClasses:classes];
    FLEXObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"Subclasses of %@ (%lu)",
        className, (unsigned long)classes.count
    ];

    return controller;
}

+ (instancetype)objectsWithReferencesToObject:(id)object {
    static Class SwiftObjectClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwiftObjectClass = NSClassFromString(@"SwiftObject");
        if (!SwiftObjectClass) {
            SwiftObjectClass = NSClassFromString(@"Swift._SwiftObject");
        }
    });

    NSMutableArray<FLEXObjectRef *> *instances = [NSMutableArray new];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id tryObject, __unsafe_unretained Class actualClass) {
        // Get all the ivars on the object. Start with the class and and travel up the inheritance chain.
        // Once we find a match, record it and move on to the next object. There's no reason to find multiple matches within the same object.
        Class tryClass = actualClass;
        while (tryClass) {
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(tryClass, &ivarCount);

            for (unsigned int ivarIndex = 0; ivarIndex < ivarCount; ivarIndex++) {
                Ivar ivar = ivars[ivarIndex];
                NSString *typeEncoding = @(ivar_getTypeEncoding(ivar) ?: "");

                if (typeEncoding.flex_typeIsObjectOrClass) {
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    uintptr_t *fieldPointer = (__bridge void *)tryObject + offset;

                    if (*fieldPointer == (uintptr_t)(__bridge void *)object) {
                        NSString *ivarName = @(ivar_getName(ivar) ?: "???");
                        [instances addObject:[FLEXObjectRef referencing:tryObject ivar:ivarName]];
                        return;
                    }
                }
            }

            tryClass = class_getSuperclass(tryClass);
        }
    }];

    NSArray<NSPredicate *> *predicates = [self defaultPredicates];
    NSArray<NSString *> *sectionTitles = [self defaultSectionTitles];
    FLEXObjectListViewController *viewController = [[self alloc]
        initWithReferences:instances
        predicates:predicates
        sectionTitles:sectionTitles
    ];
    viewController.title = [NSString stringWithFormat:@"Referencing %@ %p",
        NSStringFromClass(object_getClass(object)), object
    ];
    return viewController;
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
}

- (NSArray<FLEXMutableListSection *> *)makeSections {
    if (self.predicates.count) {
        return [self buildSections:self.sectionTitles predicates:self.predicates];
    } else {
        return @[[self makeSection:self.references title:nil]];
    }
}


#pragma mark - Private

- (NSArray *)buildSections:(NSArray<NSString *> *)titles predicates:(NSArray<NSPredicate *> *)predicates {
    NSParameterAssert(titles.count == predicates.count);
    NSParameterAssert(titles); NSParameterAssert(predicates);

    return [NSArray flex_forEachUpTo:titles.count map:^id(NSUInteger i) {
        NSArray *rows = [self.references filteredArrayUsingPredicate:predicates[i]];
        return [self makeSection:rows title:titles[i]];
    }];
}

- (FLEXMutableListSection *)makeSection:(NSArray *)rows title:(NSString *)title {
    FLEXMutableListSection *section = [FLEXMutableListSection list:rows
        cellConfiguration:^(FLEXTableViewCell *cell, FLEXObjectRef *ref, NSInteger row) {
            cell.textLabel.text = ref.reference;
            cell.detailTextLabel.text = ref.summary;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } filterMatcher:^BOOL(NSString *filterText, FLEXObjectRef *ref) {
            if (ref.summary && [ref.summary localizedCaseInsensitiveContainsString:filterText]) {
                return YES;
            }

            return [ref.reference localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    __weak __typeof(self) weakSelf = self;
    section.selectionHandler = ^(__kindof UIViewController *host, FLEXObjectRef *ref) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.navigationController pushViewController:[
                FLEXObjectExplorerFactory explorerViewControllerForObject:ref.object
            ] animated:YES];
        }
    };

    section.customTitle = title;
    return section;
}

@end
