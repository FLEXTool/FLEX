//
//  FLEXHierarchyTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewController.h"

@interface FLEXHierarchyTableViewController : FLEXTableViewController

/// Lists every view, and under each SwiftUI hosting view its SwiftUI view tree.
/// \c viewsAtTap and \c selectedView hold \c UIView or \c FLEXSwiftUIViewNode objects.
+ (instancetype)windows:(NSArray<UIWindow *> *)allWindows
             viewsAtTap:(NSArray *)viewsAtTap
           selectedView:(id)selectedView;

/// A \c UIView or a \c FLEXSwiftUIViewNode
@property (nonatomic) id selectedView;
@property (nonatomic) void(^didSelectRowAction)(id selectedView);

@end
