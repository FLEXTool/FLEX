//
//  FLEXMacViewHierarchyViewController.h
//  FLEX (macOS)
//
//  An outline of every window and view in the app.
//  The AppKit counterpart of FLEXHierarchyViewController.
//

#import <AppKit/AppKit.h>
#import "FLEXMacNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacViewHierarchyViewController : NSViewController <FLEXMacNavigationItems>

+ (instancetype)hierarchy;
/// Expands the hierarchy to reveal and select \c view
+ (instancetype)hierarchyFocusingOnView:(nullable NSView *)view;

- (void)reloadHierarchy;
- (void)focusOnView:(nullable NSView *)view;

@end

NS_ASSUME_NONNULL_END
