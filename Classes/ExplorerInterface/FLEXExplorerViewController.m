//
//  FLEXExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerViewController.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"
#import "FLEXWindow.h"
#import "FLEXTabList.h"
#import "FLEXNavigationController.h"
#import "FLEXHierarchyViewController.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXWindowManagerController.h"
#import "FLEXViewControllersViewController.h"
#import "NSUserDefaults+FLEX.h"

typedef NS_ENUM(NSUInteger, FLEXExplorerMode) {
    FLEXExplorerModeDefault,
    FLEXExplorerModeSelect,
    FLEXExplorerModeMove
};

@interface FLEXExplorerViewController () <FLEXHierarchyDelegate, UIAdaptivePresentationControllerDelegate>

/// Tracks the currently active tool/mode
@property (nonatomic) FLEXExplorerMode currentMode;

/// Gesture recognizer for dragging a view in move mode
@property (nonatomic) UIPanGestureRecognizer *movePanGR;

/// Gesture recognizer for showing additional details on the selected view
@property (nonatomic) UITapGestureRecognizer *detailsTapGR;

/// Only valid while a move pan gesture is in progress.
@property (nonatomic) CGRect selectedViewFrameBeforeDragging;

/// Only valid while a toolbar drag pan gesture is in progress.
@property (nonatomic) CGRect toolbarFrameBeforeDragging;

/// Only valid while a selected view pan gesture is in progress.
@property (nonatomic) CGFloat selectedViewLastPanX;

/// Borders of all the visible views in the hierarchy at the selection point.
/// The keys are NSValues with the corresponding view (nonretained).
@property (nonatomic) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;

/// The actual views at the selection point with the deepest view last.
@property (nonatomic) NSArray<UIView *> *viewsAtTapPoint;

/// The view that we're currently highlighting with an overlay and displaying details for.
@property (nonatomic) UIView *selectedView;

/// A colored transparent overlay to indicate that the view is selected.
@property (nonatomic) UIView *selectedViewOverlay;

/// Used to actuate changes in view selection on iOS 10+
@property (nonatomic, readonly) UISelectionFeedbackGenerator *selectionFBG API_AVAILABLE(ios(10.0));

/// self.view.window as a \c FLEXWindow
@property (nonatomic, readonly) FLEXWindow *window;

/// All views that we're KVOing. Used to help us clean up properly.
@property (nonatomic) NSMutableSet<UIView *> *observedViews;

/// Used to preserve the target app's UIMenuController items.
@property (nonatomic) NSArray<UIMenuItem *> *appMenuItems;

@end

@implementation FLEXExplorerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.observedViews = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    for (UIView *view in _observedViews) {
        [self stopObservingView:view];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Toolbar
    _explorerToolbar = [FLEXExplorerToolbar new];

    // Start the toolbar off below any bars that may be at the top of the view.
    CGFloat toolbarOriginY = NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin;

    CGRect safeArea = [self viewSafeArea];
    CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(
        CGRectGetWidth(self.view.bounds), CGRectGetHeight(safeArea)
    )];
    [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(
        CGRectGetMinX(safeArea), toolbarOriginY, toolbarSize.width, toolbarSize.height
    )];
    self.explorerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.explorerToolbar];
    [self setupToolbarActions];
    [self setupToolbarGestures];
    
    // View selection
    UITapGestureRecognizer *selectionTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleSelectionTap:)
    ];
    [self.view addGestureRecognizer:selectionTapGR];
    
    // View moving
    self.movePanGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
    self.movePanGR.enabled = self.currentMode == FLEXExplorerModeMove;
    [self.view addGestureRecognizer:self.movePanGR];
    
    // Feedback
    if (@available(iOS 10.0, *)) {
        _selectionFBG = [UISelectionFeedbackGenerator new];
    }
    
    // Observe keyboard to move self out of the way
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(keyboardShown:)
        name:UIKeyboardWillShowNotification
        object:nil
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateButtonStates];
}


#pragma mark - Rotation

