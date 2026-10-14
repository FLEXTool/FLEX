//
//  FLEXHierarchyViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 1/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXHierarchyViewController.h"
#import "FLEXHierarchyTableViewController.h"
#import "FHSViewController.h"
#import "FLEXUtility.h"
#import "FLEXSwiftUIInspector.h"
#import "FLEXTabList.h"
#import "FLEXResources.h"
#import "FLEXAlert.h"
#import "NSUserDefaults+FLEX.h"
#import "UIBarButtonItem+FLEX.h"

typedef NS_ENUM(NSUInteger, FLEXHierarchyViewMode) {
    FLEXHierarchyViewModeTree = 1,
    FLEXHierarchyViewMode3DSnapshot
};

@interface FLEXHierarchyViewController ()
@property (nonatomic, readonly, weak) id<FLEXHierarchyDelegate> hierarchyDelegate;
@property (nonatomic, readonly) FHSViewController *snapshotViewController;
@property (nonatomic, readonly) FLEXHierarchyTableViewController *treeViewController;

@property (nonatomic) FLEXHierarchyViewMode mode;

@property (nonatomic, readonly) id selectedView;
@end

@implementation FLEXHierarchyViewController

#pragma mark - Initialization

+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate {
    return [self delegate:delegate viewsAtTap:nil selectedView:nil];
}

+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate
              viewsAtTap:(NSArray *)viewsAtTap
            selectedView:(id)selectedView {
    return [[self alloc] initWithDelegate:delegate viewsAtTap:viewsAtTap selectedView:selectedView];
}

- (id)initWithDelegate:(id)delegate viewsAtTap:(NSArray *)viewsAtTap selectedView:(id)view {
    self = [super init];
    if (self) {
        NSArray<UIWindow *> *allWindows = FLEXUtility.allWindows;
        _hierarchyDelegate = delegate;
        _treeViewController = [FLEXHierarchyTableViewController
            windows:allWindows viewsAtTap:viewsAtTap selectedView:view
        ];

        // The 3D snapshot shows views only; a SwiftUI view stands in as its hosting view
        if (viewsAtTap) {
            NSArray<UIView *> *views = [viewsAtTap flex_filtered:^BOOL(id item, NSUInteger idx) {
                return [item isKindOfClass:[UIView class]];
            }];
            _snapshotViewController = [FHSViewController
                snapshotViewsAtTap:views selectedView:[self.class viewForItem:view]
            ];
        } else {
            _snapshotViewController = [FHSViewController snapshotWindows:allWindows];
        }

        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    return self;
}


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // 3D toggle and SwiftUI settings buttons
    self.treeViewController.navigationItem.leftBarButtonItems = @[
        [UIBarButtonItem flex_itemWithImage:FLEXResources.toggle3DIcon target:self action:@selector(toggleHierarchyMode)],
        [UIBarButtonItem flex_itemWithTitle:@"SwiftUI" target:self action:@selector(swiftUISettingsTapped)],
    ];

    // Dismiss when tree view row is selected
    __weak id<FLEXHierarchyDelegate> delegate = self.hierarchyDelegate;
    self.treeViewController.didSelectRowAction = ^(id selectedView) {
        [delegate viewHierarchyDidDismiss:selectedView];
    };

    // Start of in tree view
    _mode = FLEXHierarchyViewModeTree;
    [self pushViewController:self.treeViewController animated:NO];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Done button: manually added here because the hierarhcy screens need to actually pass
    // data back to the explorer view controller so that it can highlight selected views
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)
    ];

    [super pushViewController:viewController animated:animated];
}


#pragma mark - Private

- (void)donePressed {
    // We need to manually close ourselves here because
    // FLEXNavigationController doesn't ever close tabs itself 
    [FLEXTabList.sharedList closeTab:self];
    [self.hierarchyDelegate viewHierarchyDidDismiss:self.selectedView];
}

- (void)swiftUISettingsTapped {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL recording = defaults.flex_recordSwiftUIViews;

    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"SwiftUI Views")
            .message(@"Name SwiftUI views and list them here, using the view tree SwiftUI records for ")
            .message(@"Xcode's view debugger. Recording starts at launch and covers every SwiftUI view ")
            .message(@"in the app. Restart the app for changes to take effect.");
        if (FLEXSwiftUIInspector.isRecording && !recording) {
            make.message(@"\n\nThe app already turns recording on with SWIFTUI_VIEW_DEBUG.");
        }

        make.button(recording ? @"Stop Recording" : @"Record SwiftUI Views").handler(^(NSArray<NSString *> *strings) {
            [defaults flex_toggleBoolForKey:kFLEXDefaultsRecordSwiftUIViewsKey];
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

- (void)toggleHierarchyMode {
    switch (self.mode) {
        case FLEXHierarchyViewModeTree:
            self.mode = FLEXHierarchyViewMode3DSnapshot;
            break;
        case FLEXHierarchyViewMode3DSnapshot:
            self.mode = FLEXHierarchyViewModeTree;
            break;
    }
}

- (void)setMode:(FLEXHierarchyViewMode)mode {
    if (mode != _mode) {
        // The tree view controller is our top stack view controller, and
        // changing the mode simply pushes the snapshot view. In the future,
        // I would like to have the 3D toggle button transparently switch
        // between two views instead of pushing a new view controller.
        // This way the views should share the search controller somehow.
        switch (mode) {
            case FLEXHierarchyViewModeTree:
                [self popViewControllerAnimated:NO];
                self.toolbarHidden = YES;
                self.treeViewController.selectedView = self.selectedView;
                break;
            case FLEXHierarchyViewMode3DSnapshot:
                [self pushViewController:self.snapshotViewController animated:NO];
                self.toolbarHidden = NO;
                self.snapshotViewController.selectedView = [self.class viewForItem:self.selectedView];
                break;
        }

        // Change this last so that self.selectedView works right above
        _mode = mode;
    }
}

/// A view, or the hosting view of a SwiftUI view.
+ (UIView *)viewForItem:(id)item {
    if ([item isKindOfClass:[FLEXSwiftUIViewNode class]]) {
        return [(FLEXSwiftUIViewNode *)item hostingView];
    }

    return item;
}

- (id)selectedView {
    switch (self.mode) {
        case FLEXHierarchyViewModeTree:
            return self.treeViewController.selectedView;
        case FLEXHierarchyViewMode3DSnapshot:
            return self.snapshotViewController.selectedView;
    }
}

@end
