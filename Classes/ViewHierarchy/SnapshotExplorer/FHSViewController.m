//
//  FHSViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 1/6/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FHSViewController.h"
#import "FHSSnapshotView.h"
#import "FLEXHierarchyViewController.h"
#import "FLEXColor.h"
#import "FLEXAlert.h"
#import "FLEXWindow.h"
#import "FLEXResources.h"
#import "NSArray+FLEX.h"
#import "UIBarButtonItem+FLEX.h"

BOOL const kFHSViewControllerExcludeFLEXWindows = YES;

@interface FHSViewController () <FHSSnapshotViewDelegate>
/// An array of only the target views whose hierarchies
/// we wish to snapshot, not every view in the snapshot.
@property (nonatomic, readonly) NSArray<UIView *> *targetViews;
@property (nonatomic, readonly) NSArray<FHSView *> *views;
@property (nonatomic          ) NSArray<FHSViewSnapshot *> *snapshots;
@property (nonatomic,         ) FHSSnapshotView *snapshotView;

@property (nonatomic, readonly) UIView *containerView;
@property (nonatomic, readonly) NSArray<UIView *> *viewsAtTap;
@property (nonatomic, readonly) NSMutableSet<Class> *forceHideHeaders;
@end

@implementation FHSViewController
@synthesize views = _views;
@synthesize snapshotView = _snapshotView;

#pragma mark - Initialization

+ (instancetype)snapshotWindows:(NSArray<UIWindow *> *)windows {
    return [[self alloc] initWithViews:windows viewsAtTap:nil selectedView:nil];
}

+ (instancetype)snapshotView:(UIView *)view {
    return [[self alloc] initWithViews:@[view] viewsAtTap:nil selectedView:nil];
}

+ (instancetype)snapshotViewsAtTap:(NSArray<UIView *> *)viewsAtTap selectedView:(UIView *)view {
    NSParameterAssert(viewsAtTap.count);
    NSParameterAssert(view.window);
    return [[self alloc] initWithViews:@[view.window] viewsAtTap:viewsAtTap selectedView:view];
}

- (id)initWithViews:(NSArray<UIView *> *)views
         viewsAtTap:(NSArray<UIView *> *)viewsAtTap
       selectedView:(UIView *)view {
    NSParameterAssert(views.count);

    self = [super init];
    if (self) {
        _forceHideHeaders = [NSMutableSet setWithObject:NSClassFromString(@"_UITableViewCellSeparatorView")];
        _selectedView = view;
        _viewsAtTap = viewsAtTap;

        if (!viewsAtTap && kFHSViewControllerExcludeFLEXWindows) {
            Class flexwindow = [FLEXWindow class];
            views = [views flex_filtered:^BOOL(UIView *view, NSUInteger idx) {
                return [view class] != flexwindow;
            }];
        }

        _targetViews = views;
        _views = [views flex_mapped:^id(UIView *view, NSUInteger idx) {
            BOOL isScrollView = [view.superview isKindOfClass:[UIScrollView class]];
            return [FHSView forView:view isInScrollView:isScrollView];
        }];
    }

    return self;
}

- (void)refreshSnapshotView {
    // Alert view to block interaction while we load everything
    UIAlertController *loading = [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Please Wait").message(@"Generating snapshot…");
    }];
    [self presentViewController:loading animated:YES completion:^{
        self.snapshots = [self.views flex_mapped:^id(FHSView *view, NSUInteger idx) {
            return [FHSViewSnapshot snapshotWithView:view];
        }];
        FHSSnapshotView *newSnapshotView = [FHSSnapshotView delegate:self];

        // This work is highly intensive so we do it on a background thread first
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            // Setting the snapshots computes lots of SCNNodes, takes several seconds
            newSnapshotView.snapshots = self.snapshots;

            // After we finish generating all the model objects and scene nodes, display the view
            dispatch_async(dispatch_get_main_queue(), ^{
                // Dismiss alert
                [loading dismissViewControllerAnimated:YES completion:nil];

                self.snapshotView = newSnapshotView;
            });
        });
    }];
}


#pragma mark - View Controller Lifecycle

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = FLEXColor.primaryBackgroundColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize back bar button item for 3D view to look like a button
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.toggle2DIcon
        target:self.navigationController
        action:@selector(toggleHierarchyMode)
    ];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_snapshotView) {
        [self refreshSnapshotView];
    }
}


