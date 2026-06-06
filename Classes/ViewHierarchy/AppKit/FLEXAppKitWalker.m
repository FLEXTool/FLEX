//
//  FLEXAppKitWalker.m
//  FLEX
//
//  SPEC: domain.walker
//

#import "FLEXAppKitWalker.h"

#if TARGET_OS_OSX

#import "FLEXAppKitViewSnapshot_Internal.h"
#import "FLEXAppKitWindowSnapshot_Internal.h"
#import "FLEXAppKitFont.h"
#import "FLEXAppKitLayer.h"
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

/// True if the view's class chain contains an NSHostingView (SwiftUI's host). The
/// generic NSHostingView<Content> has a mangled Swift name, so match by substring
/// across the hierarchy rather than isKindOfClass against a single concrete class.
static BOOL FLEXIsSwiftUIBoundary(NSView *view) {
    for (Class cls = object_getClass(view); cls != Nil; cls = class_getSuperclass(cls)) {
        const char *name = class_getName(cls);
        if (name != NULL && strstr(name, "NSHostingView") != NULL) {
            return YES;
        }
    }
    return NO;
}

static NSString *FLEXMaterialName(NSVisualEffectMaterial material) {
    switch (material) {
        case NSVisualEffectMaterialTitlebar: return @"titlebar";
        case NSVisualEffectMaterialSelection: return @"selection";
        case NSVisualEffectMaterialMenu: return @"menu";
        case NSVisualEffectMaterialPopover: return @"popover";
        case NSVisualEffectMaterialSidebar: return @"sidebar";
        case NSVisualEffectMaterialHeaderView: return @"headerView";
        case NSVisualEffectMaterialSheet: return @"sheet";
        case NSVisualEffectMaterialWindowBackground: return @"windowBackground";
        case NSVisualEffectMaterialHUDWindow: return @"hudWindow";
        case NSVisualEffectMaterialFullScreenUI: return @"fullScreenUI";
        case NSVisualEffectMaterialToolTip: return @"toolTip";
        case NSVisualEffectMaterialContentBackground: return @"contentBackground";
        case NSVisualEffectMaterialUnderWindowBackground: return @"underWindowBackground";
        case NSVisualEffectMaterialUnderPageBackground: return @"underPageBackground";
        default: return [NSString stringWithFormat:@"material(%ld)", (long)material];
    }
}

static NSString *FLEXBlendingModeName(NSVisualEffectBlendingMode mode) {
    switch (mode) {
        case NSVisualEffectBlendingModeBehindWindow: return @"behindWindow";
        case NSVisualEffectBlendingModeWithinWindow: return @"withinWindow";
        default: return [NSString stringWithFormat:@"blendingMode(%ld)", (long)mode];
    }
}

@implementation FLEXAppKitWalker

+ (NSArray<FLEXAppKitWindowSnapshot *> *)snapshotApplicationWindows {
    NSApplication *app = NSApplication.sharedApplication;
    NSWindow *keyWindow = app.keyWindow;
    NSWindow *mainWindow = app.mainWindow;

    NSMutableArray<FLEXAppKitWindowSnapshot *> *result = [NSMutableArray array];
    for (NSWindow *window in app.windows) {
        FLEXAppKitWindowSnapshot *snapshot = [FLEXAppKitWindowSnapshot new];
        snapshot.className = NSStringFromClass(object_getClass(window));
        snapshot.title = window.title;
        snapshot.identifier = window.identifier;
        snapshot.isKeyWindow = (window == keyWindow);
        snapshot.isMainWindow = (window == mainWindow);
        snapshot.isVisible = window.isVisible;
        snapshot.isPanel = [window isKindOfClass:[NSPanel class]];
        snapshot.frame = window.frame;
        NSView *content = window.contentView;
        snapshot.contentView = content ? [self snapshotForView:content inWindow:window] : nil;
        [result addObject:snapshot];
    }
    return result;
}

+ (FLEXAppKitViewSnapshot *)snapshotForView:(NSView *)view inWindow:(nullable NSWindow *)window {
    FLEXAppKitViewSnapshot *snapshot = [FLEXAppKitViewSnapshot new];
    snapshot.className = NSStringFromClass(object_getClass(view));
    snapshot.frame = view.frame;
    snapshot.frameTopLeft = [self topLeftFrameForView:view inWindow:window];
    snapshot.isFlipped = view.isFlipped;
    snapshot.hidden = view.isHidden;
    snapshot.alpha = view.alphaValue;
    snapshot.identifier = view.identifier;
    snapshot.swiftUIBoundary = FLEXIsSwiftUIBoundary(view);
    snapshot.font = [FLEXAppKitFont fontForObject:view];

    if ([view isKindOfClass:[NSVisualEffectView class]]) {
        NSVisualEffectView *effect = (NSVisualEffectView *)view;
        snapshot.material = FLEXMaterialName(effect.material);
        snapshot.blendingMode = FLEXBlendingModeName(effect.blendingMode);
    }

    // Layer facts only where the view is layer-backed — a nil layer is normal.
    if (view.layer != nil) {
        snapshot.layer = [FLEXAppKitLayer layerFromLayer:view.layer
                                            inAppearance:view.effectiveAppearance];
    }

    NSMutableArray<FLEXAppKitViewSnapshot *> *children =
        [NSMutableArray arrayWithCapacity:view.subviews.count];
    for (NSView *subview in view.subviews) {
        [children addObject:[self snapshotForView:subview inWindow:window]];
    }
    snapshot.children = children;
    return snapshot;
}

/// Normalized top-left rect, full-window-frame-relative (titlebar included), per
/// domain.walker. Computed through screen coordinates so per-view isFlipped is
/// resolved by AppKit's own conversion rather than manual y-flipping.
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
