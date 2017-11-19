//
//  FLEXExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXExplorerViewController.h"
#import "FLEXExplorerToolbar.h"
#import "FLEXToolbarItem.h"
#import "FLEXUtility.h"
#import "FLEXHierarchyTableViewController.h"
#import "FLEXGlobalsTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkHistoryTableViewController.h"

static NSString *const kFLEXToolbarTopMarginDefaultsKey = @"com.flex.FLEXToolbar.topMargin";

typedef NS_ENUM(NSUInteger, FLEXExplorerMode) {
    FLEXExplorerModeDefault,
    FLEXExplorerModeSelect,
    FLEXExplorerModeMove
};

@interface FLEXExplorerViewController () <FLEXHierarchyTableViewControllerDelegate, FLEXGlobalsTableViewControllerDelegate>

@property (nonatomic, strong) FLEXExplorerToolbar *explorerToolbar;

/// Tracks the currently active tool/mode
@property (nonatomic, assign) FLEXExplorerMode currentMode;

/// Gesture recognizer for dragging a view in move mode
@property (nonatomic, strong) UIPanGestureRecognizer *movePanGR;

/// Gesture recognizer for showing additional details on the selected view
@property (nonatomic, strong) UITapGestureRecognizer *detailsTapGR;

/// Only valid while a move pan gesture is in progress.
@property (nonatomic, assign) CGRect selectedViewFrameBeforeDragging;

/// Only valid while a toolbar drag pan gesture is in progress.
@property (nonatomic, assign) CGRect toolbarFrameBeforeDragging;

/// Borders of all the visible views in the hierarchy at the selection point.
/// The keys are NSValues with the correponding view (nonretained).
@property (nonatomic, strong) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;

/// The actual views at the selection point with the deepest view last.
@property (nonatomic, strong) NSArray<UIView *> *viewsAtTapPoint;

/// The view that we're currently highlighting with an overlay and displaying details for.
@property (nonatomic, strong) UIView *selectedView;

/// A colored transparent overlay to indicate that the view is selected.
@property (nonatomic, strong) UIView *selectedViewOverlay;

/// Tracked so we can restore the key window after dismissing a modal.
/// We need to become key after modal presentation so we can correctly capture intput.
/// If we're just showing the toolbar, we want the main app's window to remain key so that we don't interfere with input, status bar, etc.
@property (nonatomic, strong) UIWindow *previousKeyWindow;

/// Similar to the previousKeyWindow property above, we need to track status bar styling if
/// the app doesn't use view controller based status bar management. When we present a modal,
/// we want to change the status bar style to UIStausBarStyleDefault. Before changing, we stash
/// the current style. On dismissal, we return the staus bar to the style that the app was using previously.
@property (nonatomic, assign) UIStatusBarStyle previousStatusBarStyle;

/// All views that we're KVOing. Used to help us clean up properly.
@property (nonatomic, strong) NSMutableSet<UIView *> *observedViews;

@end

@implementation FLEXExplorerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.observedViews = [NSMutableSet set];
    }
    return self;
}

-(void)dealloc
{
    for (UIView *view in _observedViews) {
        [self stopObservingView:view];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Toolbar
    self.explorerToolbar = [[FLEXExplorerToolbar alloc] init];

    // Start the toolbar off below any bars that may be at the top of the view.
    id toolbarOriginYDefault = [[NSUserDefaults standardUserDefaults] objectForKey:kFLEXToolbarTopMarginDefaultsKey];
    CGFloat toolbarOriginY = toolbarOriginYDefault ? [toolbarOriginYDefault doubleValue] : 100;

    CGRect safeArea = [self viewSafeArea];
    CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(safeArea))];
    [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(CGRectGetMinX(safeArea), toolbarOriginY, toolbarSize.width, toolbarSize.height)];
    self.explorerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.explorerToolbar];
    [self setupToolbarActions];
    [self setupToolbarGestures];
    
    // View selection
    UITapGestureRecognizer *selectionTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectionTap:)];
    [self.view addGestureRecognizer:selectionTapGR];
    
    // View moving
    self.movePanGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
    self.movePanGR.enabled = self.currentMode == FLEXExplorerModeMove;
    [self.view addGestureRecognizer:self.movePanGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateButtonStates];
}


