//
//  FLEXMacNavigationController.h
//  FLEX (macOS)
//
//  A minimal UINavigationController-like container for AppKit.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// View controllers pushed onto a FLEXMacNavigationController may
/// adopt this protocol to place controls in the navigation bar.
@protocol FLEXMacNavigationItems <NSObject>
@optional
- (NSArray<NSView *> *)flex_navigationAccessoryViews;
/// The view to focus when this view controller becomes visible
- (nullable NSView *)flex_preferredFirstResponder;
@end

@interface FLEXMacNavigationController : NSViewController

- (instancetype)initWithRootViewController:(NSViewController *)root;

@property (nonatomic, readonly) NSArray<NSViewController *> *viewControllers;
@property (nonatomic, readonly, nullable) NSViewController *topViewController;

- (void)pushViewController:(NSViewController *)viewController;
- (void)popViewController;
- (void)popToRootViewController;
/// Replaces the whole stack with the given view controller
- (void)setRootViewController:(NSViewController *)viewController;
/// Re-reads the top view controller's navigation accessory views
- (void)reloadNavigationItems;

@end

@interface NSViewController (FLEXMacNavigation)
@property (nonatomic, readonly, nullable) FLEXMacNavigationController *flex_navigationController;
/// Pushes onto the containing navigation controller, or opens in the FLEX explorer window
- (void)flex_push:(nullable NSViewController *)viewController;
@end

/// Convenience to make a small borderless toolbar button with an SF symbol (or title fallback)
NSButton *FLEXMacBarButton(NSString *symbolName, NSString *fallbackTitle, NSString *tooltip, id _Nullable target, SEL _Nullable action);

NS_ASSUME_NONNULL_END
