//
//  FLEXAppKitJSON.h
//  FLEX
//
//  Projects the walker's snapshot model into JSON-serializable Foundation
//  dictionaries (floats at fixed precision, nils as NSNull) so the output is
//  deterministic and round-trips through NSJSONSerialization. The final string
//  serialization is left to the consumer — this returns Foundation collections.
//

#import <Foundation/Foundation.h>

@class FLEXAppKitViewSnapshot;
@class FLEXAppKitWindowSnapshot;
@class FLEXConstraintNode;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitJSON : NSObject

+ (NSArray<NSDictionary *> *)dictionariesForWindows:(NSArray<FLEXAppKitWindowSnapshot *> *)windows;
+ (NSDictionary *)dictionaryForWindow:(FLEXAppKitWindowSnapshot *)window;
+ (NSDictionary *)dictionaryForView:(FLEXAppKitViewSnapshot *)view;
+ (NSDictionary *)dictionaryForConstraintNode:(FLEXConstraintNode *)node;

@end

NS_ASSUME_NONNULL_END