#pragma mark - Public

- (void)setSelectedView:(UIView *)view {
    _selectedView = view;
    self.snapshotView.selectedView = view ? [self snapshotForView:view] : nil;
}


#pragma mark - Private

#pragma mark Properties

- (FHSSnapshotView *)snapshotView {
    return self.isViewLoaded ? _snapshotView : nil;
}

- (void)setSnapshotView:(FHSSnapshotView *)snapshotView {
    NSParameterAssert(snapshotView);

    _snapshotView = snapshotView;

    // Initialize our toolbar items
    self.toolbarItems = @[
        [UIBarButtonItem flex_itemWithCustomView:snapshotView.spacingSlider],
        UIBarButtonItem.flex_flexibleSpace,
        [UIBarButtonItem
            flex_itemWithImage:FLEXResources.moreIcon
            target:self action:@selector(didPressOptionsButton:)
        ],
        UIBarButtonItem.flex_flexibleSpace,
        [UIBarButtonItem flex_itemWithCustomView:snapshotView.depthSlider]
    ];
    [self resizeToolbarItems:self.view.frame.size];

    // If we have views-at-tap, dim the other views
    [snapshotView emphasizeViews:self.viewsAtTap];
    // Set the selected view, if any
    snapshotView.selectedView = [self snapshotForView:self.selectedView];
    snapshotView.headerExclusions = self.forceHideHeaders.allObjects;
    [snapshotView setNeedsLayout];

    // Remove old snapshot, if any, and add the new one
    [_snapshotView removeFromSuperview];
    snapshotView.frame = self.containerView.bounds;
    [self.containerView addSubview:snapshotView];
}

- (UIView *)containerView {
    return self.view;
}

#pragma mark Helper

- (FHSViewSnapshot *)snapshotForView:(UIView *)view {
    if (!view || !self.snapshots.count) return nil;

    for (FHSViewSnapshot *snapshot in self.snapshots) {
        FHSViewSnapshot *found = [snapshot snapshotForView:view];
        if (found) {
            return found;
        }
    }

    // Error: we have snapshots but the view we requested is not in one
    @throw NSInternalInconsistencyException;
    return nil;
}

#pragma mark Events

- (void)didPressOptionsButton:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        if (self.selectedView) {
            make.button(@"Hide selected view").handler(^(NSArray<NSString *> *strings) {
                [self.snapshotView hideView:[self snapshotForView:self.selectedView]];
            });
            make.button(@"Hide headers for views like this").handler(^(NSArray<NSString *> *strings) {
                Class cls = [self.selectedView class];
                if (![self.forceHideHeaders containsObject:cls]) {
                    [self.forceHideHeaders addObject:[self.selectedView class]];
                    self.snapshotView.headerExclusions = self.forceHideHeaders.allObjects;
                }
            });
        }
        make.title(@"Options");
        make.button(@"Toggle headers").handler(^(NSArray<NSString *> *strings) {
            [self.snapshotView toggleShowHeaders];
        });
        make.button(@"Toggle outlines").handler(^(NSArray<NSString *> *strings) {
            [self.snapshotView toggleShowBorders];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}

- (void)resizeToolbarItems:(CGSize)viewSize {
    CGFloat sliderHeights = self.snapshotView.spacingSlider.bounds.size.height;
    CGFloat sliderWidths = viewSize.width / 3.f;
    CGRect frame = CGRectMake(0, 0, sliderWidths, sliderHeights);
    self.snapshotView.spacingSlider.frame = frame;
    self.snapshotView.depthSlider.frame = frame;

    [self.navigationController.toolbar setNeedsLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self resizeToolbarItems:self.view.frame.size];
    } completion:nil];
}

#pragma mark FHSSnapshotViewDelegate

- (void)didDeselectView:(FHSViewSnapshot *)snapshot {
    // Our setter would also call the setter for the snapshot view,
    // which we don't need to do here since it is already selected
    _selectedView = nil;
}

- (void)didLongPressView:(FHSViewSnapshot *)snapshot {

}

- (void)didSelectView:(FHSViewSnapshot *)snapshot {
    // Our setter would also call the setter for the snapshot view,
    // which we don't need to do here since it is already selected
    _selectedView = snapshot.view.view;
}

@end
