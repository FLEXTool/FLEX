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
#import "FLEXElement.h"
#import "FLEXHierarchyTableViewController.h"
#import "FLEXGlobalsTableViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkHistoryTableViewController.h"

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
@property (nonatomic, assign) CGRect selectedElementFrameBeforeDragging;

/// Only valid while a toolbar drag pan gesture is in progress.
@property (nonatomic, assign) CGRect toolbarFrameBeforeDragging;

/// Borders of all the visible views in the hierarchy at the selection point.
/// The keys are NSValues with the correponding view (nonretained).
@property (nonatomic, strong) NSDictionary *outlineViewsForVisibleElements;

/// The actual views at the selection point with the deepest view last.
@property (nonatomic, strong) NSArray<FLEXElement *> *elementsAtTapPoint;

/// The view that we're currently highlighting with an overlay and displaying details for.
@property (nonatomic, strong) FLEXElement *selectedElement;

/// A colored transparent overlay to indicate that the view is selected.
@property (nonatomic, strong) UIView *selectedElementOverlay;

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
@property (nonatomic, strong) NSMutableSet *observedViews;

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
    for (FLEXElement *element in _observedViews) {
        [self stopObservingElement:element];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Toolbar
    self.explorerToolbar = [[FLEXExplorerToolbar alloc] init];
    CGSize toolbarSize = [self.explorerToolbar sizeThatFits:self.view.bounds.size];
    // Start the toolbar off below any bars that may be at the top of the view.
    CGFloat toolbarOriginY = 100.0;
    self.explorerToolbar.frame = CGRectMake(0.0, toolbarOriginY, toolbarSize.width, toolbarSize.height);
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
    for (UIView *outlineView in [self.outlineViewsForVisibleElements allValues]) {
        outlineView.hidden = YES;
    }
    self.selectedElementOverlay.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    for (FLEXElement *element in self.elementsAtTapPoint) {
        NSValue *key = [NSValue valueWithNonretainedObject:element];
        UIView *outlineView = self.outlineViewsForVisibleElements[key];
        outlineView.frame = [self frameInLocalCoordinatesForElement:element];
        if (self.currentMode == FLEXExplorerModeSelect) {
            outlineView.hidden = NO;
        }
    }
    
    if (self.selectedElement) {
        self.selectedElementOverlay.frame = [self frameInLocalCoordinatesForElement:self.selectedElement];
        self.selectedElementOverlay.hidden = NO;
    }
}

#pragma mark - Setter Overrides

- (void)setSelectedElement:(FLEXElement *)selectedElement
{
    if (![_selectedElement isEqual:selectedElement]) {
        if (![self.elementsAtTapPoint containsObject:_selectedElement]) {
            [self stopObservingElement:_selectedElement];
        }
        
        _selectedElement = selectedElement;
        
        [self beginObservingElement:selectedElement];

        // Update the toolbar and selected overlay
        self.explorerToolbar.selectedItemDescription = [selectedElement descriptionIncludingFrame:YES];
        self.explorerToolbar.selectedItemOverlayColor = selectedElement.color;

        if (selectedElement) {
            if (!self.selectedElementOverlay) {
                self.selectedElementOverlay = [[UIView alloc] init];
                [self.view addSubview:self.selectedElementOverlay];
                self.selectedElementOverlay.layer.borderWidth = 1.0;
            }
            UIColor *outlineColor = selectedElement.color;
            self.selectedElementOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
            self.selectedElementOverlay.layer.borderColor = [outlineColor CGColor];
            
            CGRect overlayFrame = CGRectZero;
            if (selectedElement.isLayerBacked) {
                overlayFrame = [self.view.layer convertRect:selectedElement.bounds fromLayer:selectedElement.layer];
            } else {
                overlayFrame = [self.view convertRect:selectedElement.bounds fromView:selectedElement.view];
            }
            self.selectedElementOverlay.frame = overlayFrame;
            
            // Make sure the selected overlay is in front of all the other subviews except the toolbar, which should always stay on top.
            [self.view bringSubviewToFront:self.selectedElementOverlay];
            [self.view bringSubviewToFront:self.explorerToolbar];
        } else {
            [self.selectedElementOverlay removeFromSuperview];
            self.selectedElementOverlay = nil;
        }
        
        // Some of the button states depend on whether we have a selected view.
        [self updateButtonStates];
    }
}