#pragma mark - Rotation

- (UIViewController *)viewControllerForRotationAndOrientation
{
    UIWindow *window = self.previousKeyWindow ?: [[UIApplication sharedApplication] keyWindow];
    UIViewController *viewController = window.rootViewController;
    NSString *viewControllerSelectorString = [@[@"_vie", @"wContro", @"llerFor", @"Supported", @"Interface", @"Orientations"] componentsJoinedByString:@""];
    SEL viewControllerSelector = NSSelectorFromString(viewControllerSelectorString);
    if ([viewController respondsToSelector:viewControllerSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        viewController = [viewController performSelector:viewControllerSelector];
#pragma clang diagnostic pop
    }
    return viewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    UIInterfaceOrientationMask supportedOrientations = [FLEXUtility infoPlistSupportedInterfaceOrientationsMask];
    if (viewControllerToAsk && viewControllerToAsk != self) {
        supportedOrientations = [viewControllerToAsk supportedInterfaceOrientations];
    }
    
    // The UIViewController docs state that this method must not return zero.
    // If we weren't able to get a valid value for the supported interface orientations, default to all supported.
    if (supportedOrientations == 0) {
        supportedOrientations = UIInterfaceOrientationMaskAll;
    }
    
    return supportedOrientations;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    BOOL shouldAutorotate = YES;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        shouldAutorotate = [viewControllerToAsk shouldAutorotate];
    }
    return shouldAutorotate;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    for (UIView *outlineView in [self.outlineViewsForVisibleViews allValues]) {
        outlineView.hidden = YES;
    }
    self.selectedViewOverlay.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
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
}


#pragma mark - Setter Overrides

