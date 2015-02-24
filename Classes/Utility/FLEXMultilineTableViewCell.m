//
//  FLEXMultilineTableViewCell.m
//  UICatalog
//
//  Created by Ryan Olson on 2/13/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXMultilineTableViewCell.h"

NSString *const kFLEXMultilineTableViewCellIdentifier = @"kFLEXMultilineTableViewCellIdentifier";

@implementation FLEXMultilineTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, [[self class] labelInsets]);
}

+ (UIEdgeInsets)labelInsets
{
    return UIEdgeInsetsMake(10.0, 15.0, 10.0, 15.0);
}

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText inTableViewWidth:(CGFloat)tableViewWidth style:(UITableViewStyle)style showsAccessory:(BOOL)showsAccessory
{
    CGFloat labelWidth = tableViewWidth;

    // Content view inset due to accessory view observed on iOS 8.1 iPhone 6.
    if (showsAccessory) {
        labelWidth -= 34.0;
    }

    UIEdgeInsets labelInsets = [self labelInsets];
    labelWidth -= (labelInsets.left + labelInsets.right);

    CGSize constrainSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGFloat preferredLabelHeight = ceil([attributedText boundingRectWithSize:constrainSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height);
    CGFloat preferredCellHeight = preferredLabelHeight + labelInsets.top + labelInsets.bottom + 1.0;

    return preferredCellHeight;
}

@end
