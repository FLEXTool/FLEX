//
//  main.m  — FLEXAppKitProbe
//
//  A scoped correctness harness for FLEXAppKitWalker. Builds only against FLEXAppKit
//  (not the UIKit FLEX target), so it runs on macOS via `swift run FLEXAppKitProbe`.
//  Asserts the walker's output against geometry/font/color/layer facts computed
//  independently. This is dev tooling, not part of the upstream library.
//

#import <AppKit/AppKit.h>
#import <objc/runtime.h>
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

        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                                       styleMask:NSWindowStyleMaskTitled
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        window.title = @"ProbeWindow";
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
        check(ps.font == nil, @"plain NSView reports no font (null)");

        // 4. Rooted traversal: NSApp.windows enumeration
        NSArray<FLEXAppKitWindowSnapshot *> *windows = [FLEXAppKitWalker snapshotApplicationWindows];
        FLEXAppKitWindowSnapshot *probeWindow = nil;
        for (FLEXAppKitWindowSnapshot *w in windows) {
            if ([w.title isEqualToString:@"ProbeWindow"]) { probeWindow = w; break; }
        }
        check(probeWindow != nil, @"NSApp.windows enumeration finds ProbeWindow as a root");
        check(probeWindow.className.length > 0 && [probeWindow.className containsString:@"Window"],
              [NSString stringWithFormat:@"window real class looks like an NSWindow (got %@)", probeWindow.className]);
        check(probeWindow.contentView != nil && probeWindow.contentView.children.count >= 1,
              @"window root carries its contentView subtree");

        // 5. swiftUIBoundary: a class whose name contains NSHostingView trips the flag
        Class hostingStub = objc_allocateClassPair([NSView class], "NSHostingViewStub", 0);
        objc_registerClassPair(hostingStub);
        NSView *fakeHost = [[hostingStub alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        FLEXAppKitViewSnapshot *hs = [FLEXAppKitWalker snapshotForView:fakeHost inWindow:nil];
        check(hs.swiftUIBoundary == YES, @"swiftUIBoundary == YES at an NSHostingView-named class");
        check(ps.swiftUIBoundary == NO, @"swiftUIBoundary == NO for a plain view");

        // 6. Layer sub-shape + NSColor decomposition (standalone, layer-backed)
        NSView *backed = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 50, 50)];
        backed.wantsLayer = YES;
        backed.layer.cornerRadius = 8;
        backed.layer.masksToBounds = YES;
        backed.layer.backgroundColor = [NSColor colorWithSRGBRed:1 green:0 blue:0 alpha:1].CGColor;
        FLEXAppKitViewSnapshot *bs = [FLEXAppKitWalker snapshotForView:backed inWindow:nil];
        check(bs.layer != nil, @"layer-backed view captures a layer");
        check(bs.layer && approx(bs.layer.cornerRadius, 8), @"layer cornerRadius == 8");
        check(bs.layer && bs.layer.masksToBounds == YES, @"layer masksToBounds == YES");
        check(bs.layer.backgroundColor != nil, @"layer has a decomposed backgroundColor");
        check(bs.layer.backgroundColor && [bs.layer.backgroundColor.hex isEqualToString:@"#FF0000FF"],
              [NSString stringWithFormat:@"bg color hex == #FF0000FF (got %@)", bs.layer.backgroundColor.hex]);

        // 6b. nil-layer: a standalone, non-wantsLayer view reports no layer (success)
        NSView *unbacked = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        FLEXAppKitViewSnapshot *us = [FLEXAppKitWalker snapshotForView:unbacked inWindow:nil];
        check(us.layer == nil, @"unbacked standalone view reports no layer (nil, not error)");

        // 7. NSVisualEffectView material / blendingMode
        NSVisualEffectView *vev = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 50, 50)];
        vev.material = NSVisualEffectMaterialSidebar;
        FLEXAppKitViewSnapshot *vs = [FLEXAppKitWalker snapshotForView:vev inWindow:nil];
        check([vs.material isEqualToString:@"sidebar"],
              [NSString stringWithFormat:@"material == sidebar (got %@)", vs.material]);
        check(vs.blendingMode.length > 0,
              [NSString stringWithFormat:@"blendingMode present (got %@)", vs.blendingMode]);

        // 8. Node-schema completeness: superclasses / text / axRole / constraintsCount
        check([cs.superclasses containsObject:@"NSView"] && [cs.superclasses.lastObject isEqualToString:@"NSObject"],
              [NSString stringWithFormat:@"superclasses run up to NSObject (got %@)", cs.superclasses]);
        check(ls.text != nil && [ls.text isEqualToString:@"Hi"],
              [NSString stringWithFormat:@"text == 'Hi' for the label (got %@)", ls.text]);
        check(ps.text == nil, @"plain NSView reports no text (null)");
        check(ls.axRole.length > 0,
              [NSString stringWithFormat:@"label carries an axRole (got %@)", ls.axRole]);

        NSView *constrained = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
        [content addSubview:constrained];
        [constrained addConstraint:[NSLayoutConstraint constraintWithItem:constrained
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:120]];
        FLEXAppKitViewSnapshot *cns = [FLEXAppKitWalker snapshotForView:constrained inWindow:window];
        check(cns.constraintsCount == 1,
              [NSString stringWithFormat:@"constraintsCount == 1 (got %ld)", (long)cns.constraintsCount]);

        // 9. Depth bound: truncated + childCount, children omitted past the bound
        NSView *a = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)];
        NSView *b = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
        NSView *cc = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        [a addSubview:b];
        [b addSubview:cc];
        FLEXAppKitViewSnapshot *as = [FLEXAppKitWalker snapshotForView:a inWindow:nil maxDepth:1];
        check(as.truncated == NO && as.childCount == 1 && as.children.count == 1,
              @"depth root: not truncated, childCount 1, one child present");
        FLEXAppKitViewSnapshot *deepB = as.children.firstObject;
        check(deepB != nil && deepB.truncated == YES && deepB.childCount == 1 && deepB.children.count == 0,
              @"depth bound: node truncated, childCount 1, children omitted");

        // 10. Constraints extraction (FLEXConstraintNode)
        FLEXConstraintNode *cn = [FLEXConstraintNode constraintsForView:constrained];
        FLEXConstraint *wc = cn.constraints.firstObject;
        check(wc != nil && [wc.first.attribute isEqualToString:@"width"]
                  && [wc.relation isEqualToString:@"equal"] && approx(wc.constant, 120)
                  && [wc.second.kind isEqualToString:@"none"] && wc.first.isTarget,
              @"width constraint serialized (width == 120, second none, first is target)");

        NSView *cont = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 50)];
        NSView *cA = [NSView new];
        NSView *cB = [NSView new];
        cA.translatesAutoresizingMaskIntoConstraints = NO;
        cB.translatesAutoresizingMaskIntoConstraints = NO;
        [cont addSubview:cA];
        [cont addSubview:cB];
        [cont addConstraint:[NSLayoutConstraint constraintWithItem:cA
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cB
                                                         attribute:NSLayoutAttributeLeading
                                                        multiplier:1
                                                          constant:8]];
        FLEXConstraintNode *cnA = [FLEXConstraintNode constraintsForView:cA];
        FLEXConstraint *bc = cnA.constraints.firstObject;
        check(cnA.constraints.count == 1 && bc != nil && [bc.first.attribute isEqualToString:@"trailing"]
                  && bc.first.isTarget && [bc.second.kind isEqualToString:@"view"] && approx(bc.constant, 8),
              @"sibling constraint found for the first item (ancestor-held, both directions)");
        FLEXConstraintNode *cnB = [FLEXConstraintNode constraintsForView:cB];
        check(cnB.constraints.count == 1, @"same constraint found for the SECOND item (reverse direction)");

        // 11. Window nesting: a child window nests under its parent, not as a root
        NSWindow *childWin = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                         styleMask:NSWindowStyleMaskTitled
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
        childWin.title = @"ChildProbeWindow";
        [window addChildWindow:childWin ordered:NSWindowAbove];
        NSArray<FLEXAppKitWindowSnapshot *> *ws2 = [FLEXAppKitWalker snapshotApplicationWindows];
        BOOL childIsRoot = NO;
        FLEXAppKitWindowSnapshot *parentRoot = nil;
        for (FLEXAppKitWindowSnapshot *w in ws2) {
            if ([w.title isEqualToString:@"ChildProbeWindow"]) { childIsRoot = YES; }
            if ([w.title isEqualToString:@"ProbeWindow"]) { parentRoot = w; }
        }
        check(!childIsRoot, @"child window is NOT a top-level root");
        BOOL childNested = NO;
        for (FLEXAppKitWindowSnapshot *c in parentRoot.childWindows) {
            if ([c.title isEqualToString:@"ChildProbeWindow"]) { childNested = YES; }
        }
        check(parentRoot != nil && childNested, @"child window nested under its parent window");

        // 12. Parallel CALayer sublayer tree + count
        NSView *layerHost = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)];
        layerHost.wantsLayer = YES;
        [layerHost.layer addSublayer:[CALayer layer]];
        [layerHost.layer addSublayer:[CALayer layer]];
        FLEXAppKitViewSnapshot *lhs = [FLEXAppKitWalker snapshotForView:layerHost inWindow:nil];
        check(lhs.layer != nil && lhs.layer.sublayerCount == 2 && lhs.layer.sublayers.count == 2 && !lhs.layer.truncated,
              [NSString stringWithFormat:@"parallel layer tree has 2 sublayers (got %ld)",
                                         lhs.layer ? (long)lhs.layer.sublayerCount : -1]);

        printf("\n%s (%d failure%s)\n", gFailures == 0 ? "ALL PASS" : "FAILURES",
               gFailures, gFailures == 1 ? "" : "s");
        return gFailures == 0 ? 0 : 1;
    }
}
