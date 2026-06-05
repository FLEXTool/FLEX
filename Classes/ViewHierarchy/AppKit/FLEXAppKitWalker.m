//
//  FLEXAppKitWalker.m
//  FLEX
//
//  SPEC: domain.walker
//

#import "FLEXAppKitWalker.h"

#if TARGET_OS_OSX

#import "FLEXAppKitViewSnapshot.h"
#import "FLEXAppKitFont.h"
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@implementation FLEXAppKitWalker

+ (FLEXAppKitViewSnapshot *)snapshotForView:(NSView *)view inWindow:(nullable NSWindow *)window {
    NSString *className = NSStringFromClass(object_getClass(view));
    FLEXAppKitFont *font = [FLEXAppKitFont fontForObject:view];

    NSMutableArray<FLEXAppKitViewSnapshot *> *children =
        [NSMutableArray arrayWithCapacity:view.subviews.count];
    for (NSView *subview in view.subviews) {
        [children addObject:[self snapshotForView:subview inWindow:window]];
    }

    return [[FLEXAppKitViewSnapshot alloc] initWithClassName:className
                                                       frame:view.frame
                                                frameTopLeft:[self topLeftFrameForView:view
                                                                              inWindow:window]
                                                   isFlipped:view.isFlipped
                                                      hidden:view.isHidden
                                                       alpha:view.alphaValue
                                                  identifier:view.identifier
                                                        font:font
                                                    children:children];
}

/// Normalized top-left rect, full-window-frame-relative (titlebar included), per
/// domain.walker. Computed through screen coordinates so that per-view isFlipped is
/// resolved by AppKit's own conversion rather than by manual y-flipping — the #1
/// silent-correctness trap.
+ (CGRect)topLeftFrameForView:(NSView *)view inWindow:(nullable NSWindow *)window {
    if (window == nil) {
        return view.frame;
    }
    NSRect inWindow = [view convertRect:view.bounds toView:nil];
    NSRect inScreen = [window convertRectToScreen:inWindow];
    NSRect windowFrame = window.frame;
    CGFloat x = NSMinX(inScreen) - NSMinX(windowFrame);
    CGFloat yFromTop = NSMaxY(windowFrame) - NSMaxY(inScreen);
    return CGRectMake(x, yFromTop, NSWidth(inScreen), NSHeight(inScreen));
}

@end

#endif // TARGET_OS_OSX
