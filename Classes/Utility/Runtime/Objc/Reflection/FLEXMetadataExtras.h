//
//  FLEXMetadataExtras.h
//  FLEX
//
//  Created by Tanner Bennett on 4/26/22.
//

#import <Foundation/Foundation.h>
#import "FLEXMethodBase.h"
#import "FLEXProperty.h"
#import "FLEXIvar.h"

NS_ASSUME_NONNULL_BEGIN

/// A dictionary mapping type encoding strings to an array of field titles
extern NSString * const FLEXAuxiliarynfoKeyFieldLabels;

@protocol FLEXMetadataAuxiliaryInfo <NSObject>

/// Used to supply arbitrary additional data that need not be exposed by their own properties
- (nullable id)auxiliaryInfoForKey:(NSString *)key;

@end

@interface FLEXMethodBase (Auxiliary) <FLEXMetadataAuxiliaryInfo> @end
@interface FLEXProperty (Auxiliary) <FLEXMetadataAuxiliaryInfo> @end
@interface FLEXIvar (Auxiliary) <FLEXMetadataAuxiliaryInfo> @end


NS_ASSUME_NONNULL_END
