//
//  FLEXMetadataSection.h
//  FLEX
//
//  Created by Tanner Bennett on 9/19/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewSection.h"
#import "FLEXObjectExplorer.h"

typedef NS_ENUM(NSUInteger, FLEXMetadataKind) {
    FLEXMetadataKindProperties = 1,
    FLEXMetadataKindClassProperties,
    FLEXMetadataKindIvars,
    FLEXMetadataKindMethods,
    FLEXMetadataKindClassMethods,
    FLEXMetadataKindClassHierarchy,
    FLEXMetadataKindProtocols,
    FLEXMetadataKindOther
};

/// This section is used for displaying ObjC runtime metadata
/// about a class or object, such as listing methods, properties, etc.
@interface FLEXMetadataSection : FLEXTableViewSection

+ (instancetype)explorer:(FLEXObjectExplorer *)explorer kind:(FLEXMetadataKind)metadataKind;

@property (nonatomic, readonly) FLEXMetadataKind metadataKind;

/// The names of metadata to exclude. Useful if you wish to group specific
/// properties or methods together in their own section outside of this one.
///
/// Setting this property calls \c reloadData on this section.
@property (nonatomic) NSSet<NSString *> *excludedMetadata;

@end