- (void)setElementsAtTapPoint:(NSArray *)elementsAtTapPoint
{
    if (![_elementsAtTapPoint isEqual:elementsAtTapPoint]) {
        for (FLEXElement *element in _elementsAtTapPoint) {
            if (element != self.selectedElement) {
                [self stopObservingElement:element];
            }
        }
        
        _elementsAtTapPoint = elementsAtTapPoint;
        
        for (FLEXElement *element in elementsAtTapPoint) {
            [self beginObservingElement:element];
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
                self.elementsAtTapPoint = nil;
                self.selectedElement = nil;
                break;
                
            case FLEXExplorerModeSelect:
                // Make sure the outline views are unhidden in case we came from the move mode.
                for (id key in self.outlineViewsForVisibleElements) {
                    UIView *outlineView = self.outlineViewsForVisibleElements[key];
                    outlineView.hidden = NO;
                }
                break;
                
            case FLEXExplorerModeMove:
                // Hide all the outline views to focus on the selected view, which is the only one that will move.
                for (id key in self.outlineViewsForVisibleElements) {
                    UIView *outlineView = self.outlineViewsForVisibleElements[key];
                    outlineView.hidden = YES;
                }
                break;
        }
        self.movePanGR.enabled = currentMode == FLEXExplorerModeMove;
        [self updateButtonStates];
    }
}


#pragma mark - View Tracking

- (void)beginObservingElement:(FLEXElement *)element
{
    // Bail if we're already observing this view or if there's nothing to observe.
    if (!element || element.isLayerBacked || [self.observedViews containsObject:element.view]) {
        return;
    }
    
    for (NSString *keyPath in [[self class] viewKeyPathsToTrack]) {
        [element.view addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }
    
    [self.observedViews addObject:element.view];
}

- (void)stopObservingElement:(FLEXElement *)element
{
    if (!element || element.isLayerBacked) {
        return;
    }
    
    for (NSString *keyPath in [[self class] viewKeyPathsToTrack]) {
        [element.view removeObserver:self forKeyPath:keyPath];
    }
    
    [self.observedViews removeObject:element];
}

+ (NSArray *)viewKeyPathsToTrack
{
    static NSArray *trackedViewKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *frameKeyPath = NSStringFromSelector(@selector(frame));
        trackedViewKeyPaths = @[frameKeyPath];
    });
    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:(id)object
{
    NSUInteger indexOfElement = NSNotFound;
    for (NSUInteger i = 0; i < self.elementsAtTapPoint.count; i++) {
        FLEXElement *element = self.elementsAtTapPoint[i];
        if (element.layerOrView == object) {
            indexOfElement = i;
            break;
        }
    }
    
    if (indexOfElement != NSNotFound) {
        FLEXElement *element = self.elementsAtTapPoint[indexOfElement];
        NSValue *key = [NSValue valueWithNonretainedObject:element];
        UIView *outline = self.outlineViewsForVisibleElements[key];
        if (outline) {
            outline.frame = [self frameInLocalCoordinatesForElement:element];
        }
    }
    if (object == self.selectedElement.layerOrView) {
        // Update the selected view description since we show the frame value there.
        self.explorerToolbar.selectedItemDescription = [self.selectedElement descriptionIncludingFrame:YES];
        CGRect selectedElementOutlineFrame = [self frameInLocalCoordinatesForElement:self.selectedElement];
        self.selectedElementOverlay.frame = selectedElementOutlineFrame;
    }
}

