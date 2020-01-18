//
//  FLEXMultilineTableViewCell.h
//  FLEX
//
//  Created by Ryan Olson on 2/13/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXTableViewCell.h"

/// A cell with both labels set to be multi-line capable.
@interface FLEXMultilineTableViewCell : FLEXTableViewCell

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText inTableViewWidth:(CGFloat)tableViewWidth style:(UITableViewStyle)style showsAccessory:(BOOL)showsAccessory;

@end

/// A \c FLEXMultilineTableViewCell initialized with \c UITableViewCellStyleSubtitle
@interface FLEXMultilineDetailTableViewCell : FLEXMultilineTableViewCell

@end
