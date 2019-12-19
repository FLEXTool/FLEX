//
//  FLEXCollectionContentSection.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXCollectionContentSection.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXTableView.h"
#import "FLEXObjectExplorerFactory.h"

typedef NS_ENUM(NSUInteger, FLEXCollectionType) {
    FLEXUnsupportedCollection,
    FLEXOrderedCollection,
    FLEXUnorderedCollection,
    FLEXKeyedCollection
};

@interface FLEXCollectionContentSection ()
@property (nonatomic) id<FLEXCollection> cachedCollection;
@property (nonatomic, readonly) id<FLEXCollection> collection;
@property (nonatomic, readonly) FLEXCollectionContentFuture collectionFuture;
@property (nonatomic, readonly) FLEXCollectionType collectionType;
@end

@implementation FLEXCollectionContentSection

#pragma mark Initialization

+ (instancetype)forObject:(id)object {
    return [self forCollection:object];
}

+ (id)forCollection:(id<FLEXCollection>)collection {
    FLEXCollectionContentSection *section = [self new];
    section->_collectionType = [self typeForCollection:collection];
    section->_collection = collection;
    section.cachedCollection = collection.copy;
    return section;
}

+ (id)forReusableFuture:(FLEXCollectionContentFuture)collectionFuture {
    FLEXCollectionContentSection *section = [self new];
    section->_collectionFuture = collectionFuture;
    section.cachedCollection = collectionFuture(section);
    section->_collectionType = [self typeForCollection:section.cachedCollection];
    return section;
}

#pragma mark - Misc

+ (FLEXCollectionType)typeForCollection:(id<FLEXCollection>)collection {
    // Order matters here, as NSDictionary is keyed but it responds to allObjects
    if ([collection respondsToSelector:@selector(objectAtIndexedSubscript:)]) {
        return FLEXOrderedCollection;
    }
    if ([collection respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        return FLEXKeyedCollection;
    }
    if ([collection respondsToSelector:@selector(allObjects)]) {
        return FLEXUnorderedCollection;
    }

    [NSException raise:NSInvalidArgumentException
                format:@"Given collection does not properly conform to FLEXCollection"];
    return FLEXUnsupportedCollection;
}

/// Row titles
/// - Ordered: the index
/// - Unordered: the object
/// - Keyed: the key
- (NSString *)titleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
            return @(row).stringValue;
        case FLEXUnorderedCollection:
            return [self describe:[self objectForRow:row]];
        case FLEXKeyedCollection:
            return [self describe:self.collection.allKeys[row]];

        case FLEXUnsupportedCollection:
            return nil;
    }
}

/// Row subtitles
/// - Ordered: the object
/// - Unordered: nothing
/// - Keyed: the value
- (NSString *)subtitleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
        case FLEXKeyedCollection:
            return [self describe:[self objectForRow:row]];
        case FLEXUnorderedCollection:
            return nil;

        case FLEXUnsupportedCollection:
            return nil;
    }
}

- (NSString *)describe:(id)object {
    return [FLEXRuntimeUtility summaryForObject:object];
}

- (id)objectForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
            return self.collection[row];
        case FLEXUnorderedCollection:
            return self.collection.allObjects[row];
        case FLEXKeyedCollection:
            return self.collection[self.collection.allKeys[row]];

        case FLEXUnsupportedCollection:
            return nil;
    }
}

#pragma mark - Overrides

- (NSString *)title {
    return FLEXPluralString(self.cachedCollection.count, @"Entries", @"Entry");
}

- (NSInteger)numberOfRows {
    return self.cachedCollection.count;
}

- (void)reloadData {
    if (self.collectionFuture) {
        self.cachedCollection = self.collectionFuture(self);
    } else {
        self.cachedCollection = self.collection.copy;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:[self objectForRow:row]];
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    // Default for unordered, subtitle for others
    return self.collectionType == FLEXUnorderedCollection ? kFLEXDefaultCell : kFLEXDetailCell;
}

- (void)configureCell:(__kindof FLEXTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end
