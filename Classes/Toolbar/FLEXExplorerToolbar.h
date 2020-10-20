//
//  FLEXExplorerToolbar.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXExplorerToolbarItem;

NS_ASSUME_NONNULL_BEGIN

/// Users of the toolbar can configure the enabled state
/// and event target/actions for each item.
@interface FLEXExplorerToolbar : UIView

/// The items to be displayed in the toolbar. Defaults to:
/// globalsItem, hierarchyItem, selectItem, moveItem, closeItem
@property (nonatomic, copy) NSArray<FLEXExplorerToolbarItem *> *toolbarItems;

/// Toolbar item for selecting views.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *selectItem;

/// Toolbar item for presenting a list with the view hierarchy.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *hierarchyItem;

/// Toolbar item for moving views.
/// Its \c sibling is the \c lastTabItem
@property (nonatomic, readonly) FLEXExplorerToolbarItem *moveItem;

/// Toolbar item for presenting the currently active tab.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *recentItem;

/// Toolbar item for presenting a screen with various tools for inspecting the app.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *globalsItem;

/// Toolbar item for hiding the explorer.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *closeItem;

/// A view for moving the entire toolbar.
/// Users of the toolbar can attach a pan gesture recognizer to decide how to reposition the toolbar.
@property (nonatomic, readonly) UIView *dragHandle;

/// A color matching the overlay on color on the selected view.
@property (nonatomic) UIColor *selectedViewOverlayColor;

/// Description text for the selected view displayed below the toolbar items.
@property (nonatomic, copy) NSString *selectedViewDescription;

/// Area where details of the selected view are shown
/// Users of the toolbar can attach a tap gesture recognizer to show additional details.
@property (nonatomic, readonly) UIView *selectedViewDescriptionContainer;

@end

NS_ASSUME_NONNULL_END
