//
//  FLEXDescriptionTableViewCell.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-05.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXDescriptionTableViewCell : UITableViewCell

+ (CGFloat)preferredHeightWithText:(NSString *)text inTableViewWidth:(CGFloat)tableViewWidth;

@end
