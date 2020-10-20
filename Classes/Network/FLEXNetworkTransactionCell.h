//
//  FLEXNetworkTransactionCell.h
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kFLEXNetworkTransactionCellIdentifier;

@class FLEXNetworkTransaction;

@interface FLEXNetworkTransactionCell : UITableViewCell

@property (nonatomic) FLEXNetworkTransaction *transaction;

+ (CGFloat)preferredCellHeight;

@end
