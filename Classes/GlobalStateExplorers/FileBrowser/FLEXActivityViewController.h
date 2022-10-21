//
//  FLEXActivityViewController.h
//  FLEX
//
//  Created by Tanner Bennett on 5/26/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Wraps UIActivityViewController so that it can't dismiss other view controllers
@interface FLEXActivityViewController : UIActivityViewController

/// @param source A \c UIVIew, \c UIBarButtonItem, or \c NSValue representing a source rect.
+ (id)sharing:(NSArray *)items source:(nullable id)source;

@end

NS_ASSUME_NONNULL_END
