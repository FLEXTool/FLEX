//
//  FLEXTableContentHeaderCell.m
//  UICatalog
//
//  Created by Peng Tao on 15/11/26.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXTableColumnHeader.h"

@implementation FLEXTableColumnHeader
{
    UILabel *_arrowLabel;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, frame.size.width - 25, frame.size.height)];
        label.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:label];
        self.label = label;
        
        
        _arrowLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 20, 0, 20, frame.size.height)];
        _arrowLabel.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_arrowLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 1, 2, 1, frame.size.height - 4)];
        line.backgroundColor = [UIColor colorWithWhite:0.803 alpha:0.850];
        [self addSubview:line];
        
    }
    return self;
}

- (void)changeSortStatusWithType:(FLEXTableColumnHeaderSortType)type
{
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





@end
