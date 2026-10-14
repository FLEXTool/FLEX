//
//  FLEXHierarchyViewController.h
//  FLEX
//
//  Created by Tanner Bennett on 1/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXNavigationController.h"

@protocol FLEXHierarchyDelegate <NSObject>
/// @param selectedView A \c UIView or a \c FLEXSwiftUIViewNode
- (void)viewHierarchyDidDismiss:(id)selectedView;
@end

/// A navigation controller which manages two child view controllers:
/// a 3D Reveal-like hierarchy explorer, and a 2D tree-list hierarchy explorer.
@interface FLEXHierarchyViewController : FLEXNavigationController

+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate;
/// \c viewsAtTap and \c selectedView hold \c UIView or \c FLEXSwiftUIViewNode objects.
+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate
              viewsAtTap:(NSArray *)viewsAtTap
            selectedView:(id)selectedView;

- (void)toggleHierarchyMode;

@end
