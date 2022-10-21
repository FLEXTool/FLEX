//
//  FLEXHTTPTransactionDetailController.h
//  Flipboard
//
//  Created by Ryan Olson on 2/10/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXHTTPTransaction;

@interface FLEXHTTPTransactionDetailController : UITableViewController

+ (instancetype)withTransaction:(FLEXHTTPTransaction *)transaction;

@end
