//
//  FLEXShortcut.h
//  FLEX
//
//  Created by Tanner Bennett on 12/10/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Represents a row in a shortcut section.
///
/// The purpsoe of this protocol is to allow delegating a small
/// subset of the responsibilities of a \c FLEXShortcutsSection
/// to another object, for a single arbitrary row.
///
/// It is useful to make your own shortcuts to append/prepend
/// them to the existing list of shortcuts for a class.
@protocol FLEXShortcut <NSObject>

- (NSString *)titleWith:(id)object;
- (NSString *)subtitleWith:(id)object;
//- (void (^)(UIViewController *))didSelectAction:(id)object;
/// Called when the row is selected
- (UIViewController *)viewerWith:(id)object;
/// Basically, whether or not to show a detail disclosure indicator
- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object;

@optional
/// Called when the (i) button is pressed
- (UIViewController *)editorWith:(id)object;

@end

/// Provides default behavior for FLEX metadata objects.
@interface FLEXShortcut : NSObject <FLEXShortcut>

/// @param item An \c NSString or \c FLEX* metadata object.
/// @note You may also pass a \c FLEXShortcut conforming object,
/// and that object will be returned instead.
+ (id<FLEXShortcut>)shortcutFor:(id)item;

@end
