//
//  main.m  — FLEXAppKitProbe
//
//  A scoped correctness harness for FLEXAppKitWalker. Builds only against FLEXAppKit
//  (not the UIKit FLEX target), so it runs on macOS via `swift run FLEXAppKitProbe`.
//  Asserts the walker's output against geometry/font facts computed independently.
//
//  This is dev tooling, not part of the upstream library.
//

#import <AppKit/AppKit.h>
#import <math.h>
#import <stdio.h>
@import FLEXAppKit;

@interface FLEXProbeView : NSView
@end
@implementation FLEXProbeView
@end

@interface FLEXFlippedView : NSView
@end
@implementation FLEXFlippedView
- (BOOL)isFlipped { return YES; }
@end

static int gFailures = 0;

static void check(BOOL cond, NSString *msg) {
    printf("  %s: %s\n", cond ? "ok" : "FAIL", msg.UTF8String);
    if (!cond) { gFailures++; }
}

static BOOL approx(CGFloat a, CGFloat b) { return fabs(a - b) <= 0.5; }

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];

        // 1. Real runtime class via object_getClass
        FLEXProbeView *custom = [[FLEXProbeView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        FLEXAppKitViewSnapshot *cs = [FLEXAppKitWalker snapshotForView:custom inWindow:nil];
        check([cs.className isEqualToString:@"FLEXProbeView"],
              [NSString stringWithFormat:@"real class == FLEXProbeView (got %@)", cs.className]);

        // A titled window; its content bottom-left coincides with the window frame
        // bottom-left (titlebar is at the top), so winH = contentH + titlebar.
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                                       styleMask:NSWindowStyleMaskTitled
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        NSView *content = window.contentView;
        CGFloat winH = window.frame.size.height;
        CGFloat titlebar = winH - 300;

        // 2a. Non-flipped subview: raw frame + normalized top-left + isFlipped
        NSView *plain = [[NSView alloc] initWithFrame:NSMakeRect(50, 40, 100, 20)];
        [content addSubview:plain];
        FLEXAppKitViewSnapshot *ps = [FLEXAppKitWalker snapshotForView:plain inWindow:window];
        check(approx(ps.frame.origin.x, 50) && approx(ps.frame.origin.y, 40),
              @"raw frame preserved in AppKit (bottom-left) coords");
        check(ps.isFlipped == NO, @"isFlipped == NO for a default view");
        check(approx(ps.frameTopLeft.origin.x, 50),
              [NSString stringWithFormat:@"normalized x == 50 (got %.1f)", ps.frameTopLeft.origin.x]);
        check(approx(ps.frameTopLeft.origin.y, winH - 60),
              [NSString stringWithFormat:@"normalized yTop == %.1f (got %.1f)", winH - 60, ps.frameTopLeft.origin.y]);

        // 2b. Flipped container: isFlipped reported, normalized geometry still correct
        FLEXFlippedView *flipped = [[FLEXFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        [content addSubview:flipped];
        NSView *inFlipped = [[NSView alloc] initWithFrame:NSMakeRect(50, 40, 100, 20)];
        [flipped addSubview:inFlipped];
        FLEXAppKitViewSnapshot *fs = [FLEXAppKitWalker snapshotForView:flipped inWindow:window];
        check(fs.isFlipped == YES, @"isFlipped == YES for a flipped container");
        FLEXAppKitViewSnapshot *ifs = fs.children.firstObject;
        check(ifs != nil && approx(ifs.frameTopLeft.origin.y, titlebar + 40),
              [NSString stringWithFormat:@"flipped child yTop == %.1f (got %.1f)",
                                         titlebar + 40, ifs ? ifs.frameTopLeft.origin.y : -1]);

        // 3. Font decomposition: raw weight trait AND nearest name, no lossy conversion
        NSTextField *label = [NSTextField labelWithString:@"Hi"];
        label.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
        [content addSubview:label];
        FLEXAppKitViewSnapshot *ls = [FLEXAppKitWalker snapshotForView:label inWindow:window];
        check(ls.font != nil, @"label reports a font");
        check(ls.font && approx(ls.font.pointSize, 13), @"font pointSize == 13");
        check(ls.font && [ls.font.weightName isEqualToString:@"semibold"],
              [NSString stringWithFormat:@"weightName == semibold (got %@)", ls.font.weightName]);
        check(ls.font && approx(ls.font.weightTrait, NSFontWeightSemibold),
              @"weightTrait ~ NSFontWeightSemibold (raw, not converted)");
        check(ls.font.postScriptName.length > 0, @"postScriptName present");

        // 4. No font carrier -> null, a success not an error
        check(ps.font == nil, @"plain NSView reports no font (null)");

        printf("\n%s (%d failure%s)\n", gFailures == 0 ? "ALL PASS" : "FAILURES",
               gFailures, gFailures == 1 ? "" : "s");
        return gFailures == 0 ? 0 : 1;
    }
}
