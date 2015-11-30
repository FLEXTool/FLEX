//
//  FLEXTableContentCell.h
//  UICatalog
//
//  Created by Peng Tao on 15/11/24.
//  Copyright © 2015年 f. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXTableContentCell;
@protocol FLEXTableContentCellDelegate <NSObject>

@optional
- (void)tableContentCell:(FLEXTableContentCell *)tableView labelDidTapWithText:(NSString *)text;

@end

@interface FLEXTableContentCell : UITableViewCell

@property (nonatomic, strong)NSArray *labels;

@property (nonatomic, weak) id<FLEXTableContentCellDelegate>delegate;

+ (instancetype)cellWithTableView:(UITableView *)tableView columnNumber:(NSInteger)number;

@end
