//
//  FHSSnapshotNodes.m
//  FLEX
//
//  Created by Tanner Bennett on 1/7/20.
//

#import "FHSSnapshotNodes.h"
#import "SceneKit+Snapshot.h"

@interface FHSSnapshotNodes ()
@property (nonatomic, nullable) SCNNode *highlight;
@property (nonatomic, nullable) SCNNode *dimming;
@end
@implementation FHSSnapshotNodes

+ (instancetype)snapshot:(FHSViewSnapshot *)snapshot depth:(NSInteger)depth {
    FHSSnapshotNodes *nodes = [self new];
    nodes->_snapshotItem = snapshot;
    nodes->_depth = depth;
    return nodes;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted != highlighted) {
        _highlighted = highlighted;

        if (highlighted) {
            if (!self.highlight) {
                // Create highlight node
                self.highlight = [SCNNode
                    highlight:self.snapshotItem
                    color:[UIColor.blueColor colorWithAlphaComponent:0.5]
                ];
            }
            // Add add highlight node, remove dimming node if dimmed
            [self.snapshot addChildNode:self.highlight];
            if (self.isDimmed) {
                [self.dimming removeFromParentNode];
            }
        } else {
            // Remove highlight node, add back dimming node if dimmed
            [self.highlight removeFromParentNode];
            if (self.isDimmed) {
                [self.snapshot addChildNode:self.dimming];
            }
        }
    }
}

- (void)setDimmed:(BOOL)dimmed {
    if (_dimmed != dimmed) {
        _dimmed = dimmed;

        if (dimmed) {
            if (!self.dimming) {
                // Create dimming node
                self.dimming = [SCNNode
                    highlight:self.snapshotItem
                    color:[UIColor.blackColor colorWithAlphaComponent:0.5]
                ];
            }
            // Add add dimming node if not highlighted
            if (!self.isHighlighted) {
                [self.snapshot addChildNode:self.dimming];
            }
        } else {
            // Remove dimming node (if not already highlighted)
            if (!self.isHighlighted) {
                [self.dimming removeFromParentNode];
            }
        }
    }
}

- (void)setForceHideHeader:(BOOL)forceHideHeader {
    if (_forceHideHeader != forceHideHeader) {
        _forceHideHeader = forceHideHeader;

        if (self.header.parentNode) {
            self.header.hidden = YES;
            [self.header removeFromParentNode];
        } else {
            self.header.hidden = NO;
            [self.snapshot addChildNode:self.header];
        }
    }
}

@end
