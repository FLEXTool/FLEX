//
//  FHSSnapshotView.m
//  FLEX
//
//  Created by Tanner Bennett on 1/7/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FHSSnapshotView.h"
#import "FHSSnapshotNodes.h"
#import "SceneKit+Snapshot.h"
#import "FLEXColor.h"

@interface FHSSnapshotView ()
@property (nonatomic, readonly) SCNView *sceneView;
@property (nonatomic) NSString *currentSummary;

/// Maps nodes by snapshot IDs
@property (nonatomic) NSDictionary<NSString *, FHSSnapshotNodes *> *nodesMap;
@property (nonatomic) NSInteger maxDepth;

@property (nonatomic) FHSSnapshotNodes *highlightedNodes;
@property (nonatomic, getter=wantsHideHeaders) BOOL hideHeaders;
@property (nonatomic, getter=wantsHideBorders) BOOL hideBorders;
@property (nonatomic) BOOL suppressSelectionEvents;

@property (nonatomic, readonly) BOOL mustHideHeaders;
@end

@implementation FHSSnapshotView

#pragma mark - Initialization

+ (instancetype)delegate:(id<FHSSnapshotViewDelegate>)delegate {
    FHSSnapshotView *view = [self new];
    view.delegate = delegate;
    return view;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self initSpacingSlider];
        [self initDepthSlider];
        [self initSceneView]; // Must be last; calls setMaxDepth
//        self.hideHeaders = YES;
        
            // Self
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // Scene
        self.sceneView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleTap:)
        ]];
    }

    return self;
}

- (void)initSceneView {
    _sceneView = [SCNView new];
    self.sceneView.allowsCameraControl = YES;

    [self addSubview:self.sceneView];
}

- (void)initSpacingSlider {
    _spacingSlider = [UISlider new];
    self.spacingSlider.minimumValue = 0;
    self.spacingSlider.maximumValue = 100;
    self.spacingSlider.continuous = YES;
    [self.spacingSlider
        addTarget:self
        action:@selector(spacingSliderDidChange:)
        forControlEvents:UIControlEventValueChanged
    ];

    self.spacingSlider.value = 50;
}

- (void)initDepthSlider {
    _depthSlider = [FHSRangeSlider new];
    [self.depthSlider
        addTarget:self
        action:@selector(depthSliderDidChange:)
        forControlEvents:UIControlEventValueChanged
    ];
}


#pragma mark - Public

- (void)setSelectedView:(FHSViewSnapshot *)view {
    // Ivar set in selectSnapshot:
    [self selectSnapshot:view ? self.nodesMap[view.view.identifier] : nil];
}

- (void)setSnapshots:(NSArray<FHSViewSnapshot *> *)snapshots {
    _snapshots = snapshots;

    // Create new scene (possibly discarding old scene)
    SCNScene *scene = [SCNScene new];
    scene.background.contents = FLEXColor.primaryBackgroundColor;
    self.sceneView.scene = scene;

    NSInteger depth = 0;
    NSMutableDictionary *nodesMap = [NSMutableDictionary new];

    // Add every root snapshot to the root scene node with increasing depths
    SCNNode *root = scene.rootNode;
    for (FHSViewSnapshot *snapshot in self.snapshots) {
        [SCNNode
            snapshot:snapshot
            parent:nil
            parentNode:nil
            root:root
            depth:&depth
            nodesMap:nodesMap
            hideHeaders:_hideHeaders
        ];
    }

    self.maxDepth = depth;
    self.nodesMap = nodesMap;
}

- (void)setHeaderExclusions:(NSArray<Class> *)headerExclusions {
    _headerExclusions = headerExclusions;

    if (headerExclusions.count) {
        for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
            if ([headerExclusions containsObject:nodes.snapshotItem.view.view.class]) {
                nodes.forceHideHeader = YES;
            } else {
                nodes.forceHideHeader = NO;
            }
        }
    }
}

- (void)emphasizeViews:(NSArray<UIView *> *)emphasizedViews {
    if (emphasizedViews.count) {
        [self emphasizeViews:emphasizedViews inSnapshots:self.snapshots];
        [self setNeedsLayout];
    }
}

