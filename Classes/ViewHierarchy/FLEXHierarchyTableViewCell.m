//
//  FLEXHierarchyTableViewCell.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-02.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXHierarchyTableViewCell.h"
#import "FLEXUtility.h"

@interface FLEXHierarchyTableViewCell ()

@property (nonatomic, strong) UIView *depthIndicatorView;
@property (nonatomic, strong) UIImageView *colorCircleImageView;

@end

@implementation FLEXHierarchyTableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.depthIndicatorView = [[UIView alloc] init];
        self.depthIndicatorView.backgroundColor = [FLEXUtility hierarchyIndentPatternColor];
        [self.contentView addSubview:self.depthIndicatorView];
        
        UIImage *defaultCircleImage = [FLEXUtility circularImageWithColor:[UIColor blackColor] radius:5.0];
        self.colorCircleImageView = [[UIImageView alloc] initWithImage:defaultCircleImage];
        [self.contentView addSubview:self.colorCircleImageView];
        
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0];
        self.detailTextLabel.font = [FLEXUtility defaultTableViewCellLabelFont];
        self.accessoryType = UITableViewCellAccessoryDetailButton;
        
        self.viewBackgroundColorView = [[UIView alloc] init];
        self.viewBackgroundColorView.clipsToBounds = YES;
        self.viewBackgroundColorView.layer.borderColor = [UIColor blackColor].CGColor;
        self.viewBackgroundColorView.layer.borderWidth = 1.0f;
        [self.contentView addSubview:self.viewBackgroundColorView];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *originalColour = self.viewBackgroundColorView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    // UITableViewCell changes all subviews in the contentView to backgroundColor = clearColor.
    // We want to preserve the hierarchy background color when highlighted.
    self.depthIndicatorView.backgroundColor = [FLEXUtility hierarchyIndentPatternColor];
    
    self.viewBackgroundColorView.backgroundColor = originalColour;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *originalColour = self.viewBackgroundColorView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    // See setHighlighted above.
    self.depthIndicatorView.backgroundColor = [FLEXUtility hierarchyIndentPatternColor];
    
    self.viewBackgroundColorView.backgroundColor = originalColour;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGFloat kContentPadding = 10.0;
    const CGFloat kDepthIndicatorWidthMultiplier = 4.0;
    const CGFloat kViewBackgroundColourDimension = 20;
    
    CGRect depthIndicatorFrame = CGRectMake(kContentPadding, 0, self.viewDepth * kDepthIndicatorWidthMultiplier, self.contentView.bounds.size.height);
    self.depthIndicatorView.frame = depthIndicatorFrame;
    
    CGRect circleFrame = self.colorCircleImageView.frame;
    circleFrame.origin.x = CGRectGetMaxX(depthIndicatorFrame);
    circleFrame.origin.y = self.textLabel.frame.origin.y + FLEXFloor((self.textLabel.frame.size.height - circleFrame.size.height) / 2.0);
    self.colorCircleImageView.frame = circleFrame;
    
    CGRect textLabelFrame = self.textLabel.frame;
    CGFloat textOriginX = CGRectGetMaxX(circleFrame) + 4.0;
    textLabelFrame.origin.x = textOriginX;
    textLabelFrame.size.width = CGRectGetMaxX(self.contentView.frame) - kContentPadding - textOriginX - kViewBackgroundColourDimension;
    self.textLabel.frame = textLabelFrame;
    
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    CGFloat detailOriginX = CGRectGetMaxX(depthIndicatorFrame);
    detailTextLabelFrame.origin.x = detailOriginX;
    detailTextLabelFrame.size.width = CGRectGetMaxX(self.contentView.bounds) - kContentPadding - detailOriginX;
    self.detailTextLabel.frame = detailTextLabelFrame;
    
    CGRect viewBackgroundColourViewFrame = self.textLabel.frame;
    viewBackgroundColourViewFrame.size.width = kViewBackgroundColourDimension;
    viewBackgroundColourViewFrame.size.height = kViewBackgroundColourDimension;
    viewBackgroundColourViewFrame.origin.x = CGRectGetMaxX(self.textLabel.frame) + kContentPadding;
    viewBackgroundColourViewFrame.origin.y = ABS(CGRectGetHeight(self.contentView.frame) -  CGRectGetHeight(viewBackgroundColourViewFrame)) / 2;
    
    self.viewBackgroundColorView.frame = viewBackgroundColourViewFrame;
    self.viewBackgroundColorView.layer.cornerRadius = kViewBackgroundColourDimension / 2;
}

- (void)setViewColor:(UIColor *)viewColor
{
    if (![_viewColor isEqual:viewColor]) {
        _viewColor = viewColor;
        self.colorCircleImageView.image = [FLEXUtility circularImageWithColor:viewColor radius:6.0];
    }
}

- (void)setViewDepth:(NSInteger)viewDepth
{
    if (_viewDepth != viewDepth) {
        _viewDepth = viewDepth;
        [self setNeedsLayout];
    }
}

@end
