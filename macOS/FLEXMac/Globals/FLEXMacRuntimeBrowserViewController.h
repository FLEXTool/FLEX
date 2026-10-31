//
//  FLEXMacRuntimeBrowserViewController.h
//  FLEX (macOS)
//
//  Browse loaded images (libraries) and the classes they define.
//  A simplified AppKit counterpart of FLEXObjcRuntimeViewController.
//

#import "FLEXMacTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacRuntimeBrowserViewController : FLEXMacTableViewController

/// Lists every loaded image which contains Objective-C classes
+ (instancetype)imagesBrowser;
/// Lists the classes in the image at \c imagePath
+ (instancetype)classesInImage:(NSString *)imagePath;

@end

NS_ASSUME_NONNULL_END
