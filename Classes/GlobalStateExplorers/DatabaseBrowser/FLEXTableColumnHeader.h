//
//  FLEXTableContentHeaderCell.h
//  UICatalog
//
//  Created by Peng Tao on 15/11/26.
//  Copyright © 2015年 f. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLEXTableColumnHeaderSortType) {
    FLEXTableColumnHeaderSortTypeNone = 0,
    FLEXTableColumnHeaderSortTypeAsc,
    FLEXTableColumnHeaderSortTypeDesc,
};

@interface FLEXTableColumnHeader : UIView

@property (nonatomic, strong) UILabel *label;

- (void)changeSortStatusWithType:(FLEXTableColumnHeaderSortType)type;

@end

