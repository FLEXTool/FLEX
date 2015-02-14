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
    UIEdgeInsets labelInsets = UIEdgeInsetsZero;
    labelInsets.top = 10.0;
    labelInsets.bottom = 10.0;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        labelInsets.left = 15.0;
        labelInsets.right = 15.0;
    } else {
        labelInsets.left = 10.0;
        labelInsets.right = 10.0;
    }
    return labelInsets;
}

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText inTableViewWidth:(CGFloat)tableViewWidth style:(UITableViewStyle)style showsAccessory:(BOOL)showsAccessory
{
    // Hardcoded margins from observation of cells in a grouped table on iOS 6.
    // There is no API to get the insets of the content view proir to layout.
    // Thankfully they removed the magic margins in iOS 7.
    // Differences are between the content view's width and the table view's width
    // Full screen iPhone - 20
    // Full screen iPad - 90

    CGFloat labelWidth = tableViewWidth;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1 && style == UITableViewStyleGrouped) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            labelWidth -= 40.0;
        } else {
            labelWidth -= 90.0;
        }
    }

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
