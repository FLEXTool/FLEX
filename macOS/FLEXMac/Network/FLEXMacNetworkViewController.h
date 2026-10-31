//
//  FLEXMacNetworkViewController.h
//  FLEX (macOS)
//
//  Network history and request details.
//  The AppKit counterpart of FLEXNetworkMITMViewController
//  and FLEXHTTPTransactionDetailController.
//

#import "FLEXMacTableViewController.h"
@class FLEXHTTPTransaction;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXMacNetworkViewController : FLEXMacTableViewController
@end

@interface FLEXMacNetworkDetailViewController : FLEXMacTableViewController
+ (instancetype)detailsForTransaction:(FLEXHTTPTransaction *)transaction;
@end

NS_ASSUME_NONNULL_END