- (UIViewController *)viewControllerForRotationAndOrientation {
    UIViewController *viewController = FLEXUtility.appKeyWindow.rootViewController;
    // Obfuscating selector _viewControllerForSupportedInterfaceOrientations
    NSString *viewControllerSelectorString = [@[
        @"_vie", @"wContro", @"llerFor", @"Supported", @"Interface", @"Orientations"
    ] componentsJoinedByString:@""];
    SEL viewControllerSelector = NSSelectorFromString(viewControllerSelectorString);
    if ([viewController respondsToSelector:viewControllerSelector]) {
        viewController = [viewController valueForKey:viewControllerSelectorString];
    }
    
    return viewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // Commenting this out until I can figure out a better way to solve this
//    if (self.window.isKeyWindow) {
//        [self.window resignKeyWindow];
//    }
    
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    UIInterfaceOrientationMask supportedOrientations = FLEXUtility.infoPlistSupportedInterfaceOrientationsMask;
    // We check its class by name because using isKindOfClass will fail for the same class defined
    // twice in the runtime; and the goal here is to avoid calling -supportedInterfaceOrientations
    // recursively when I'm inspecting FLEX with itself from a tweak dylib
    if (viewControllerToAsk && ![NSStringFromClass([viewControllerToAsk class]) hasPrefix:@"FLEX"]) {
        supportedOrientations = [viewControllerToAsk supportedInterfaceOrientations];
    }
    
    // The UIViewController docs state that this method must not return zero.
    // If we weren't able to get a valid value for the supported interface
    // orientations, default to all supported.
    if (supportedOrientations == 0) {
        supportedOrientations = UIInterfaceOrientationMaskAll;
    }
    
    return supportedOrientations;
}

- (BOOL)shouldAutorotate {
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    BOOL shouldAutorotate = YES;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        shouldAutorotate = [viewControllerToAsk shouldAutorotate];
    }
    return shouldAutorotate;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *outlineView in self.outlineViewsForVisibleViews.allValues) {
            outlineView.hidden = YES;
        }
        self.selectedViewOverlay.hidden = YES;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *view in self.viewsAtTapPoint) {
            NSValue *key = [NSValue valueWithNonretainedObject:view];
            UIView *outlineView = self.outlineViewsForVisibleViews[key];
            outlineView.frame = [self frameInLocalCoordinatesForView:view];
            if (self.currentMode == FLEXExplorerModeSelect) {
                outlineView.hidden = NO;
            }
        }

        if (self.selectedView) {
            self.selectedViewOverlay.frame = [self frameInLocalCoordinatesForView:self.selectedView];
            self.selectedViewOverlay.hidden = NO;
        }
    }];
}


#pragma mark - Setter Overrides

- (void)setSelectedView:(UIView *)selectedView {
    if (![_selectedView isEqual:selectedView]) {
        if (![self.viewsAtTapPoint containsObject:_selectedView]) {
            [self stopObservingView:_selectedView];
        }
        
        _selectedView = selectedView;
        
        [self beginObservingView:selectedView];

        // Update the toolbar and selected overlay
        self.explorerToolbar.selectedViewDescription = [FLEXUtility
            descriptionForView:selectedView includingFrame:YES
        ];
        self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility
            consistentRandomColorForObject:selectedView
        ];

        if (selectedView) {
            if (!self.selectedViewOverlay) {
                self.selectedViewOverlay = [UIView new];
                [self.view addSubview:self.selectedViewOverlay];
                self.selectedViewOverlay.layer.borderWidth = 1.0;
            }
            UIColor *outlineColor = [FLEXUtility consistentRandomColorForObject:selectedView];
            self.selectedViewOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
            self.selectedViewOverlay.layer.borderColor = outlineColor.CGColor;
            self.selectedViewOverlay.frame = [self.view convertRect:selectedView.bounds fromView:selectedView];
            
            // Make sure the selected overlay is in front of all the other subviews
            // except the toolbar, which should always stay on top.
            [self.view bringSubviewToFront:self.selectedViewOverlay];
            [self.view bringSubviewToFront:self.explorerToolbar];
        } else {
            [self.selectedViewOverlay removeFromSuperview];
            self.selectedViewOverlay = nil;
        }
        
        // Some of the button states depend on whether we have a selected view.
        [self updateButtonStates];
    }
}

- (void)setViewsAtTapPoint:(NSArray<UIView *> *)viewsAtTapPoint {
    if (![_viewsAtTapPoint isEqual:viewsAtTapPoint]) {
        for (UIView *view in _viewsAtTapPoint) {
            if (view != self.selectedView) {
                [self stopObservingView:view];
            }
        }
        
        _viewsAtTapPoint = viewsAtTapPoint;
        
        for (UIView *view in viewsAtTapPoint) {
            [self beginObservingView:view];
        }
    }
}

