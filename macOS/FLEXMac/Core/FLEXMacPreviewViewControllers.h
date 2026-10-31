//
//  FLEXMacPreviewViewControllers.h
//  FLEX (macOS)
//
//  Simple viewers for images and text.
//

#import <AppKit/AppKit.h>
#import "FLEXMacNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacImagePreviewViewController : NSViewController <FLEXMacNavigationItems>
+ (instancetype)previewForImage:(NSImage *)image title:(nullable NSString *)title;
@end

@interface FLEXMacTextViewController : NSViewController <FLEXMacNavigationItems>
+ (instancetype)viewerWithText:(NSString *)text title:(nullable NSString *)title;
@end

NS_ASSUME_NONNULL_END
