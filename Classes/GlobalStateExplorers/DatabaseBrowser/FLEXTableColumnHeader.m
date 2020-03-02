//
//  FLEXTableContentHeaderCell.m
//  FLEX
//
//  Created by Peng Tao on 15/11/26.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXTableColumnHeader.h"
#import "FLEXColor.h"
#import "UIFont+FLEX.h"
#import "FLEXUtility.h"

@interface FLEXTableColumnHeader ()
@property (nonatomic, readonly) UILabel *arrowLabel;
@property (nonatomic, readonly) UIView *lineView;
@end

@implementation FLEXTableColumnHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = FLEXColor.secondaryBackgroundColor;
        
        _titleLabel = [UILabel new];
        _titleLabel.font = UIFont.flex_defaultTableCellFont;
        [self addSubview:_titleLabel];
        
        _arrowLabel = [UILabel new];
        _arrowLabel.font = UIFont.flex_defaultTableCellFont;
        [self addSubview:_arrowLabel];
        
        _lineView = [UIView new];
        _lineView.backgroundColor = FLEXColor.hairlineColor;
        [self addSubview:_lineView];
        
    }
    return self;
}

- (void)setSortType:(FLEXTableColumnHeaderSortType)type {
    _sortType = type;
    
    switch (type) {
        case FLEXTableColumnHeaderSortTypeNone:
            _arrowLabel.text = @"";
            break;
        case FLEXTableColumnHeaderSortTypeAsc:
            _arrowLabel.text = @"⬆️";
            break;
        case FLEXTableColumnHeaderSortTypeDesc:
            _arrowLabel.text = @"⬇️";
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    
    self.titleLabel.frame = CGRectMake(5, 0, size.width - 25, size.height);
    self.arrowLabel.frame = CGRectMake(size.width - 20, 0, 20, size.height);
    self.lineView.frame = CGRectMake(size.width - 1, 2, FLEXPointsToPixels(1), size.height - 4);
}

@end