- (void)setCurrentMode:(FLEXExplorerMode)currentMode {
    if (_currentMode != currentMode) {
        _currentMode = currentMode;
        switch (currentMode) {
            case FLEXExplorerModeDefault:
                [self removeAndClearOutlineViews];
                self.viewsAtTapPoint = nil;
                self.selectedView = nil;
                break;
                
            case FLEXExplorerModeSelect:
                // Make sure the outline views are unhidden in case we came from the move mode.
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = NO;
                }
                break;
                
            case FLEXExplorerModeMove:
                // Hide all the outline views to focus on the selected view,
                // which is the only one that will move.
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = YES;
                }
                break;
        }
        self.movePanGR.enabled = currentMode == FLEXExplorerModeMove;
        [self updateButtonStates];
    }
}


#pragma mark - View Tracking

- (void)beginObservingView:(UIView *)view {
    // Bail if we're already observing this view or if there's nothing to observe.
    if (!view || [self.observedViews containsObject:view]) {
        return;
    }
    
    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }
    
    [self.observedViews addObject:view];
}

- (void)stopObservingView:(UIView *)view {
    if (!view) {
        return;
    }
    
    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view removeObserver:self forKeyPath:keyPath];
    }
    
    [self.observedViews removeObject:view];
}

- (NSArray<NSString *> *)viewKeyPathsToTrack {
    static NSArray<NSString *> *trackedViewKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *frameKeyPath = NSStringFromSelector(@selector(frame));
        trackedViewKeyPaths = @[frameKeyPath];
    });
    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {
    [self updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:(id)object {
    NSUInteger indexOfView = [self.viewsAtTapPoint indexOfObject:object];
    if (indexOfView != NSNotFound) {
        UIView *view = self.viewsAtTapPoint[indexOfView];
        NSValue *key = [NSValue valueWithNonretainedObject:view];
        UIView *outline = self.outlineViewsForVisibleViews[key];
        if (outline) {
            outline.frame = [self frameInLocalCoordinatesForView:view];
        }
    }
    if (object == self.selectedView) {
        // Update the selected view description since we show the frame value there.
        self.explorerToolbar.selectedViewDescription = [FLEXUtility
            descriptionForView:self.selectedView includingFrame:YES
        ];
        CGRect selectedViewOutlineFrame = [self frameInLocalCoordinatesForView:self.selectedView];
        self.selectedViewOverlay.frame = selectedViewOutlineFrame;
    }
}

- (CGRect)frameInLocalCoordinatesForView:(UIView *)view {
    // Convert to window coordinates since the view may be in a different window than our view
    CGRect frameInWindow = [view convertRect:view.bounds toView:nil];
    // Convert from the window to our view's coordinate space
    return [self.view convertRect:frameInWindow fromView:nil];
}

- (void)keyboardShown:(NSNotification *)notif {
    CGRect keyboardFrame = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect toolbarFrame = self.explorerToolbar.frame;
    
    if (CGRectGetMinY(keyboardFrame) < CGRectGetMaxY(toolbarFrame)) {
        toolbarFrame.origin.y = keyboardFrame.origin.y - toolbarFrame.size.height;
        // Subtract a little more, to ignore accessory input views
        toolbarFrame.origin.y -= 50;
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self updateToolbarPositionWithUnconstrainedFrame:toolbarFrame];
        } completion:nil];
    }
}

#pragma mark - Toolbar Buttons

- (void)setupToolbarActions {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    NSDictionary<NSString *, FLEXExplorerToolbarItem *> *actionsToItems = @{
        NSStringFromSelector(@selector(selectButtonTapped:)):        toolbar.selectItem,
        NSStringFromSelector(@selector(hierarchyButtonTapped:)):     toolbar.hierarchyItem,
        NSStringFromSelector(@selector(recentButtonTapped:)):        toolbar.recentItem,
        NSStringFromSelector(@selector(moveButtonTapped:)):          toolbar.moveItem,
        NSStringFromSelector(@selector(globalsButtonTapped:)):       toolbar.globalsItem,
        NSStringFromSelector(@selector(closeButtonTapped:)):         toolbar.closeItem,
    };
    
    [actionsToItems enumerateKeysAndObjectsUsingBlock:^(NSString *sel, FLEXExplorerToolbarItem *item, BOOL *stop) {
        [item addTarget:self action:NSSelectorFromString(sel) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)selectButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleSelectTool];
}

- (void)hierarchyButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleViewsTool];
}

