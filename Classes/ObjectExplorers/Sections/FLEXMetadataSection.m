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
    return [self.metadata[row] previewWithTarget:self.explorer.object];
}

- (NSString *)title {
    switch (self.metadataKind) {
        case FLEXMetadataKindProperties:
            return [self titleWithBaseName:@"Properties"];
        case FLEXMetadataKindClassProperties:
            return [self titleWithBaseName:@"Class Properties"];
        case FLEXMetadataKindIvars:
            return [self titleWithBaseName:@"Ivars"];
        case FLEXMetadataKindMethods:
            return [self titleWithBaseName:@"Methods"];
        case FLEXMetadataKindClassMethods:
            return [self titleWithBaseName:@"Class Methods"];
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
        case FLEXMetadataKindClassProperties:
            self.allMetadata = self.explorer.classProperties;
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
    UITableViewCellAccessoryType accessory = [self accessoryTypeForRow:row];
    return accessory == UITableViewCellAccessoryDisclosureIndicator ||
        accessory == UITableViewCellAccessoryDetailDisclosureButton;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDetailCell;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [self.metadata[row] viewerWithTarget:self.explorer.object];
}

- (void (^)(UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return ^(UIViewController *host) {
        [host.navigationController pushViewController:[self editorForRow:row] animated:YES];
    };
}

- (UIViewController *)editorForRow:(NSInteger)row {
    return [self.metadata[row] editorWithTarget:self.explorer.object];
}

- (void)configureCell:(__kindof FLEXTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = [self accessoryTypeForRow:row];
}

@end