- (void)setSelectedView:(UIView *)selectedView
{
    if (![_selectedView isEqual:selectedView]) {
        if (![self.viewsAtTapPoint containsObject:_selectedView]) {
            [self stopObservingView:_selectedView];
        }
        
        _selectedView = selectedView;
        
        [self beginObservingView:selectedView];

        // Update the toolbar and selected overlay
        self.explorerToolbar.selectedViewDescription = [FLEXUtility descriptionForView:selectedView includingFrame:YES];
        self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility consistentRandomColorForObject:selectedView];

        if (selectedView) {
            if (!self.selectedViewOverlay) {
                self.selectedViewOverlay = [[UIView alloc] init];
                [self.view addSubview:self.selectedViewOverlay];
                self.selectedViewOverlay.layer.borderWidth = 1.0;
            }
            UIColor *outlineColor = [FLEXUtility consistentRandomColorForObject:selectedView];
            self.selectedViewOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
            self.selectedViewOverlay.layer.borderColor = [outlineColor CGColor];
            self.selectedViewOverlay.frame = [self.view convertRect:selectedView.bounds fromView:selectedView];
            
            // Make sure the selected overlay is in front of all the other subviews except the toolbar, which should always stay on top.
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

- (void)setViewsAtTapPoint:(NSArray<UIView *> *)viewsAtTapPoint
{
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

- (void)setCurrentMode:(FLEXExplorerMode)currentMode
{
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
                // Hide all the outline views to focus on the selected view, which is the only one that will move.
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

- (void)beginObservingView:(UIView *)view
{
    // Bail if we're already observing this view or if there's nothing to observe.
    if (!view || [self.observedViews containsObject:view]) {
        return;
    }
    
    for (NSString *keyPath in [[self class] viewKeyPathsToTrack]) {
        [view addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }
    
    [self.observedViews addObject:view];
}

- (void)stopObservingView:(UIView *)view
{
    if (!view) {
        return;
    }
    
    for (NSString *keyPath in [[self class] viewKeyPathsToTrack]) {
        [view removeObserver:self forKeyPath:keyPath];
    }
    
    [self.observedViews removeObject:view];
}

+ (NSArray<NSString *> *)viewKeyPathsToTrack
{
    static NSArray<NSString *> *trackedViewKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *frameKeyPath = NSStringFromSelector(@selector(frame));
        trackedViewKeyPaths = @[frameKeyPath];
    });
    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    [self updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:(id)object
{
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
        self.explorerToolbar.selectedViewDescription = [FLEXUtility descriptionForView:self.selectedView includingFrame:YES];
        CGRect selectedViewOutlineFrame = [self frameInLocalCoordinatesForView:self.selectedView];
        self.selectedViewOverlay.frame = selectedViewOutlineFrame;
    }
}

- (CGRect)frameInLocalCoordinatesForView:(UIView *)view
{
    // First convert to window coordinates since the view may be in a different window than our view.
    CGRect frameInWindow = [view convertRect:view.bounds toView:nil];
    // Then convert from the window to our view's coordinate space.
    return [self.view convertRect:frameInWindow fromView:nil];
}


#pragma mark - Toolbar Buttons

- (void)setupToolbarActions
{
    [self.explorerToolbar.selectItem addTarget:self action:@selector(selectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.explorerToolbar.hierarchyItem addTarget:self action:@selector(hierarchyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.explorerToolbar.moveItem addTarget:self action:@selector(moveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.explorerToolbar.globalsItem addTarget:self action:@selector(globalsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.explorerToolbar.closeItem addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)selectButtonTapped:(FLEXToolbarItem *)sender
{
    [self toggleSelectTool];
}

- (void)hierarchyButtonTapped:(FLEXToolbarItem *)sender
{
    [self toggleViewsTool];
}

- (NSArray<UIView *> *)allViewsInHierarchy
{
    NSMutableArray<UIView *> *allViews = [NSMutableArray array];
    NSArray<UIWindow *> *windows = [FLEXUtility allWindows];
    for (UIWindow *window in windows) {
        if (window != self.view.window) {
            [allViews addObject:window];
            [allViews addObjectsFromArray:[self allRecursiveSubviewsInView:window]];
        }
    }
    return allViews;
}

- (UIWindow *)statusWindow
{
    NSString *statusBarString = [NSString stringWithFormat:@"%@arWindow", @"_statusB"];
    return [[UIApplication sharedApplication] valueForKey:statusBarString];
}

- (void)moveButtonTapped:(FLEXToolbarItem *)sender
{
    [self toggleMoveTool];
}

- (void)globalsButtonTapped:(FLEXToolbarItem *)sender
{
    [self toggleMenuTool];
}

- (void)closeButtonTapped:(FLEXToolbarItem *)sender
{
    self.currentMode = FLEXExplorerModeDefault;
    [self.delegate explorerViewControllerDidFinish:self];
}

- (void)updateButtonStates
{
    // Move and details only active when an object is selected.
    BOOL hasSelectedObject = self.selectedView != nil;
    self.explorerToolbar.moveItem.enabled = hasSelectedObject;
    self.explorerToolbar.selectItem.selected = self.currentMode == FLEXExplorerModeSelect;
    self.explorerToolbar.moveItem.selected = self.currentMode == FLEXExplorerModeMove;
}


#pragma mark - Toolbar Dragging

- (void)setupToolbarGestures
{
    // Pan gesture for dragging.
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolbarPanGesture:)];
    [self.explorerToolbar.dragHandle addGestureRecognizer:panGR];
    
    // Tap gesture for hinting.
    UITapGestureRecognizer *hintTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolbarHintTapGesture:)];
    [self.explorerToolbar.dragHandle addGestureRecognizer:hintTapGR];
    
    // Tap gesture for showing additional details
    self.detailsTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleToolbarDetailsTapGesture:)];
    [self.explorerToolbar.selectedViewDescriptionContainer addGestureRecognizer:self.detailsTapGR];
}

- (void)handleToolbarPanGesture:(UIPanGestureRecognizer *)panGR
{
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan:
            self.toolbarFrameBeforeDragging = self.explorerToolbar.frame;
            [self updateToolbarPostionWithDragGesture:panGR];
            break;
            
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateToolbarPostionWithDragGesture:panGR];
            break;
            
        default:
            break;
    }
}

- (void)updateToolbarPostionWithDragGesture:(UIPanGestureRecognizer *)panGR
{
    CGPoint translation = [panGR translationInView:self.view];
    CGRect newToolbarFrame = self.toolbarFrameBeforeDragging;
    newToolbarFrame.origin.y += translation.y;
    
    [self updateToolbarPositionWithUnconstrainedFrame:newToolbarFrame];
}

- (void)updateToolbarPositionWithUnconstrainedFrame:(CGRect)unconstrainedFrame
{
    CGRect safeArea = [self viewSafeArea];
    // We only constrain the Y-axis because We want the toolbar to handle the X-axis safeArea layout by itself
    CGFloat minY = CGRectGetMinY(safeArea);
    CGFloat maxY = CGRectGetMaxY(safeArea) - unconstrainedFrame.size.height;
    if (unconstrainedFrame.origin.y < minY) {
        unconstrainedFrame.origin.y = minY;
    } else if (unconstrainedFrame.origin.y > maxY) {
        unconstrainedFrame.origin.y = maxY;
    }

    self.explorerToolbar.frame = unconstrainedFrame;

    [[NSUserDefaults standardUserDefaults] setDouble:unconstrainedFrame.origin.y forKey:kFLEXToolbarTopMarginDefaultsKey];
}

- (void)handleToolbarHintTapGesture:(UITapGestureRecognizer *)tapGR
{
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

- (void)handleToolbarDetailsTapGesture:(UITapGestureRecognizer *)tapGR
{
    if (tapGR.state == UIGestureRecognizerStateRecognized && self.selectedView) {
        FLEXObjectExplorerViewController *selectedViewExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.selectedView];
        selectedViewExplorer.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(selectedViewExplorerFinished:)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:selectedViewExplorer];
        [self makeKeyAndPresentViewController:navigationController animated:YES completion:nil];
    }
}