- (UIWindow *)statusWindow {
    if (!@available(iOS 16, *)) {
        NSString *statusBarString = [NSString stringWithFormat:@"%@arWindow", @"_statusB"];
        return [UIApplication.sharedApplication valueForKey:statusBarString];
    }
    
    return nil;
}

- (void)recentButtonTapped:(FLEXExplorerToolbarItem *)sender {
    NSAssert(FLEXTabList.sharedList.activeTab, @"Must have active tab");
    [self presentViewController:FLEXTabList.sharedList.activeTab animated:YES completion:nil];
}

- (void)moveButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMoveTool];
}

- (void)globalsButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMenuTool];
}

- (void)closeButtonTapped:(FLEXExplorerToolbarItem *)sender {
    self.currentMode = FLEXExplorerModeDefault;
    [self.delegate explorerViewControllerDidFinish:self];
}

- (void)updateButtonStates {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    
    toolbar.selectItem.selected = self.currentMode == FLEXExplorerModeSelect;
    
    // Move only enabled when an object is selected.
    BOOL hasSelectedObject = self.selectedView != nil;
    toolbar.moveItem.enabled = hasSelectedObject;
    toolbar.moveItem.selected = self.currentMode == FLEXExplorerModeMove;
    
    // Recent only enabled when we have a last active tab
    toolbar.recentItem.enabled = FLEXTabList.sharedList.activeTab != nil;
}


#pragma mark - Toolbar Dragging

- (void)setupToolbarGestures {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    
    // Pan gesture for dragging.
    [toolbar.dragHandle addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarPanGesture:)
    ]];
    
    // Tap gesture for hinting.
    [toolbar.dragHandle addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarHintTapGesture:)
    ]];
    
    // Tap gesture for showing additional details
    self.detailsTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarDetailsTapGesture:)
    ];
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:self.detailsTapGR];
    
    // Swipe gestures for selecting deeper / higher views at a point
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleChangeViewAtPointGesture:)
    ];
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:panGesture];
    
    // Long press gesture to present tabs manager
    [toolbar.globalsItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowTabsGesture:)
    ]];
    
    // Long press gesture to present window manager
    [toolbar.selectItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarWindowManagerGesture:)
    ]];
    
    // Long press gesture to present view controllers at tap
    [toolbar.hierarchyItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowViewControllersGesture:)
    ]];
}

- (void)handleToolbarPanGesture:(UIPanGestureRecognizer *)panGR {
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan:
            self.toolbarFrameBeforeDragging = self.explorerToolbar.frame;
            [self updateToolbarPositionWithDragGesture:panGR];
            break;
            
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateToolbarPositionWithDragGesture:panGR];
            break;
            
        default:
            break;
    }
}

- (void)updateToolbarPositionWithDragGesture:(UIPanGestureRecognizer *)panGR {
    CGPoint translation = [panGR translationInView:self.view];
    CGRect newToolbarFrame = self.toolbarFrameBeforeDragging;
    newToolbarFrame.origin.y += translation.y;
    
    [self updateToolbarPositionWithUnconstrainedFrame:newToolbarFrame];
}

- (void)updateToolbarPositionWithUnconstrainedFrame:(CGRect)unconstrainedFrame {
    CGRect safeArea = [self viewSafeArea];
    // We only constrain the Y-axis because we want the toolbar
    // to handle the X-axis safeArea layout by itself
    CGFloat minY = CGRectGetMinY(safeArea);
    CGFloat maxY = CGRectGetMaxY(safeArea) - unconstrainedFrame.size.height;
    if (unconstrainedFrame.origin.y < minY) {
        unconstrainedFrame.origin.y = minY;
    } else if (unconstrainedFrame.origin.y > maxY) {
        unconstrainedFrame.origin.y = maxY;
    }

    self.explorerToolbar.frame = unconstrainedFrame;
    NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin = unconstrainedFrame.origin.y;
}