- (CGRect)frameInLocalCoordinatesForElement:(FLEXElement *)element
{
    CGRect frameInWindow = CGRectZero;
    // First convert to window coordinates since the view may be in a different window than our view.
    if (element.isLayerBacked) {
        frameInWindow = [element.layer convertRect:element.bounds toLayer:nil];
    } else {
        frameInWindow = [element.view convertRect:element.bounds toView:nil];
    }
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

- (NSArray *)allElementsInHierarchy
{
    NSMutableArray<FLEXElement *> *allElements = [NSMutableArray array];
    NSArray *windows = [FLEXUtility allWindows];
    for (UIWindow *window in windows) {
        if (window != self.view.window) {
            FLEXElement *windowElement = [[FLEXElement alloc] initWithObject:window type:FLEXElementTypeView];
            [allElements addObject:windowElement];
            [allElements addObjectsFromArray:[self allRecursiveChildrenInElement:windowElement]];
        }
    }
    return allElements;
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
    self.explorerToolbar.moveItem.enabled = [self shouldEnableMoveItem];
    self.explorerToolbar.selectItem.selected = self.currentMode == FLEXExplorerModeSelect;
    self.explorerToolbar.moveItem.selected = self.currentMode == FLEXExplorerModeMove;
}

- (BOOL)shouldEnableMoveItem
{
    // Move and details only active when an object is selected and a view
    return self.selectedElement != nil && self.selectedElement.isLayerBacked == NO;
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
    [self.explorerToolbar.selectedItemDescriptionContainer addGestureRecognizer:self.detailsTapGR];
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
    
    CGFloat maxY = CGRectGetMaxY(self.view.bounds) - newToolbarFrame.size.height;
    if (newToolbarFrame.origin.y < 0.0) {
        newToolbarFrame.origin.y = 0.0;
    } else if (newToolbarFrame.origin.y > maxY) {
        newToolbarFrame.origin.y = maxY;
    }
    
    self.explorerToolbar.frame = newToolbarFrame;
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
    if (tapGR.state == UIGestureRecognizerStateRecognized && self.selectedElement) {
        FLEXObjectExplorerViewController *selectedElementExplorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.selectedElement];
        selectedElementExplorer.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(selectedElementExplorerFinished:)];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:selectedElementExplorer];
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
    
    // Include hidden views in the "elementsAtTapPoint" array so we can show them in the hierarchy list.
    self.elementsAtTapPoint = [self elementsAtPoint:selectionPointInWindow skipHiddenElements:NO];
    
    // For outlined views and the selected view, only use visible views.
    // Outlining hidden views adds clutter and makes the selection behavior confusing.
    NSArray *visibleElementsAtTapPoint = [self elementsAtPoint:selectionPointInWindow skipHiddenElements:YES];
    NSMutableDictionary *newOutlineViewsForVisibleViews = [NSMutableDictionary dictionary];
    for (FLEXElement *element in visibleElementsAtTapPoint) {
        UIView *outlineView = [self outlineViewForElement:element];
        [self.view addSubview:outlineView];
        NSValue *key = [NSValue valueWithNonretainedObject:element];
        [newOutlineViewsForVisibleViews setObject:outlineView forKey:key];
    }
    self.outlineViewsForVisibleElements = newOutlineViewsForVisibleViews;
    self.selectedElement = [self elementForSelectionAtPoint:selectionPointInWindow];
    
    // Make sure the explorer toolbar doesn't end up behind the newly added outline views.
    [self.view bringSubviewToFront:self.explorerToolbar];
    
    [self updateButtonStates];
}

- (UIView *)outlineViewForElement:(FLEXElement *)element
{
    CGRect outlineFrame = [self frameInLocalCoordinatesForElement:element];
    UIView *outlineView = [[UIView alloc] initWithFrame:outlineFrame];
    outlineView.backgroundColor = [UIColor clearColor];
    outlineView.layer.borderColor = [element.color CGColor];
    outlineView.layer.borderWidth = 1.0;
    return outlineView;
}

