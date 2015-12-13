//
//  FLEXTableContentCell.m
//  UICatalog
//
//  Created by Peng Tao on 15/11/24.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXTableContentCell.h"
#import "FLEXMultiColumnTableView.h"

@interface FLEXTableContentCell ()

@end

@implementation FLEXTableContentCell

+ (instancetype)cellWithTableView:(UITableView *)tableView columnNumber:(NSInteger)number;
{
    static NSString *identifier = @"FLEXTableContentCell";
    FLEXTableContentCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[FLEXTableContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        NSMutableArray *labels = [NSMutableArray array];
        for (int i = 0; i < number ; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.backgroundColor = [UIColor whiteColor];
            label.font            = [UIFont systemFontOfSize:13.0];
            label.textAlignment   = NSTextAlignmentLeft;
            label.backgroundColor = [UIColor greenColor];
            [labels addObject:label];
            
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:cell
                                                                                      action:@selector(labelDidTap:)];
            [label addGestureRecognizer:gesture];
            label.userInteractionEnabled = YES;
            
            [cell.contentView addSubview:label];
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
        cell.labels = labels;
    }
    return cell;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat labelWidth  = self.contentView.frame.size.width / self.labels.count;
    CGFloat labelHeight = self.contentView.frame.size.height;
    for (int i = 0; i < self.labels.count; i++) {
        UILabel *label = self.labels[i];
        label.frame = CGRectMake(labelWidth * i + 5, 0, (labelWidth - 10), labelHeight);
    }
}


- (void)labelDidTap:(UIGestureRecognizer *)gesture
{
    UILabel *label = (UILabel *)gesture.view;
    if ([self.delegate respondsToSelector:@selector(tableContentCell:labelDidTapWithText:)]) {
        [self.delegate tableContentCell:self labelDidTapWithText:label.text];
    }
}

@end
