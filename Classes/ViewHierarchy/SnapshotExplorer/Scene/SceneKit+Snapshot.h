//
//  SceneKit+Snapshot.h
//  FLEX
//
//  Created by Tanner Bennett on 1/8/20.
//

#import <SceneKit/SceneKit.h>
#import "FHSViewSnapshot.h"
@class FHSSnapshotNodes;

extern CGFloat const kFHSSmallZOffset;

#pragma mark SCNNode
@interface SCNNode (Snapshot)

/// @return the nearest ancestor snapshot node starting at this node
@property (nonatomic, readonly) SCNNode *nearestAncestorSnapshot;

/// @return a node that renders a highlight overlay over a specified snapshot
+ (instancetype)highlight:(FHSViewSnapshot *)view color:(UIColor *)color;
/// @return a node that renders a snapshot image
+ (instancetype)snapshot:(FHSViewSnapshot *)view;
/// @return a node that draws a line between two vertices
+ (instancetype)lineFrom:(SCNVector3)v1 to:(SCNVector3)v2 color:(UIColor *)lineColor;

/// @return a node that can be used to render a colored border around the specified node
- (instancetype)borderWithColor:(UIColor *)color;
/// @return a node that renders a header above a snapshot node
///         using the title text from the view, if specified
+ (instancetype)header:(FHSViewSnapshot *)view;

/// @return a SceneKit node that recursively renders a hierarchy
///         of UI elements starting at the specified snapshot
+ (instancetype)snapshot:(FHSViewSnapshot *)view
                  parent:(FHSViewSnapshot *)parentView
              parentNode:(SCNNode *)parentNode
                    root:(SCNNode *)rootNode
                   depth:(NSInteger *)depthOut
                nodesMap:(NSMutableDictionary<NSString *, FHSSnapshotNodes *> *)nodesMap
             hideHeaders:(BOOL)hideHeaders;

@end


#pragma mark SCNShape
@interface SCNShape (Snapshot)
/// @return a shape with the given path, 0 extrusion depth, and a double-sided
///         material with the given diffuse contents inserted at index 0
+ (instancetype)shapeWithPath:(UIBezierPath *)path materialDiffuse:(id)contents;
/// @return a shape that is used to render the background of the snapshot header
+ (instancetype)nameHeader:(UIColor *)color frame:(CGRect)frame corners:(CGFloat)cornerRadius;

@end


#pragma mark SCNText
@interface SCNText (Snapshot)
/// @return text geometry used to render text inside the snapshot header
+ (instancetype)labelGeometry:(NSString *)text font:(UIFont *)font;

@end
