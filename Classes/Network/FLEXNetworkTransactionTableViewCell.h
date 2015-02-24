//
//  FLEXNetworkTransactionTableViewCell.h
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2015 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kFLEXNetworkTransactionCellIdentifier;

@class FLEXNetworkTransaction;

@interface FLEXNetworkTransactionTableViewCell : UITableViewCell

@property (nonatomic, strong) FLEXNetworkTransaction *transaction;

+ (CGFloat)preferredCellHeight;

@end
