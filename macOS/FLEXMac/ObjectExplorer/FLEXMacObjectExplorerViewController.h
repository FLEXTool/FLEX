//
//  FLEXMacObjectExplorerViewController.h
//  FLEX (macOS)
//
//  Explores any object or class: description, type-specific shortcuts,
//  properties, ivars, methods, class hierarchy and protocols.
//

#import "FLEXMacTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacObjectExplorerViewController : FLEXMacTableViewController

/// @return nil if \c object is nil
+ (nullable instancetype)explorerForObject:(nullable id)object;

@property (nonatomic, readonly) id object;

@end

NS_ASSUME_NONNULL_END