#pragma mark - View Selection

- (void)handleSelectionTap:(UITapGestureRecognizer *)tapGR
{
    // Only if we're in selection mode
    if (self.currentMode == FLEXExplorerModeSelect && tapGR.state == UIGestureRecognizerStateRecognized) {
        // Note that [tapGR locationInView:nil] is broken in iOS 8, so we have to do a two step conversion to window coordinates.
        // Thanks to @lascorbe for finding this: https://github.com/Flipboard/FLEX/pull/31
        CGPoint tapPointInView = [tapGR locationInView:self.view];
        CGPoint tapPointInWindow = [self.view convertPoint:tapPointInView toView:nil];
        [self updateOutlineViewsForSelectionPoint:tapPointInWindow];
    }
}

- (void)updateOutlineViewsForSelectionPoint:(CGPoint)selectionPointInWindow
{
    [self removeAndClearOutlineViews];
    
    // Include hidden views in the "viewsAtTapPoint" array so we can show them in the hierarchy list.
    self.viewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:NO];
    
    // For outlined views and the selected view, only use visible views.
    // Outlining hidden views adds clutter and makes the selection behavior confusing.
    NSArray<UIView *> *visibleViewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:YES];
    NSMutableDictionary<NSValue *, UIView *> *newOutlineViewsForVisibleViews = [NSMutableDictionary dictionary];
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