- (void)handleToolbarHintTapGesture:(UITapGestureRecognizer *)tapGR {
    // Bounce the toolbar to indicate that it is draggable.
    // TODO: make it bouncier.
    if (tapGR.state == UIGestureRecognizerStateRecognized) {
        CGRect originalToolbarFrame = self.explorerToolbar.frame;
        const NSTimeInterval kHalfwayDuration = 0.2;
        const CGFloat kVerticalOffset = 30.0;
        [UIView animateWithDuration:kHalfwayDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect newToolbarFrame = self.explorerToolbar.frame;
            newToolbarFrame.origin.y += kVerticalOffset;
            self.explorerToolbar.frame = newToolbarFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:kHalfwayDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.explorerToolbar.frame = originalToolbarFrame;
            } completion:nil];
        }];
    }
}

- (void)handleToolbarDetailsTapGesture:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state == UIGestureRecognizerStateRecognized && self.selectedView) {
        UIViewController *topStackVC = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.selectedView];
        [self presentViewController:
            [FLEXNavigationController withRootViewController:topStackVC]
        animated:YES completion:nil];
    }
}

- (void)handleToolbarShowTabsGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Back up the UIMenuController items since dismissViewController: will attempt to replace them
        self.appMenuItems = UIMenuController.sharedMenuController.menuItems;
        
        // Don't use FLEXNavigationController because the tab viewer itself is not a tab
        [super presentViewController:[[UINavigationController alloc]
            initWithRootViewController:[FLEXTabsViewController new]
        ] animated:YES completion:nil];
    }
}

- (void)handleToolbarWindowManagerGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Back up the UIMenuController items since dismissViewController: will attempt to replace them
        self.appMenuItems = UIMenuController.sharedMenuController.menuItems;
        
        [super presentViewController:[FLEXNavigationController
            withRootViewController:[FLEXWindowManagerController new]
        ] animated:YES completion:nil];
    }
}

- (void)handleToolbarShowViewControllersGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan && self.viewsAtTapPoint.count) {
        // Back up the UIMenuController items since dismissViewController: will attempt to replace them
        self.appMenuItems = UIMenuController.sharedMenuController.menuItems;
        
        UIViewController *list = [FLEXViewControllersViewController
            controllersForViews:self.viewsAtTapPoint
        ];
        [self presentViewController:
            [FLEXNavigationController withRootViewController:list
        ] animated:YES completion:nil];
    }
}


#pragma mark - View Selection

- (void)handleSelectionTap:(UITapGestureRecognizer *)tapGR {
    // Only if we're in selection mode
    if (self.currentMode == FLEXExplorerModeSelect && tapGR.state == UIGestureRecognizerStateRecognized) {
        // Note that [tapGR locationInView:nil] is broken in iOS 8,
        // so we have to do a two step conversion to window coordinates.
        // Thanks to @lascorbe for finding this: https://github.com/Flipboard/FLEX/pull/31
        CGPoint tapPointInView = [tapGR locationInView:self.view];
        CGPoint tapPointInWindow = [self.view convertPoint:tapPointInView toView:nil];
        [self updateOutlineViewsForSelectionPoint:tapPointInWindow];
    }
}

- (void)handleChangeViewAtPointGesture:(UIPanGestureRecognizer *)sender {
    NSInteger max = self.viewsAtTapPoint.count - 1;
    NSInteger currentIdx = [self.viewsAtTapPoint indexOfObject:self.selectedView];
    CGFloat locationX = [sender locationInView:self.view].x;
    
    // Track the pan gesture: every N points we move along the X axis,
    // actuate some haptic feedback and move up or down the hierarchy.
    // We only store the "last" location when we've met the threshold.
    // We only change the view and actuate feedback if the view selection
    // changes; that is, as long as we don't go outside or under the array.
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.selectedViewLastPanX = locationX;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            static CGFloat kNextLevelThreshold = 20.f;
            CGFloat lastX = self.selectedViewLastPanX;
            NSInteger newSelection = currentIdx;
            
            // Left, go down the hierarchy
            if (locationX < lastX && (lastX - locationX) >= kNextLevelThreshold) {
                // Choose a new view index up to the max index
                newSelection = MIN(max, currentIdx + 1);
                self.selectedViewLastPanX = locationX;
            }
            // Right, go up the hierarchy
            else if (lastX < locationX && (locationX - lastX) >= kNextLevelThreshold) {
                // Choose a new view index down to the min index
                newSelection = MAX(0, currentIdx - 1);
                self.selectedViewLastPanX = locationX;
            }
            
            if (currentIdx != newSelection) {
                self.selectedView = self.viewsAtTapPoint[newSelection];
                [self actuateSelectionChangedFeedback];
            }
            
            break;
        }
            
        default: break;
    }
}

