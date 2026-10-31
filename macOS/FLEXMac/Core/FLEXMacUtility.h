//
//  FLEXMacUtility.h
//  FLEX (macOS)
//
//  AppKit counterparts of the UIKit-specific helpers in FLEXUtility.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Windows owned by FLEX itself adopt this protocol so that they can be
/// excluded from the view hierarchy, view selection, and "key window" lookups.
@protocol FLEXMacInternalWindow <NSObject>
@end

@interface FLEXMacUtility : NSObject

#pragma mark Windows

/// @return YES if the window belongs to FLEX's own interface
+ (BOOL)isFLEXWindow:(nullable NSWindow *)window;
/// All windows of the app, excluding FLEX's own windows
@property (nonatomic, readonly, class) NSArray<NSWindow *> *appWindows;
/// The most recent key window of the app which is not a FLEX window
@property (nonatomic, readonly, class, nullable) NSWindow *appKeyWindow;
/// Starts tracking the app's key window. Called by FLEXManager.
+ (void)startTrackingKeyWindow;

#pragma mark Views

+ (NSString *)descriptionForView:(NSView *)view includingFrame:(BOOL)includeFrame;
+ (NSString *)stringForRect:(NSRect)rect;
/// The rect of the view in screen coordinates
+ (NSRect)screenRectForView:(NSView *)view;
/// The view controller whose view is exactly \c view, if any
+ (nullable NSViewController *)viewControllerForView:(NSView *)view;
/// The closest view controller of \c view or any of its ancestors
+ (nullable NSViewController *)viewControllerForAncestralView:(NSView *)view;
+ (nullable NSImage *)snapshotOfView:(NSView *)view;
+ (nullable NSImage *)snapshotOfLayer:(CALayer *)layer;
+ (NSColor *)consistentRandomColorForObject:(nullable id)object;
/// The root view of the window, including the title bar views
+ (nullable NSView *)rootViewForWindow:(NSWindow *)window;
/// Recursively counts the subviews of a view
+ (NSUInteger)subviewCountOfView:(NSView *)view;

#pragma mark Images & Fonts

/// An SF Symbol, or nil if it is unavailable
+ (nullable NSImage *)symbol:(NSString *)name;
+ (nullable NSImage *)symbol:(NSString *)name description:(nullable NSString *)description;
+ (NSFont *)monospacedFontOfSize:(CGFloat)size;
+ (NSImage *)circleImageWithColor:(NSColor *)color diameter:(CGFloat)diameter;

#pragma mark Alerts & Input

+ (void)showAlertWithTitle:(NSString *)title message:(nullable NSString *)message;
+ (void)showError:(NSError *)error;
/// Shows an alert with a single text field.
/// @param completion called with the entered text, or nil if cancelled
+ (void)promptWithTitle:(NSString *)title
                message:(nullable NSString *)message
           defaultValue:(nullable NSString *)defaultValue
             completion:(void(^)(NSString * _Nullable text))completion;
/// Shows a confirmation alert.
+ (void)confirmWithTitle:(NSString *)title
                 message:(nullable NSString *)message
             actionTitle:(NSString *)actionTitle
             destructive:(BOOL)destructive
              completion:(void(^)(void))completion;

#pragma mark Misc

+ (void)copyToPasteboard:(nullable NSString *)string;
/// Like +[FLEXRuntimeUtility summaryForObject:] but never longer than \c maxLength
+ (NSString *)summaryForObject:(nullable id)object maxLength:(NSUInteger)maxLength;
/// Like the above, but uses the declared type to format BOOLs as YES/NO
+ (NSString *)summaryForObject:(nullable id)object type:(nullable NSString *)typeEncoding maxLength:(NSUInteger)maxLength;
/// Human readable byte count
+ (NSString *)stringForByteCount:(long long)bytes;

@end

NS_ASSUME_NONNULL_END