- (UIView *)outlineViewForView:(UIView *)view
{
    CGRect outlineFrame = [self frameInLocalCoordinatesForView:view];
    UIView *outlineView = [[UIView alloc] initWithFrame:outlineFrame];
    outlineView.backgroundColor = [UIColor clearColor];
    outlineView.layer.borderColor = [[FLEXUtility consistentRandomColorForObject:view] CGColor];
    outlineView.layer.borderWidth = 1.0;
    return outlineView;
}

- (void)removeAndClearOutlineViews
{
    for (NSValue *key in self.outlineViewsForVisibleViews) {
        UIView *outlineView = self.outlineViewsForVisibleViews[key];
        [outlineView removeFromSuperview];
    }
    self.outlineViewsForVisibleViews = nil;
}

- (NSArray<UIView *> *)viewsAtPoint:(CGPoint)tapPointInWindow skipHiddenViews:(BOOL)skipHidden
{
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIWindow *window in [FLEXUtility allWindows]) {
        // Don't include the explorer's own window or subviews.
        if (window != self.view.window && [window pointInside:tapPointInWindow withEvent:nil]) {
            [views addObject:window];
            [views addObjectsFromArray:[self recursiveSubviewsAtPoint:tapPointInWindow inView:window skipHiddenViews:skipHidden]];
        }
    }
    return views;
}

- (UIView *)viewForSelectionAtPoint:(CGPoint)tapPointInWindow
{
    // Select in the window that would handle the touch, but don't just use the result of hitTest:withEvent: so we can still select views with interaction disabled.
    // Default to the the application's key window if none of the windows want the touch.
    UIWindow *windowForSelection = [[UIApplication sharedApplication] keyWindow];
    for (UIWindow *window in [[FLEXUtility allWindows] reverseObjectEnumerator]) {
        // Ignore the explorer's own window.
        if (window != self.view.window) {
            if ([window hitTest:tapPointInWindow withEvent:nil]) {
                windowForSelection = window;
                break;
            }
        }
    }
    
    // Select the deepest visible view at the tap point. This generally corresponds to what the user wants to select.
    return [[self recursiveSubviewsAtPoint:tapPointInWindow inView:windowForSelection skipHiddenViews:YES] lastObject];
}

- (NSArray<UIView *> *)recursiveSubviewsAtPoint:(CGPoint)pointInView inView:(UIView *)view skipHiddenViews:(BOOL)skipHidden
{
    NSMutableArray<UIView *> *subviewsAtPoint = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
        BOOL isHidden = subview.hidden || subview.alpha < 0.01;
        if (skipHidden && isHidden) {
            continue;
        }
        
        BOOL subviewContainsPoint = CGRectContainsPoint(subview.frame, pointInView);
        if (subviewContainsPoint) {
            [subviewsAtPoint addObject:subview];
        }
        
        // If this view doesn't clip to its bounds, we need to check its subviews even if it doesn't contain the selection point.
        // They may be visible and contain the selection point.
        if (subviewContainsPoint || !subview.clipsToBounds) {
            CGPoint pointInSubview = [view convertPoint:pointInView toView:subview];
            [subviewsAtPoint addObjectsFromArray:[self recursiveSubviewsAtPoint:pointInSubview inView:subview skipHiddenViews:skipHidden]];
        }
    }
    return subviewsAtPoint;
}

- (NSArray<UIView *> *)allRecursiveSubviewsInView:(UIView *)view
{
    NSMutableArray<UIView *> *subviews = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
        [subviews addObject:subview];
        [subviews addObjectsFromArray:[self allRecursiveSubviewsInView:subview]];
    }
    return subviews;
}

- (NSDictionary<NSValue *, NSNumber *> *)hierarchyDepthsForViews:(NSArray<UIView *> *)views
{
    NSMutableDictionary<NSValue *, NSNumber *> *hierarchyDepths = [NSMutableDictionary dictionary];
    for (UIView *view in views) {
        NSInteger depth = 0;
        UIView *tryView = view;
        while (tryView.superview) {
            tryView = tryView.superview;
            depth++;
        }
        [hierarchyDepths setObject:@(depth) forKey:[NSValue valueWithNonretainedObject:view]];
    }
    return hierarchyDepths;
}


