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
@class FLEXAppKitLayer;

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

/// Displayed string where the view is text-bearing (NSControl/NSText); nil otherwise.
/// What the selector grammar's `text` predicate matches against.
@property (nonatomic, readonly, copy, nullable) NSString *text;

/// The AX role (NSAccessibility), to cross-reference the AX dump.
@property (nonatomic, readonly, copy, nullable) NSString *axRole;

/// Runtime class hierarchy from the view's class up to NSView (exclusive of the
/// view's own class, which is `className`). An --include field.
@property (nonatomic, readonly, copy) NSArray<NSString *> *superclasses;

/// Number of NSLayoutConstraints touching this view (both directions). The full
/// list is produced separately; this is the default-projection count.
@property (nonatomic, readonly) NSInteger constraintsCount;

/// Number of subviews, always reported even when `children` is truncated.
@property (nonatomic, readonly) NSInteger childCount;

/// True when subviews were omitted because the depth bound was reached. A leaf is
/// never truncated; `childCount` still reports the real subview count.
@property (nonatomic, readonly) BOOL truncated;

/// True at an NSHostingView (SwiftUI's AppKit host): below it the class names are
/// SwiftUI internals, but the layer-backed scaffold is still real and traversed.
@property (nonatomic, readonly) BOOL swiftUIBoundary;

/// NSVisualEffectView.material / blendingMode (string names), where applicable.
@property (nonatomic, readonly, copy, nullable) NSString *material;
@property (nonatomic, readonly, copy, nullable) NSString *blendingMode;

/// Decomposed font where the view (or its cell) carries one; nil otherwise.
@property (nonatomic, readonly, nullable) FLEXAppKitFont *font;

/// Layer facts where the view is layer-backed (wantsLayer / non-nil layer); nil
/// otherwise. A nil layer is normal, not a failure (NSView is not always backed).
@property (nonatomic, readonly, nullable) FLEXAppKitLayer *layer;

@property (nonatomic, readonly, copy) NSArray<FLEXAppKitViewSnapshot *> *children;

@end

NS_ASSUME_NONNULL_END
