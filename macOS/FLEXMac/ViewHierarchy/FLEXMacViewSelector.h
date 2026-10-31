//
//  FLEXMacViewSelector.h
//  FLEX (macOS)
//
//  "Select" mode: hover over any view in the app to highlight it and
//  click to select it. Press Escape to cancel.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacViewSelector : NSObject

@property (nonatomic, readonly, class) FLEXMacViewSelector *sharedSelector;

@property (nonatomic, readonly) BOOL isActive;

/// @param handler called with the selected view, or nil if selection was cancelled
- (void)beginWithHandler:(void(^)(NSView *_Nullable selectedView))handler;
- (void)cancel;

/// The deepest app view under the given screen point, if any
+ (nullable NSView *)viewAtScreenPoint:(NSPoint)point;

@end

NS_ASSUME_NONNULL_END
