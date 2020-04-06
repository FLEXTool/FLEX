//
//  FLEXDBQueryRowCell.m
//  FLEX
//
//  Created by Peng Tao on 15/11/24.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXDBQueryRowCell.h"
#import "FLEXMultiColumnTableView.h"
#import "NSArray+FLEX.h"
#import "UIFont+FLEX.h"
#import "FLEXColor.h"

NSString * const kFLEXDBQueryRowCellReuse = @"kFLEXDBQueryRowCellReuse";

@interface FLEXDBQueryRowCell ()
@property (nonatomic) NSInteger columnCount;
@property (nonatomic) NSArray<UILabel *> *labels;
@end

@implementation FLEXDBQueryRowCell

- (void)setData:(NSArray *)data {
    _data = data;
    self.columnCount = data.count;
    
    [self.labels flex_forEach:^(UILabel *label, NSUInteger idx) {
        id content = self.data[idx];
        
        if ([content isKindOfClass:[NSString class]]) {
            label.text = content;
        } else if (content == NSNull.null) {
            label.text = @"<null>";
            label.textColor = FLEXColor.deemphasizedTextColor;
        } else {
            label.text = [content description];
        }
    }];
}

- (void)setColumnCount:(NSInteger)columnCount {
    if (columnCount != _columnCount) {
        _columnCount = columnCount;
        
        // Remove existing labels
        for (UILabel *l in self.labels) {
            [l removeFromSuperview];
        }
        
        // Create new labels
        self.labels = [NSArray flex_forEachUpTo:columnCount map:^id(NSUInteger i) {
            UILabel *label = [UILabel new];
            label.font = UIFont.flex_defaultTableCellFont;
            label.textAlignment = NSTextAlignmentLeft;
            [self.contentView addSubview:label];
            
            return label;
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width  = self.contentView.frame.size.width / self.labels.count;
    CGFloat height = self.contentView.frame.size.height;
    
    [self.labels flex_forEach:^(UILabel *label, NSUInteger i) {
        label.frame = CGRectMake(width * i + 5, 0, (width - 10), height);
    }];
}

@end