- (void)emphasizeViews:(NSArray<UIView *> *)emphasizedViews inSnapshots:(NSArray<FHSViewSnapshot *> *)snapshots {
    for (FHSViewSnapshot *snapshot in snapshots) {
        FHSSnapshotNodes *nodes = self.nodesMap[snapshot.view.identifier];
        nodes.dimmed = ![emphasizedViews containsObject:snapshot.view.view];
        [self emphasizeViews:emphasizedViews inSnapshots:snapshot.children];
    }
}

- (void)toggleShowHeaders {
    self.hideHeaders = !self.hideHeaders;
}

- (void)toggleShowBorders {
    self.hideBorders = !self.hideBorders;
}

- (void)hideView:(FHSViewSnapshot *)view {
    NSParameterAssert(view);
    FHSSnapshotNodes *nodes = self.nodesMap[view.view.identifier];
    [nodes.snapshot removeFromParentNode];
}

#pragma mark - Helper

- (BOOL)mustHideHeaders {
    return self.spacingSlider.value <= kFHSSmallZOffset;
}

- (void)setMaxDepth:(NSInteger)maxDepth {
    _maxDepth = maxDepth;

    self.depthSlider.allowedMinValue = 0;
    self.depthSlider.allowedMaxValue = maxDepth;
    self.depthSlider.maxValue = maxDepth;
    self.depthSlider.minValue = 0;
}

- (void)setHideHeaders:(BOOL)hideHeaders {
    if (_hideHeaders != hideHeaders) {
        _hideHeaders = hideHeaders;

        if (!self.mustHideHeaders) {
            if (hideHeaders) {
                [self hideHeaders];
            } else {
                [self unhideHeaders];
            }
        }
    }
}

- (void)setHideBorders:(BOOL)hideBorders {
    if (_hideBorders != hideBorders) {
        _hideBorders = hideBorders;

        for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
            nodes.border.hidden = hideBorders;
        }
    }
}

- (FHSSnapshotNodes *)nodesAtPoint:(CGPoint)point {
    NSArray<SCNHitTestResult *> *results = [self.sceneView hitTest:point options:nil];
    for (SCNHitTestResult *result in results) {
        SCNNode *nearestSnapshot = result.node.nearestAncestorSnapshot;
        if (nearestSnapshot) {
            return self.nodesMap[nearestSnapshot.name];
        }
    }

    return nil;
}

- (void)selectSnapshot:(FHSSnapshotNodes *)selected {
    // Notify delegate of de-select
    if (!selected && self.selectedView) {
        [self.delegate didDeselectView:self.selectedView];
    }

    _selectedView = selected.snapshotItem;

    // Case: selected the currently selected node
    if (selected == self.highlightedNodes) {
        return;
    }

    // No-op if nothng is selected (yay objc!)
    self.highlightedNodes.highlighted = NO;
    self.highlightedNodes = nil;

    // No node means we tapped the background
    if (selected) {
        selected.highlighted = YES;
        // TODO: update description text here
        self.highlightedNodes = selected;
    }

    // Notify delegate
    [self.delegate didSelectView:selected.snapshotItem];

    [self setNeedsLayout];
}

- (void)hideHeaders {
    for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
        nodes.header.hidden = YES;
    }
}

- (void)unhideHeaders {
    for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
        if (!nodes.forceHideHeader) {
            nodes.header.hidden = NO;
        }
    }
}


#pragma mark - Event Handlers

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        CGPoint tap = [gesture locationInView:self.sceneView];
        [self selectSnapshot:[self nodesAtPoint:tap]];
    }
}

- (void)spacingSliderDidChange:(UISlider *)slider {
    // TODO: hiding the header when flat logic

    for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
        nodes.snapshot.position = ({
            SCNVector3 pos = nodes.snapshot.position;
            pos.z = MAX(slider.value, kFHSSmallZOffset) * nodes.depth;
            pos;
        });

        if (!self.wantsHideHeaders) {
            if (self.mustHideHeaders) {
                [self hideHeaders];
            } else {
                [self unhideHeaders];
            }
        }
    }
}

- (void)depthSliderDidChange:(FHSRangeSlider *)slider {
    CGFloat min = slider.minValue, max = slider.maxValue;
    for (FHSSnapshotNodes *nodes in self.nodesMap.allValues) {
        CGFloat depth = nodes.depth;
        nodes.snapshot.hidden = depth < min || max < depth;
    }
}

@end
