//
//  FLEXMetadataExtras.m
//  FLEX
//
//  Created by Tanner Bennett on 4/26/22.
//

#import "FLEXMetadataExtras.h"

NSString * const FLEXAuxiliarynfoKeyFieldLabels = @"FLEXAuxiliarynfoKeyFieldLabels";

@implementation FLEXMethodBase (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end

@implementation FLEXProperty (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end

@implementation FLEXIvar (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end