#pragma mark - Selected View Moving

- (void)handleMovePan:(UIPanGestureRecognizer *)movePanGR
{
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

- (void)updateSelectedViewPositionWithDragGesture:(UIPanGestureRecognizer *)movePanGR
{
    CGPoint translation = [movePanGR translationInView:self.selectedView.superview];
    CGRect newSelectedViewFrame = self.selectedViewFrameBeforeDragging;
    newSelectedViewFrame.origin.x = FLEXFloor(newSelectedViewFrame.origin.x + translation.x);
    newSelectedViewFrame.origin.y = FLEXFloor(newSelectedViewFrame.origin.y + translation.y);
    self.selectedView.frame = newSelectedViewFrame;
}


#pragma mark - Safe Area Handling

- (CGRect)viewSafeArea
{
    CGRect safeArea = self.view.bounds;
#if FLEX_AT_LEAST_IOS11_SDK
    if (@available(iOS 11, *)) {
        safeArea = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
    }
#endif
    return safeArea;
}

#if FLEX_AT_LEAST_IOS11_SDK
- (void)viewSafeAreaInsetsDidChange
{
  if (@available(iOS 11, *)) {
    [super viewSafeAreaInsetsDidChange];
  }

  CGRect safeArea = [self viewSafeArea];
  CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(safeArea))];
  [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(CGRectGetMinX(self.explorerToolbar.frame), CGRectGetMinY(self.explorerToolbar.frame), toolbarSize.width, toolbarSize.height)];
}
#endif


