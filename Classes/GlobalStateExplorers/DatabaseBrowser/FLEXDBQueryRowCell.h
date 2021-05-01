//
//  FLEXDBQueryRowCell.h
//  FLEX
//
//  Created by Peng Tao on 15/11/24.
//  Copyright © 2015年 f. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXDBQueryRowCell;

extern NSString * const kFLEXDBQueryRowCellReuse;

@protocol FLEXDBQueryRowCellLayoutSource <NSObject>

- (CGFloat)dbQueryRowCell:(FLEXDBQueryRowCell *)dbQueryRowCell minXForColumn:(NSUInteger)column;
- (CGFloat)dbQueryRowCell:(FLEXDBQueryRowCell *)dbQueryRowCell widthForColumn:(NSUInteger)column;

@end

@interface FLEXDBQueryRowCell : UITableViewCell

/// An array of NSString, NSNumber, or NSData objects
@property (nonatomic) NSArray *data;
@property (nonatomic, weak) id<FLEXDBQueryRowCellLayoutSource> layoutSource;

@end
