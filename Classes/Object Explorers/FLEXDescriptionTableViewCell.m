//
//  FLEXDescriptionTableViewCell.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-05.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXDescriptionTableViewCell.h"
#import "FLEXUtility.h"

@interface FLEXDescriptionTableViewCell ()

@end

@implementation FLEXDescriptionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 0;
        self.textLabel.font = [[self class] labelFont];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, [[self class] labelInsets]);
}

+ (UIFont *)labelFont
{
    return [FLEXUtility defaultTableViewCellLabelFont];
}

+ (UIEdgeInsets)labelInsets
{
    UIEdgeInsets labelInsets = UIEdgeInsetsZero;
    labelInsets.top = 15.0;
    labelInsets.bottom = 15.0;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        labelInsets.left = 15.0;
        labelInsets.right = 0.0;
    } else {
        labelInsets.left = 10.0;
        labelInsets.right = 10.0;
    }
    return labelInsets;
}

+ (CGFloat)preferredHeightWithText:(NSString *)text inTableViewWidth:(CGFloat)tableViewWidth
{
    // Hardcoded margins from observation of cells in a grouped table on iOS 6.
    // There is no API to get the insets of the content view proir to layout.
    // Thankfully they removed the magic margins in iOS 7.
    // Differences are between the content view's width and the table view's width
    // Full screen iPhone - 20
    // Full screen iPad - 90
    
    CGFloat labelWidth = tableViewWidth;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            labelWidth -= 40.0;
        } else {
            labelWidth -= 90.0;
        }
    }
    
    UIEdgeInsets labelInsets = [self labelInsets];
    labelWidth -= (labelInsets.left + labelInsets.right);
    
    // Size an attributed string to get around deprecation warnings if the deployment target is >= 7 while still supporting deployment tagets back to 6.0.
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [self labelFont]}];
    CGSize constrainSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGFloat preferredLabelHeight = ceil([attributedText boundingRectWithSize:constrainSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height);
    CGFloat preferredCellHeight = preferredLabelHeight + labelInsets.top + labelInsets.bottom + 1.0;
    
    return preferredCellHeight;
}

@end