#pragma mark - Touch Handling

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates
{
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


#pragma mark - FLEXHierarchyTableViewControllerDelegate

- (void)hierarchyViewController:(FLEXHierarchyTableViewController *)hierarchyViewController didFinishWithSelectedView:(UIView *)selectedView
{
    // Note that we need to wait until the view controller is dismissed to calculated the frame of the outline view.
    // Otherwise the coordinate conversion doesn't give the correct result.
    [self resignKeyAndDismissViewControllerAnimated:YES completion:^{
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


#pragma mark - FLEXGlobalsViewControllerDelegate

- (void)globalsViewControllerDidFinish:(FLEXGlobalsTableViewController *)globalsViewController
{
    [self resignKeyAndDismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - FLEXObjectExplorerViewController Done Action

- (void)selectedViewExplorerFinished:(id)sender
{
    [self resignKeyAndDismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Modal Presentation and Window Management

- (void)makeKeyAndPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    // Save the current key window so we can restore it following dismissal.
    self.previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
    
    // Make our window key to correctly handle input.
    [self.view.window makeKeyWindow];
    
    // Move the status bar on top of FLEX so we can get scroll to top behavior for taps.
    [[self statusWindow] setWindowLevel:self.view.window.windowLevel + 1.0];
    
    // If this app doesn't use view controller based status bar management and we're on iOS 7+,
    // make sure the status bar style is UIStatusBarStyleDefault. We don't actully have to check
    // for view controller based management because the global methods no-op if that is turned on.
    self.previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    // Show the view controller.
    [self presentViewController:viewController animated:animated completion:completion];
}

- (void)resignKeyAndDismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIWindow *previousKeyWindow = self.previousKeyWindow;
    self.previousKeyWindow = nil;
    [previousKeyWindow makeKeyWindow];
    [[previousKeyWindow rootViewController] setNeedsStatusBarAppearanceUpdate];
    
    // Restore the status bar window's normal window level.
    // We want it above FLEX while a modal is presented for scroll to top, but below FLEX otherwise for exploration.
    [[self statusWindow] setWindowLevel:UIWindowLevelStatusBar];
    
    // Restore the stauts bar style if the app is using global status bar management.
    [[UIApplication sharedApplication] setStatusBarStyle:self.previousStatusBarStyle];
    
    [self dismissViewControllerAnimated:animated completion:completion];
}

- (BOOL)wantsWindowToBecomeKey
{
    return self.previousKeyWindow != nil;
}

#pragma mark - Keyboard Shortcut Helpers

- (void)toggleSelectTool
{
    if (self.currentMode == FLEXExplorerModeSelect) {
        self.currentMode = FLEXExplorerModeDefault;
    } else {
        self.currentMode = FLEXExplorerModeSelect;
    }
}

- (void)toggleMoveTool
{
    if (self.currentMode == FLEXExplorerModeMove) {
        self.currentMode = FLEXExplorerModeDefault;
    } else {
        self.currentMode = FLEXExplorerModeMove;
    }
}

- (void)toggleViewsTool
{
    BOOL viewsModalShown = [[self presentedViewController] isKindOfClass:[UINavigationController class]];
    viewsModalShown = viewsModalShown && [[[(UINavigationController *)[self presentedViewController] viewControllers] firstObject] isKindOfClass:[FLEXHierarchyTableViewController class]];
    if (viewsModalShown) {
        [self resignKeyAndDismissViewControllerAnimated:YES completion:nil];
    } else {
        void (^presentBlock)(void) = ^{
            NSArray<UIView *> *allViews = [self allViewsInHierarchy];
            NSDictionary<NSValue *, NSNumber *> *depthsForViews = [self hierarchyDepthsForViews:allViews];
            FLEXHierarchyTableViewController *hierarchyTVC = [[FLEXHierarchyTableViewController alloc] initWithViews:allViews viewsAtTap:self.viewsAtTapPoint selectedView:self.selectedView depths:depthsForViews];
            hierarchyTVC.delegate = self;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:hierarchyTVC];
            [self makeKeyAndPresentViewController:navigationController animated:YES completion:nil];
        };
        
        if (self.presentedViewController) {
            [self resignKeyAndDismissViewControllerAnimated:NO completion:presentBlock];
        } else {
            presentBlock();
        }
    }
}

- (void)toggleMenuTool
{
    BOOL menuModalShown = [[self presentedViewController] isKindOfClass:[UINavigationController class]];
    menuModalShown = menuModalShown && [[[(UINavigationController *)[self presentedViewController] viewControllers] firstObject] isKindOfClass:[FLEXGlobalsTableViewController class]];
    if (menuModalShown) {
        [self resignKeyAndDismissViewControllerAnimated:YES completion:nil];
    } else {
        void (^presentBlock)(void) = ^{
            FLEXGlobalsTableViewController *globalsViewController = [[FLEXGlobalsTableViewController alloc] init];
            globalsViewController.delegate = self;
            [FLEXGlobalsTableViewController setApplicationWindow:[[UIApplication sharedApplication] keyWindow]];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:globalsViewController];
            [self makeKeyAndPresentViewController:navigationController animated:YES completion:nil];
        };
        
        if (self.presentedViewController) {
            [self resignKeyAndDismissViewControllerAnimated:NO completion:presentBlock];
        } else {
            presentBlock();
        }
    }
}

- (void)handleDownArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y += 1.0 / [[UIScreen mainScreen] scale];
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && [self.viewsAtTapPoint count] > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex > 0) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex - 1];
        }
    }
}

- (void)handleUpArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y -= 1.0 / [[UIScreen mainScreen] scale];
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && [self.viewsAtTapPoint count] > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex < [self.viewsAtTapPoint count] - 1) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex + 1];
        }
    }
}

- (void)handleRightArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x += 1.0 / [[UIScreen mainScreen] scale];
        self.selectedView.frame = frame;
    }
}

- (void)handleLeftArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x -= 1.0 / [[UIScreen mainScreen] scale];
        self.selectedView.frame = frame;
    }
}

@end