- (void)actuateSelectionChangedFeedback {
    if (@available(iOS 10.0, *)) {
        [self.selectionFBG selectionChanged];
    }
}

- (void)updateOutlineViewsForSelectionPoint:(CGPoint)selectionPointInWindow {
    [self removeAndClearOutlineViews];
    
    // Include hidden views in the "viewsAtTapPoint" array so we can show them in the hierarchy list.
    self.viewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:NO];
    
    // For outlined views and the selected view, only use visible views.
    // Outlining hidden views adds clutter and makes the selection behavior confusing.
    NSArray<UIView *> *visibleViewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:YES];
    NSMutableDictionary<NSValue *, UIView *> *newOutlineViewsForVisibleViews = [NSMutableDictionary new];
    for (UIView *view in visibleViewsAtTapPoint) {
        UIView *outlineView = [self outlineViewForView:view];
        [self.view addSubview:outlineView];
        NSValue *key = [NSValue valueWithNonretainedObject:view];
        [newOutlineViewsForVisibleViews setObject:outlineView forKey:key];
    }
    self.outlineViewsForVisibleViews = newOutlineViewsForVisibleViews;
    self.selectedView = [self viewForSelectionAtPoint:selectionPointInWindow];
    
    // Make sure the explorer toolbar doesn't end up behind the newly added outline views.
    [self.view bringSubviewToFront:self.explorerToolbar];
    
    [self updateButtonStates];
}

- (UIView *)outlineViewForView:(UIView *)view {
    CGRect outlineFrame = [self frameInLocalCoordinatesForView:view];
    UIView *outlineView = [[UIView alloc] initWithFrame:outlineFrame];
    outlineView.backgroundColor = UIColor.clearColor;
    outlineView.layer.borderColor = [FLEXUtility consistentRandomColorForObject:view].CGColor;
    outlineView.layer.borderWidth = 1.0;
    return outlineView;
}

- (void)removeAndClearOutlineViews {
    for (NSValue *key in self.outlineViewsForVisibleViews) {
        UIView *outlineView = self.outlineViewsForVisibleViews[key];
        [outlineView removeFromSuperview];
    }
    self.outlineViewsForVisibleViews = nil;
}

- (NSArray<UIView *> *)viewsAtPoint:(CGPoint)tapPointInWindow skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *views = [NSMutableArray new];
    for (UIWindow *window in FLEXUtility.allWindows) {
        // Don't include the explorer's own window or subviews.
        if (window != self.view.window && [window pointInside:tapPointInWindow withEvent:nil]) {
            [views addObject:window];
            [views addObjectsFromArray:[self
                recursiveSubviewsAtPoint:tapPointInWindow inView:window skipHiddenViews:skipHidden
            ]];
        }
    }
    return views;
}

- (UIView *)viewForSelectionAtPoint:(CGPoint)tapPointInWindow {
    // Select in the window that would handle the touch, but don't just use the result of
    // hitTest:withEvent: so we can still select views with interaction disabled.
    // Default to the the application's key window if none of the windows want the touch.
    UIWindow *windowForSelection = UIApplication.sharedApplication.keyWindow;
    for (UIWindow *window in FLEXUtility.allWindows.reverseObjectEnumerator) {
        // Ignore the explorer's own window.
        if (window != self.view.window) {
            if ([window hitTest:tapPointInWindow withEvent:nil]) {
                windowForSelection = window;
                break;
            }
        }
    }
    
    // Select the deepest visible view at the tap point. This generally corresponds to what the user wants to select.
    return [self recursiveSubviewsAtPoint:tapPointInWindow inView:windowForSelection skipHiddenViews:YES].lastObject;
}

- (NSArray<UIView *> *)recursiveSubviewsAtPoint:(CGPoint)pointInView
                                         inView:(UIView *)view
                                skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *subviewsAtPoint = [NSMutableArray new];
    for (UIView *subview in view.subviews) {
        BOOL isHidden = subview.hidden || subview.alpha < 0.01;
        if (skipHidden && isHidden) {
            continue;
        }
        
        BOOL subviewContainsPoint = CGRectContainsPoint(subview.frame, pointInView);
        if (subviewContainsPoint) {
            [subviewsAtPoint addObject:subview];
        }
        
        // If this view doesn't clip to its bounds, we need to check its subviews even if it
        // doesn't contain the selection point. They may be visible and contain the selection point.
        if (subviewContainsPoint || !subview.clipsToBounds) {
            CGPoint pointInSubview = [view convertPoint:pointInView toView:subview];
            [subviewsAtPoint addObjectsFromArray:[self
                recursiveSubviewsAtPoint:pointInSubview inView:subview skipHiddenViews:skipHidden
            ]];
        }
    }
    return subviewsAtPoint;
}


