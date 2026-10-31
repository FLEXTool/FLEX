//
//  FLEXMacHighlightWindow.h
//  FLEX (macOS)
//
//  A transparent, click-through overlay which outlines a view on screen.
//

#import <AppKit/AppKit.h>
#import "FLEXMacUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacHighlightWindow : NSWindow <FLEXMacInternalWindow>

/// The overlay used for the current selection
@property (nonatomic, readonly, class) FLEXMacHighlightWindow *selectionHighlight;

/// Outlines \c view for a moment using a separate overlay
+ (void)flashView:(nullable NSView *)view;

@property (nonatomic, readonly, weak, nullable) NSView *highlightedView;
/// Shows the overlay over \c view, or hides it if \c view is nil or offscreen
- (void)highlightView:(nullable NSView *)view;

@end

NS_ASSUME_NONNULL_END
