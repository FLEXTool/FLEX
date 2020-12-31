//
//  FHSView.m
//  FLEX
//
//  Created by Tanner Bennett on 1/6/20.
//

#import "FHSView.h"
#import "FLEXUtility.h"
#import "NSArray+FLEX.h"

@interface FHSView (Snapshotting)
+ (UIImage *)_snapshotView:(UIView *)view;
@end

@implementation FHSView

+ (instancetype)forView:(UIView *)view isInScrollView:(BOOL)inScrollView {
    return [[self alloc] initWithView:view isInScrollView:inScrollView];
}

- (id)initWithView:(UIView *)view isInScrollView:(BOOL)inScrollView {
    self = [super init];
    if (self) {
        _view = view;
        _inScrollView = inScrollView;
        _identifier = NSUUID.UUID.UUIDString;

        UIViewController *controller = [FLEXUtility viewControllerForView:view];
        if (controller) {
            _important = YES;
            _title = [NSString stringWithFormat:
                @"%@ (for %@)",
                NSStringFromClass([controller class]),
                NSStringFromClass([view class])
            ];
        } else {
            _title = NSStringFromClass([view class]);
        }
    }

    return self;
}

- (CGRect)frame {
    if (_inScrollView) {
        CGPoint offset = [(UIScrollView *)self.view.superview contentOffset];
        return CGRectOffset(self.view.frame, -offset.x, -offset.y);
    } else {
        return self.view.frame;
    }
}

- (BOOL)hidden {
    return self.view.isHidden;
}

- (UIImage *)snapshotImage {
    return [FHSView _snapshotView:self.view];
}

- (NSArray<FHSView *> *)children {
    BOOL isScrollView = [self.view isKindOfClass:[UIScrollView class]];
    return [self.view.subviews flex_mapped:^id(UIView *subview, NSUInteger idx) {
        return [FHSView forView:subview isInScrollView:isScrollView];
    }];
}

- (NSString *)summary {
    CGRect f = self.frame;
    return [NSString stringWithFormat:
        @"%@ (%.1f, %.1f, %.1f, %.1f)",
        NSStringFromClass([self.view class]),
        f.origin.x, f.origin.y, f.size.width, f.size.height
    ];
}

- (NSString *)description{
    return self.view.description;
}

- (id)ifImportant:(id)importantAttr ifNormal:(id)normalAttr {
    return self.important ? importantAttr : normalAttr;
}

@end

@implementation FHSView (Snapshotting)

+ (UIImage *)drawView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/// Recursively hides all views that may be obscuring the given view and collects them
/// in the given array. You should unhide them all when you are done.
+ (BOOL)_hideViewsCoveringView:(UIView *)view
                          root:(UIView *)rootView
                   hiddenViews:(NSMutableArray<UIView *> *)hiddenViews {
    // Stop when we reach this view
    if (view == rootView) {
        return YES;
    }

    for (UIView *subview in rootView.subviews.reverseObjectEnumerator.allObjects) {
        if ([self _hideViewsCoveringView:view root:subview hiddenViews:hiddenViews]) {
            return YES;
        }
    }

    if (!rootView.isHidden) {
        rootView.hidden = YES;
        [hiddenViews addObject:rootView];
    }

    return NO;
}


/// Recursively hides all views that may be obscuring the given view and collects them
/// in the given array. You should unhide them all when you are done.
+ (void)hideViewsCoveringView:(UIView *)view doWhileHidden:(void(^)())block {
    NSMutableArray *viewsToUnhide = [NSMutableArray new];
    if ([self _hideViewsCoveringView:view root:view.window hiddenViews:viewsToUnhide]) {
        block();
    }

    for (UIView *v in viewsToUnhide) {
        v.hidden = NO;
    }
}

+ (UIImage *)_snapshotVisualEffectBackdropView:(UIView *)view {
    NSParameterAssert(view.window);

    // UIVisualEffectView is a special case that cannot be snapshotted
    // the same way as any other view. From Apple docs:
    //
    //   Many effects require support from the window that hosts the
    //   UIVisualEffectView. Attempting to take a snapshot of only the
    //   UIVisualEffectView will result in a snapshot that does not
    //   contain the effect. To take a snapshot of a view hierarchy
    //   that contains a UIVisualEffectView, you must take a snapshot
    //   of the entire UIWindow or UIScreen that contains it.
    //
    // To snapshot this view, we traverse the view hierarchy starting
    // from the window and hide any views that are on top of the
    // _UIVisualEffectBackdropView so that it is visible in a snapshot
    // of the window. We then take a snapshot of the window and crop
    // it to the part that contains the backdrop view. This appears to
    // be the same technique that Xcode's own view debugger uses to
    // snapshot visual effect views.
    __block UIImage *image = nil;
    [self hideViewsCoveringView:view doWhileHidden:^{
        image = [self drawView:view];
        CGRect cropRect = [view.window convertRect:view.bounds fromView:view];
        image = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(image.CGImage, cropRect)];
    }];

    return image;
}

+ (UIImage *)_snapshotView:(UIView *)view {
    UIView *superview = view.superview;
    // Is this view inside a UIVisualEffectView?
    if ([superview isKindOfClass:[UIVisualEffectView class]]) {
        // Is it (probably) the "backdrop" view of this UIVisualEffectView?
        if (superview.subviews.firstObject == view) {
            return [self _snapshotVisualEffectBackdropView:view];
        }
    }

    // Hide the view's subviews before we snapshot it
    NSMutableIndexSet *toUnhide = [NSMutableIndexSet new];
    [view.subviews flex_forEach:^(UIView *v, NSUInteger idx) {
        if (!v.isHidden) {
            v.hidden = YES;
            [toUnhide addIndex:idx];
        }
    }];

    // Snapshot the view, then unhide the previously-unhidden views
    UIImage *snapshot = [self drawView:view];
    for (UIView *v in [view.subviews objectsAtIndexes:toUnhide]) {
        v.hidden = NO;
    }

    return snapshot;
}

@end
