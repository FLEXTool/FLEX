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


typedef NS_ENUM(NSUInteger, FLEXObjectReferenceSection) {
    FLEXObjectReferenceSectionMain,
    FLEXObjectReferenceSectionAutoLayout,
    FLEXObjectReferenceSectionKVO,
    FLEXObjectReferenceSectionFLEX,
    
    FLEXObjectReferenceSectionCount
};

@interface FLEXObjectListViewController ()

@property (nonatomic, readonly, class) NSArray<NSPredicate *> *defaultPredicates;
@property (nonatomic, readonly, class) NSArray<NSString *> *defaultSectionTitles;


@property (nonatomic, copy) NSArray<FLEXMutableListSection *> *sections;
@property (nonatomic, copy) NSArray<FLEXMutableListSection *> *allSections;

@property (nonatomic, readonly, nullable) NSArray<FLEXObjectRef *> *references;
@property (nonatomic, readonly) NSArray<NSPredicate *> *predicates;
@property (nonatomic, readonly) NSArray<NSString *> *sectionTitles;

@end

@implementation FLEXObjectListViewController
@dynamic sections, allSections;

#pragma mark - Reference Grouping

+ (NSPredicate *)defaultPredicateForSection:(NSInteger)section {
    // These are the types of references that we typically don't care about.
    // We want this list of "object-ivar pairs" split into two sections.
    BOOL(^isKVORelated)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
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
    
    /// These are FLEX classes and usually you aren't looking for FLEX references inside FLEX itself
    BOOL(^isFLEXClass)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
        return [ref.reference hasPrefix:@"FLEX"];
    };

    BOOL(^isEssential)(FLEXObjectRef *, NSDictionary *) = ^BOOL(FLEXObjectRef *ref, NSDictionary *bindings) {
        return !(
            isKVORelated(ref, bindings) ||
            isConstraintRelated(ref, bindings) ||
            isFLEXClass(ref, bindings)
        );
    };

    switch (section) {
        case FLEXObjectReferenceSectionMain:
            return [NSPredicate predicateWithBlock:isEssential];
        case FLEXObjectReferenceSectionAutoLayout:
            return [NSPredicate predicateWithBlock:isConstraintRelated];
        case FLEXObjectReferenceSectionKVO:
            return [NSPredicate predicateWithBlock:isKVORelated];
        case FLEXObjectReferenceSectionFLEX:
            return [NSPredicate predicateWithBlock:isFLEXClass];

        default: return nil;
    }
}

+ (NSArray<NSPredicate *> *)defaultPredicates {
    return [NSArray flex_forEachUpTo:FLEXObjectReferenceSectionCount map:^id(NSUInteger i) {
        return [self defaultPredicateForSection:i];
    }];
}

+ (NSArray<NSString *> *)defaultSectionTitles {
    return @[
        @"", @"AutoLayout", @"Key-Value Observing", @"FLEX"
    ];
}


#pragma mark - Initialization

- (id)initWithReferences:(nullable NSArray<FLEXObjectRef *> *)references {
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

+ (UIViewController *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain {
    NSArray<FLEXObjectRef *> *references = [FLEXHeapEnumerator
        instancesOfClassWithName:className retained:retain
    ];
    
    if (references.count == 1) {
        return [FLEXObjectExplorerFactory
            explorerViewControllerForObject:references.firstObject.object
        ];
    }

    FLEXObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"%@ (%@)", className, @(references.count)];
    return controller;
}

+ (instancetype)subclassesOfClassWithName:(NSString *)className {
    NSArray<FLEXObjectRef *> *references = [FLEXHeapEnumerator subclassesOfClassWithName:className];
    FLEXObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"Subclasses of %@ (%@)",
        className, @(references.count)
    ];

    return controller;
}

+ (instancetype)objectsWithReferencesToObject:(id)object retained:(BOOL)retain {
    NSArray<FLEXObjectRef *> *instances = [FLEXHeapEnumerator
        objectsWithReferencesToObject:object retained:retain
    ];

    FLEXObjectListViewController *viewController = [[self alloc]
        initWithReferences:instances
        predicates:self.defaultPredicates
        sectionTitles:self.defaultSectionTitles
    ];
    viewController.title = [NSString stringWithFormat:@"Referencing %@ %p",
        [FLEXRuntimeUtility safeClassNameForObject:object], object
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

    section.selectionHandler = ^(UIViewController *host, FLEXObjectRef *ref) {
        [host.navigationController pushViewController:[
            FLEXObjectExplorerFactory explorerViewControllerForObject:ref.object
        ] animated:YES];
    };

    section.customTitle = title;
    return section;
}

@end
