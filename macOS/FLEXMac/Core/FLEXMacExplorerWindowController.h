//
//  FLEXMacExplorerWindowController.h
//  FLEX (macOS)
//
//  Owns the main FLEX window, which hosts a navigation stack of explorers.
//

#import <AppKit/AppKit.h>
#import "FLEXMacUtility.h"
#import "FLEXMacNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

/// A floating panel so FLEX stays above the host app's windows and keeps
/// working while the host runs a modal alert.
@interface FLEXMacExplorerWindow : NSPanel <FLEXMacInternalWindow>
@end

@interface FLEXMacExplorerWindowController : NSWindowController

@property (nonatomic, readonly, class) FLEXMacExplorerWindowController *sharedController;

@property (nonatomic, readonly) FLEXMacNavigationController *navigationController;
@property (nonatomic, readonly) BOOL isVisible;

/// Replaces the navigation stack with \c viewController and shows the window
- (void)showRootViewController:(NSViewController *)viewController;
/// Pushes \c viewController and shows the window. If the window is not
/// visible, \c viewController becomes the root instead.
- (void)pushViewController:(NSViewController *)viewController;
- (void)hide;

@end

NS_ASSUME_NONNULL_END