#pragma mark - Selected View Moving

- (void)handleMovePan:(UIPanGestureRecognizer *)movePanGR {
    switch (movePanGR.state) {
        case UIGestureRecognizerStateBegan:
            self.selectedViewFrameBeforeDragging = self.selectedView.frame;
            [self updateSelectedViewPositionWithDragGesture:movePanGR];
            break;
            
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateSelectedViewPositionWithDragGesture:movePanGR];
            break;
            
        default:
            break;
    }
}

- (void)updateSelectedViewPositionWithDragGesture:(UIPanGestureRecognizer *)movePanGR {
    CGPoint translation = [movePanGR translationInView:self.selectedView.superview];
    CGRect newSelectedViewFrame = self.selectedViewFrameBeforeDragging;
    newSelectedViewFrame.origin.x = FLEXFloor(newSelectedViewFrame.origin.x + translation.x);
    newSelectedViewFrame.origin.y = FLEXFloor(newSelectedViewFrame.origin.y + translation.y);
    self.selectedView.frame = newSelectedViewFrame;
}


#pragma mark - Safe Area Handling

- (CGRect)viewSafeArea {
    CGRect safeArea = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        safeArea = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
    }

    return safeArea;
}

- (void)viewSafeAreaInsetsDidChange {
    if (@available(iOS 11.0, *)) {
        [super viewSafeAreaInsetsDidChange];

        CGRect safeArea = [self viewSafeArea];
        CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(
            CGRectGetWidth(self.view.bounds), CGRectGetHeight(safeArea)
        )];
        [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(
            CGRectGetMinX(self.explorerToolbar.frame),
            CGRectGetMinY(self.explorerToolbar.frame),
            toolbarSize.width,
            toolbarSize.height)
        ];
    }
}


#pragma mark - Touch Handling

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates {
    BOOL shouldReceiveTouch = NO;
    
    CGPoint pointInLocalCoordinates = [self.view convertPoint:pointInWindowCoordinates fromView:nil];
    
    // Always if it's on the toolbar
    if (CGRectContainsPoint(self.explorerToolbar.frame, pointInLocalCoordinates)) {
        shouldReceiveTouch = YES;
    }
    
    // Always if we're in selection mode
    if (!shouldReceiveTouch && self.currentMode == FLEXExplorerModeSelect) {
        shouldReceiveTouch = YES;
    }
    
    // Always in move mode too
    if (!shouldReceiveTouch && self.currentMode == FLEXExplorerModeMove) {
        shouldReceiveTouch = YES;
    }
    
    // Always if we have a modal presented
    if (!shouldReceiveTouch && self.presentedViewController) {
        shouldReceiveTouch = YES;
    }
    
    return shouldReceiveTouch;
}


#pragma mark - FLEXHierarchyDelegate

- (void)viewHierarchyDidDismiss:(UIView *)selectedView {
    // Note that we need to wait until the view controller is dismissed to calculate the frame
    // of the outline view, otherwise the coordinate conversion doesn't give the correct result.
    [self toggleViewsToolWithCompletion:^{
        // If the selected view is outside of the tap point array (selected from "Full Hierarchy"),
        // then clear out the tap point array and remove all the outline views.
        if (![self.viewsAtTapPoint containsObject:selectedView]) {
            self.viewsAtTapPoint = nil;
            [self removeAndClearOutlineViews];
        }
        
        // If we now have a selected view and we didn't have one previously, go to "select" mode.
        if (self.currentMode == FLEXExplorerModeDefault && selectedView) {
            self.currentMode = FLEXExplorerModeSelect;
        }
        
        // The selected view setter will also update the selected view overlay appropriately.
        self.selectedView = selectedView;
    }];
}


#pragma mark - Modal Presentation and Window Management