- (void)removeAndClearOutlineViews
{
    for (id key in self.outlineViewsForVisibleElements) {
        UIView *outlineView = self.outlineViewsForVisibleElements[key];
        [outlineView removeFromSuperview];
    }
    self.outlineViewsForVisibleElements = nil;
}

- (NSArray *)elementsAtPoint:(CGPoint)tapPointInWindow skipHiddenElements:(BOOL)skipHidden
{
    NSMutableArray *elements = [NSMutableArray array];
    for (UIWindow *window in [FLEXUtility allWindows]) {
        // Don't include the explorer's own window or subviews.
        if (window != self.view.window && [window pointInside:tapPointInWindow withEvent:nil]) {
            FLEXElement *windowElement = [[FLEXElement alloc] initWithObject:window type:FLEXElementTypeView];
            [elements addObject:windowElement];
            [elements addObjectsFromArray:[self recursiveSubelementsAtPoint:tapPointInWindow inElement:windowElement skipHiddenElements:skipHidden]];
        }
    }
    return elements;
}

- (FLEXElement *)elementForSelectionAtPoint:(CGPoint)tapPointInWindow
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
    FLEXElement *windowElement = [[FLEXElement alloc] initWithObject:windowForSelection type:FLEXElementTypeView];
    return [[self recursiveSubelementsAtPoint:tapPointInWindow inElement:windowElement skipHiddenElements:YES] lastObject];
}

- (NSArray *)recursiveSubelementsAtPoint:(CGPoint)pointInView inElement:(FLEXElement *)element skipHiddenElements:(BOOL)skipHidden
{
    NSMutableArray *elementsAtPoint = [NSMutableArray array];
    for (FLEXElement *subelement in element.subelements) {
        if (skipHidden && subelement.isInvisible) {
            continue;
        }
        
        BOOL subviewContainsPoint = CGRectContainsPoint(subelement.frame, pointInView);
        if (subviewContainsPoint) {
            [elementsAtPoint addObject:subelement];
        }
        
        // If this view doesn't clip to its bounds, we need to check its subviews even if it doesn't contain the selection point.
        // They may be visible and contain the selection point.
        if (subviewContainsPoint || !subelement.clipsToBounds) {
            CGPoint pointInSubelement = [element convertPoint:pointInView toElement:subelement];
            [elementsAtPoint addObjectsFromArray:[self recursiveSubelementsAtPoint:pointInSubelement inElement:subelement skipHiddenElements:skipHidden]];
        }
    }
    return elementsAtPoint;
}

- (NSArray *)allRecursiveChildrenInElement:(FLEXElement *)element
{
    NSMutableArray *children = [NSMutableArray array];
    for (FLEXElement *subElement in element.subelements) {
        [children addObject:subElement];
        [children addObjectsFromArray:[self allRecursiveChildrenInElement:subElement]];
    }
    return children;
}

- (NSDictionary *)hierarchyDepthsForElementObjects:(NSArray *)elements
{
    NSMutableDictionary *hierarchyDepths = [NSMutableDictionary dictionary];
    for (FLEXElement *element in elements) {
        NSInteger depth = 0;
        FLEXElement *tryElement = element;
        FLEXElement *parent = nil;
        while ((parent = tryElement.parent) != nil) {
            tryElement = parent;
            depth++;
        }
        [hierarchyDepths setObject:@(depth) forKey:[NSValue valueWithNonretainedObject:element.object]];
    }
    return hierarchyDepths;
}


#pragma mark - Selected View Moving

