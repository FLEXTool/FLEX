//
//  FLEXMetadataSection.m
//  FLEX
//
//  Created by Tanner Bennett on 9/19/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXMetadataSection.h"
#import "FLEXTableView.h"
#import "FLEXTableViewCell.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXIvar.h"
#import "NSArray+Functional.h"
#import "FLEXRuntime+UIKitHelpers.h"

@interface FLEXMetadataSection ()
@property (nonatomic, readonly) FLEXObjectExplorer *explorer;
/// Filtered
@property (nonatomic, copy) NSArray<id<FLEXRuntimeMetadata>> *metadata;
/// Unfiltered
@property (nonatomic, copy) NSArray<id<FLEXRuntimeMetadata>> *allMetadata;
@end

@implementation FLEXMetadataSection

#pragma mark - Initialization

+ (instancetype)explorer:(FLEXObjectExplorer *)explorer kind:(FLEXMetadataKind)metadataKind {
    return [[self alloc] initWithExplorer:explorer kind:metadataKind];
}

- (id)initWithExplorer:(FLEXObjectExplorer *)explorer kind:(FLEXMetadataKind)metadataKind {
    self = [super init];
    if (self) {
        _explorer = explorer;
        _metadataKind = metadataKind;

        [self reloadData];
    }

    return self;
}

#pragma mark - Private

- (NSString *)titleWithBaseName:(NSString *)baseName {
    unsigned long totalCount = self.allMetadata.count;
    unsigned long filteredCount = self.metadata.count;

    if (totalCount == filteredCount) {
        return [baseName stringByAppendingFormat:@" (%lu)", totalCount];
    } else {
        return [baseName stringByAppendingFormat:@" (%lu of %lu)", filteredCount, totalCount];
    }
}

- (__kindof UIViewController *)detailScreenForMetadata:(id)metadata {
    id target = self.explorer.object;

    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindIvars: {
            // This works for both properties and ivars, we just
            // cast so the compiler knows what return type to expect since
            // this method has the same name as -[NSValue getValue:] (void *)
            id currentValue = [(FLEXIvar *)metadata getPotentiallyUnboxedValue:target];
            return [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
        }
        case FLEXMetadataKindClassMethods:
            // Make sure the target is a class
            // for class methods, then fall through
            if (self.explorer.objectIsInstance && ![metadata isInstanceMethod]) {
                target = [target class];
            }
        case FLEXMetadataKindMethods: {
            return [FLEXMethodCallingViewController target:target method:metadata];
        }
    }
}

// Only for properties or ivars
- (id)valueForRow:(NSInteger)row {
    id metadata = self.metadata[row];

    // We use -[FLEXObjectExplorer valueFor...:] instead of getValue: below
    // because we want to "preview" what object is being stored if this is
    // a void * or something and we're given an NSValue back from getValue:
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
            return [self.explorer valueForProperty:metadata];
        case FLEXMetadataKindIvars:
            return [self.explorer valueForIvar:metadata];

        // Methods: nil
        case FLEXMetadataKindMethods:
        case FLEXMetadataKindClassMethods:
            return nil;
    }
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return [self.metadata[row] suggestedAccessoryTypeWithTarget:self.explorer.object];
}

#pragma mark - Public

- (void)setExcludedMetadata:(NSSet<NSString *> *)excludedMetadata {
    _excludedMetadata = excludedMetadata;
    [self reloadData];
}

#pragma mark - Overrides

- (NSString *)titleForRow:(NSInteger)row {
    return [self.metadata[row] description];
}

- (NSString *)subtitleForRow:(NSInteger)row {
    id metadata = self.metadata[row];

    // We use -[FLEXObjectExplorer valueFor...:] instead of getValue: below
    // because we want to "preview" what object is being stored if this is
    // a void * or something and we're given an NSValue back from getValue:
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindIvars:
            #warning TODO: fix this logic for class properties
            if (!self.explorer.objectIsInstance) {
                if (self.metadataKind == FLEXMetadataKindProperties) {
                    if (![metadata isClassProperty]) {
                        return nil;
                    }
                } else {
                    return nil;
                }
            }
            return [FLEXRuntimeUtility summaryForObject:[self valueForRow:row]];
        case FLEXMetadataKindMethods:
        case FLEXMetadataKindClassMethods:
            return [metadata selectorString];

        default:
            return nil;
    }
}

- (NSString *)title {
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
            return [self titleWithBaseName:@"Properties"];
        case FLEXMetadataKindIvars:
            return [self titleWithBaseName:@"Ivars"];
        case FLEXMetadataKindMethods:
            return [self titleWithBaseName:@"Methods"];
        case FLEXMetadataKindClassMethods:
            return [self titleWithBaseName:@"Class methods"];

        default: return nil;
    }
}

- (NSInteger)numberOfRows {
    return self.metadata.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;

    if (!self.filterText.length) {
        self.metadata = self.allMetadata;
    } else {
        self.metadata = [self.allMetadata flex_filtered:^BOOL(FLEXProperty *obj, NSUInteger idx) {
            return [obj.description localizedCaseInsensitiveContainsString:self.filterText];
        }];
    }
}

- (void)reloadData {
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
            self.allMetadata = self.explorer.properties;
            break;
        case FLEXMetadataKindIvars:
            self.allMetadata = self.explorer.ivars;
            break;
        case FLEXMetadataKindMethods:
            self.allMetadata = self.explorer.methods;
            break;
        case FLEXMetadataKindClassMethods:
            self.allMetadata = self.explorer.classMethods;
            break;
    }

    // Remove excluded metadata
    if (self.excludedMetadata.count) {
        id filterBlock = ^BOOL(id obj, NSUInteger idx) {
            return ![self.excludedMetadata containsObject:[obj name]];
        };

        // Filter exclusions and sort
        self.allMetadata = [[self.allMetadata flex_filtered:filterBlock]
            sortedArrayUsingSelector:@selector(compare:)
        ];
    }

    // Re-filter data
    self.filterText = self.filterText;
}

- (BOOL)canSelectRow:(NSInteger)row {
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
        case FLEXMetadataKindIvars:
            if (![self valueForRow:row]) {
                return NO;
            }
        case FLEXMetadataKindMethods:
            return self.explorer.objectIsInstance;
        case FLEXMetadataKindClassMethods:
            return YES;

        default: return NO;
    }
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDetailCell;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [self detailScreenForMetadata:self.metadata[row]];
}

- (void (^)(UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return ^(UIViewController *host) {
        [host.navigationController pushViewController:[self editorForRow:row] animated:YES];
    };
}

- (UIViewController *)editorForRow:(NSInteger)row {
    NSAssert(
        self.metadataKind == FLEXMetadataKindIvars ||
        self.metadataKind == FLEXMetadataKindProperties, // ||,
//        self.metadataKind == FLEXMetadataKindClassProperties,
        @"Only ivars or properties can be edited"
    );

    id metadata = self.metadata[row];

    // Nil editor means unsupported ivar or property type, or nil value
    if (self.metadataKind == FLEXMetadataKindProperties) {
        return [FLEXFieldEditorViewController target:self.explorer.object property:metadata];
    } else if (self.metadataKind == FLEXMetadataKindIvars) {
        return [FLEXFieldEditorViewController target:self.explorer.object ivar:metadata];
    }

    // TODO: support class properties
    @throw NSInternalInconsistencyException;
    return nil;
}

- (void)configureCell:(__kindof FLEXTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = [self accessoryTypeForRow:row];
}

@end