- (void)presentViewController:(UIViewController *)toPresent
                               animated:(BOOL)animated
                             completion:(void (^)(void))completion {
    // Make our window key to correctly handle input.
    [self.view.window makeKeyWindow];

    // Move the status bar on top of FLEX so we can get scroll to top behavior for taps.
    if (!@available(iOS 13, *)) {
        [self statusWindow].windowLevel = self.view.window.windowLevel + 1.0;
    }
    
    // Back up and replace the UIMenuController items
    // Edit: no longer replacing the items, but still backing them
    // up in case we start replacing them again in the future
    self.appMenuItems = UIMenuController.sharedMenuController.menuItems;
    
    // Show the view controller
    [super presentViewController:toPresent animated:animated completion:completion];
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {    
    UIWindow *appWindow = self.window.previousKeyWindow;
    [appWindow makeKeyWindow];
    [appWindow.rootViewController setNeedsStatusBarAppearanceUpdate];
    
    // Restore previous UIMenuController items
    // Back up and replace the UIMenuController items
    UIMenuController.sharedMenuController.menuItems = self.appMenuItems;
    [UIMenuController.sharedMenuController update];
    self.appMenuItems = nil;
    
    // Restore the status bar window's normal window level.
    // We want it above FLEX while a modal is presented for
    // scroll to top, but below FLEX otherwise for exploration.
    [self statusWindow].windowLevel = UIWindowLevelStatusBar;
    
    [self updateButtonStates];
    
    [super dismissViewControllerAnimated:animated completion:completion];
}

- (BOOL)wantsWindowToBecomeKey {
    return self.window.previousKeyWindow != nil;
}

- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion {
    if (self.presentedViewController) {
        // We do NOT want to present the future; this is
        // a convenience method for toggling the SAME TOOL
        [self dismissViewControllerAnimated:YES completion:completion];
    } else if (future) {
        [self presentViewController:future() animated:YES completion:completion];
    }
}

- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion {
    if (self.presentedViewController) {
        // If a tool is already presented, dismiss it first
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:future() animated:YES completion:completion];
        }];
    } else if (future) {
        [self presentViewController:future() animated:YES completion:completion];
    }
}

- (FLEXWindow *)window {
    return (id)self.view.window;
}


#pragma mark - Keyboard Shortcut Helpers

- (void)toggleSelectTool {
    if (self.currentMode == FLEXExplorerModeSelect) {
        self.currentMode = FLEXExplorerModeDefault;
    } else {
        self.currentMode = FLEXExplorerModeSelect;
    }
}

- (void)toggleMoveTool {
    if (self.currentMode == FLEXExplorerModeMove) {
        self.currentMode = FLEXExplorerModeSelect;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.selectedView) {
        self.currentMode = FLEXExplorerModeMove;
    }
}

- (void)toggleViewsTool {
    [self toggleViewsToolWithCompletion:nil];
}

- (void)toggleViewsToolWithCompletion:(void(^)(void))completion {
    [self toggleToolWithViewControllerProvider:^UINavigationController *{
        if (self.selectedView) {
            return [FLEXHierarchyViewController
                delegate:self
                viewsAtTap:self.viewsAtTapPoint
                selectedView:self.selectedView
            ];
        } else {
            return [FLEXHierarchyViewController delegate:self];
        }
    } completion:completion];
}

- (void)toggleMenuTool {
    [self toggleToolWithViewControllerProvider:^UINavigationController *{
        return [FLEXNavigationController withRootViewController:[FLEXGlobalsViewController new]];
    } completion:nil];
}

- (BOOL)handleDownArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y += 1.0 / UIScreen.mainScreen.scale;
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.viewsAtTapPoint.count > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex > 0) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex - 1];
        }
    } else {
        return NO;
    }
    
    return YES;
}

- (BOOL)handleUpArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y -= 1.0 / UIScreen.mainScreen.scale;
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.viewsAtTapPoint.count > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex < self.viewsAtTapPoint.count - 1) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex + 1];
        }
    } else {
        return NO;
    }
    
    return YES;
}

- (BOOL)handleRightArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x += 1.0 / UIScreen.mainScreen.scale;
        self.selectedView.frame = frame;
        return YES;
    }
    
    return NO;
}

- (BOOL)handleLeftArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x -= 1.0 / UIScreen.mainScreen.scale;
        self.selectedView.frame = frame;
        return YES;
    }
    
    return NO;
}

@end