- (void)handleMovePan:(UIPanGestureRecognizer *)movePanGR
{
    switch (movePanGR.state) {
        case UIGestureRecognizerStateBegan:
            self.selectedElementFrameBeforeDragging = self.selectedElement.frame;
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
    CGPoint translation = [movePanGR translationInView:self.selectedElement.view.superview];
    CGRect newSelectedViewFrame = self.selectedElementFrameBeforeDragging;
    newSelectedViewFrame.origin.x = FLEXFloor(newSelectedViewFrame.origin.x + translation.x);
    newSelectedViewFrame.origin.y = FLEXFloor(newSelectedViewFrame.origin.y + translation.y);
    self.selectedElement.frame = newSelectedViewFrame;
}


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

- (void)hierarchyViewController:(FLEXHierarchyTableViewController *)hierarchyViewController didFinishWithSelectedElement:(FLEXElement *)selectedElement
{
    // Note that we need to wait until the view controller is dismissed to calculated the frame of the outline view.
    // Otherwise the coordinate conversion doesn't give the correct result.
    [self resignKeyAndDismissViewControllerAnimated:YES completion:^{
        // If the selected view is outside of the tap point array (selected from "Full Hierarchy"),
        // then clear out the tap point array and remove all the outline views.
        if (![self.elementsAtTapPoint containsObject:selectedElement]) {
            self.elementsAtTapPoint = nil;
            [self removeAndClearOutlineViews];
        }
        
        // If we now have a selected view and we didn't have one previously, go to "select" mode.
        if (self.currentMode == FLEXExplorerModeDefault && selectedElement) {
            self.currentMode = FLEXExplorerModeSelect;
        }
        
        // The selected view setter will also update the selected view overlay appropriately.
        self.selectedElement = selectedElement;
    }];
}


#pragma mark - FLEXGlobalsViewControllerDelegate

- (void)globalsViewControllerDidFinish:(FLEXGlobalsTableViewController *)globalsViewController
{
    [self resignKeyAndDismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - FLEXObjectExplorerViewController Done Action

- (void)selectedElementExplorerFinished:(id)sender
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
        void (^presentBlock)() = ^{
            NSArray *allElements = [self allElementsInHierarchy];
            NSDictionary *depthsForElementObjects = [self hierarchyDepthsForElementObjects:allElements];
            FLEXHierarchyTableViewController *hierarchyTVC = [[FLEXHierarchyTableViewController alloc] initWithElements:allElements elementsAtTap:self.elementsAtTapPoint selectedElement:self.selectedElement depths:depthsForElementObjects];
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
        void (^presentBlock)() = ^{
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
        CGRect frame = self.selectedElement.frame;
        frame.origin.y += 1.0 / [[UIScreen mainScreen] scale];
        self.selectedElement.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && [self.elementsAtTapPoint count] > 0) {
        NSUInteger selectedElementIndex = [self _indexOfSelectedElement];
        if (selectedElementIndex > 0) {
            self.selectedElement = [self.elementsAtTapPoint objectAtIndex:selectedElementIndex - 1];
        }
    }
}

- (void)handleUpArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedElement.frame;
        frame.origin.y -= 1.0 / [[UIScreen mainScreen] scale];
        self.selectedElement.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && [self.elementsAtTapPoint count] > 0) {
        NSUInteger selectedElementIndex = [self _indexOfSelectedElement];
        if (selectedElementIndex < [self.elementsAtTapPoint count] - 1) {
            self.selectedElement = [self.elementsAtTapPoint objectAtIndex:selectedElementIndex + 1];
        }
    }
}

- (void)handleRightArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedElement.frame;
        frame.origin.x += 1.0 / [[UIScreen mainScreen] scale];
        self.selectedElement.frame = frame;
    }
}

- (void)handleLeftArrowKeyPressed
{
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedElement.frame;
        frame.origin.x -= 1.0 / [[UIScreen mainScreen] scale];
        self.selectedElement.frame = frame;
    }
}

- (NSUInteger)_indexOfSelectedElement
{
    return [self.elementsAtTapPoint indexOfObjectPassingTest:^BOOL(FLEXElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return self.selectedElement.object == obj.object;
    }];
}

@end
