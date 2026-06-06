//
//  FLEXAppKitJSON.h
//  FLEX
//
//  Projects the walker's snapshot model into JSON-serializable Foundation
//  dictionaries shaped per the flexscope node schema (domain.node). Floats are
//  emitted at fixed precision and nils as NSNull so the output is deterministic
//  and round-trips through NSJSONSerialization. The final string serialization is
//  the consumer's job (ARCHITECTURE §5.3: the FLEX side returns Foundation
//  collections; the server/CLI serializes).
//
//  SPEC: domain.walker
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
