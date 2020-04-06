//
//  FLEXNetworkTransactionDetailController.h
//  Flipboard
//
//  Created by Ryan Olson on 2/10/15.
//  Copyright (c) 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXNetworkTransaction;

@interface FLEXNetworkTransactionDetailController : UITableViewController

@property (nonatomic) FLEXNetworkTransaction *transaction;

@end
