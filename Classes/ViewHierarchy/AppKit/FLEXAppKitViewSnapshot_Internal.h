//
//  FLEXAppKitViewSnapshot_Internal.h
//  FLEX
//
//  Internal readwrite surface so FLEXAppKitWalker can populate an otherwise
//  immutable snapshot during construction. Not part of the public contract.
//
//  SPEC: domain.walker
//

#import "FLEXAppKitViewSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitViewSnapshot ()
@property (nonatomic, copy) NSString *className;
@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect frameTopLeft;
@property (nonatomic) BOOL isFlipped;
@property (nonatomic) BOOL hidden;
@property (nonatomic) double alpha;
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic) BOOL swiftUIBoundary;
@property (nonatomic, copy, nullable) NSString *material;
@property (nonatomic, copy, nullable) NSString *blendingMode;
@property (nonatomic, nullable) FLEXAppKitFont *font;
@property (nonatomic, nullable) FLEXAppKitLayer *layer;
@property (nonatomic, copy) NSArray<FLEXAppKitViewSnapshot *> *children;
@end

NS_ASSUME_NONNULL_END
