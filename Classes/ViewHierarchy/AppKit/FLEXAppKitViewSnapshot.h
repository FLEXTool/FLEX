//
//  FLEXAppKitViewSnapshot.h
//  FLEX
//
//  An immutable per-node record produced by FLEXAppKitWalker — the macOS analog
//  of FHSViewSnapshot. Captures only the facts read on the main thread; holds no
//  live NSView, so it is safe to serialize off-main.
//
//  SPEC: domain.walker
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class FLEXAppKitFont;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitViewSnapshot : NSObject

/// The real runtime class via object_getClass — the private subclass, not an AX role.
@property (nonatomic, readonly, copy) NSString *className;

/// Raw NSView frame, in its superview's (bottom-left origin) coordinates.
@property (nonatomic, readonly) CGRect frame;

/// Normalized top-left rect, relative to the full window frame (titlebar included).
@property (nonatomic, readonly) CGRect frameTopLeft;

/// The view's own isFlipped — emitted alongside frame so a consumer never infers
/// a top-left origin from `frame` alone.
@property (nonatomic, readonly) BOOL isFlipped;

@property (nonatomic, readonly) BOOL hidden;
@property (nonatomic, readonly) double alpha;
@property (nonatomic, readonly, copy, nullable) NSString *identifier;

/// Decomposed font where the view (or its cell) carries one; nil otherwise.
@property (nonatomic, readonly, nullable) FLEXAppKitFont *font;

@property (nonatomic, readonly, copy) NSArray<FLEXAppKitViewSnapshot *> *children;

- (instancetype)initWithClassName:(NSString *)className
                            frame:(CGRect)frame
                     frameTopLeft:(CGRect)frameTopLeft
                        isFlipped:(BOOL)isFlipped
                           hidden:(BOOL)hidden
                            alpha:(double)alpha
                       identifier:(nullable NSString *)identifier
                             font:(nullable FLEXAppKitFont *)font
                         children:(NSArray<FLEXAppKitViewSnapshot *> *)children NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
