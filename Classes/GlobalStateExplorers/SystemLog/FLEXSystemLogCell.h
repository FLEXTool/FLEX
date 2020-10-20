//
//  FLEXSystemLogCell.h
//  FLEX
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewCell.h"

@class FLEXSystemLogMessage;

extern NSString *const kFLEXSystemLogCellIdentifier;

@interface FLEXSystemLogCell : FLEXTableViewCell

@property (nonatomic) FLEXSystemLogMessage *logMessage;
@property (nonatomic, copy) NSString *highlightedText;

+ (NSString *)displayedTextForLogMessage:(FLEXSystemLogMessage *)logMessage;
+ (CGFloat)preferredHeightForLogMessage:(FLEXSystemLogMessage *)logMessage inWidth:(CGFloat)width;

@end
