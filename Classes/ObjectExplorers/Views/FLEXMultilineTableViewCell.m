//
//  FLEXMultilineTableViewCell.m
//  FLEX
//
//  Created by Ryan Olson on 2/13/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXMultilineTableViewCell.h"
#import "UIView+FLEX_Layout.h"

@interface FLEXMultilineTableViewCell ()
@property (nonatomic, readonly) UILabel *_titleLabel;
@property (nonatomic, readonly) UILabel *_subtitleLabel;
@property (nonatomic) BOOL constraintsUpdated;
@end

@implementation FLEXMultilineTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel.numberOfLines = 0;
        self.subtitleLabel.numberOfLines = 0;
    }

    return self;
}

+ (UIEdgeInsets)labelInsets {
    return UIEdgeInsetsMake(10.0, 15.0, 10.0, 15.0);
}

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                            inTableViewWidth:(CGFloat)tableViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory {
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


@implementation FLEXMultilineDetailTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end
