//
//  FLEXHierarchyTableViewCell.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-02.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXHierarchyTableViewCell.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"
#import "FLEXColor.h"

@interface FLEXHierarchyTableViewCell ()

/// Indicates how deep the view is in the hierarchy
@property (nonatomic) UIView *depthIndicatorView;
/// Holds the color that visually distinguishes views from one another
@property (nonatomic) UIImageView *colorCircleImageView;
/// A checker-patterned view, used to help show the color of a view, like a photoshop canvas
@property (nonatomic) UIView *backgroundColorCheckerPatternView;
/// The subview of the checker pattern view which holds the actual color of the view
@property (nonatomic) UIView *viewBackgroundColorView;

@end

@implementation FLEXHierarchyTableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    return [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.depthIndicatorView = [UIView new];
        self.depthIndicatorView.backgroundColor = FLEXUtility.hierarchyIndentPatternColor;
        [self.contentView addSubview:self.depthIndicatorView];
        
        UIImage *defaultCircleImage = [FLEXUtility circularImageWithColor:UIColor.blackColor radius:5];
        self.colorCircleImageView = [[UIImageView alloc] initWithImage:defaultCircleImage];
        [self.contentView addSubview:self.colorCircleImageView];
        
        self.textLabel.font = UIFont.flex_defaultTableCellFont;
        self.detailTextLabel.font = UIFont.flex_defaultTableCellFont;
        self.accessoryType = UITableViewCellAccessoryDetailButton;
        
        // Use a pattern-based color to simplify application of the checker pattern
        static UIColor *checkerPatternColor = nil;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            checkerPatternColor = [UIColor colorWithPatternImage:FLEXResources.checkerPattern];
        });
        
        self.backgroundColorCheckerPatternView = [UIView new];
        self.backgroundColorCheckerPatternView.clipsToBounds = YES;
        self.backgroundColorCheckerPatternView.layer.borderColor = FLEXColor.tertiaryBackgroundColor.CGColor;
        self.backgroundColorCheckerPatternView.layer.borderWidth = 2.f / UIScreen.mainScreen.scale;
        self.backgroundColorCheckerPatternView.backgroundColor = checkerPatternColor;
        [self.contentView addSubview:self.backgroundColorCheckerPatternView];
        self.viewBackgroundColorView = [UIView new];
        [self.backgroundColorCheckerPatternView addSubview:self.viewBackgroundColorView];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *originalColour = self.viewBackgroundColorView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    // UITableViewCell changes all subviews in the contentView to backgroundColor = clearColor.
    // We want to preserve the hierarchy background color when highlighted.
    self.depthIndicatorView.backgroundColor = FLEXUtility.hierarchyIndentPatternColor;
    
    self.viewBackgroundColorView.backgroundColor = originalColour;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *originalColour = self.viewBackgroundColorView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    // See setHighlighted above.
    self.depthIndicatorView.backgroundColor = FLEXUtility.hierarchyIndentPatternColor;
    
    self.viewBackgroundColorView.backgroundColor = originalColour;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    const CGFloat kContentPadding = 6;
    const CGFloat kDepthIndicatorWidthMultiplier = 4;
    const CGFloat kViewColorIndicatorSize = 22;
    
    const CGRect bounds = self.contentView.bounds;
    const CGFloat centerY = CGRectGetMidY(bounds);
    const CGFloat textLabelCenterY = CGRectGetMidY(self.textLabel.frame);
    
    BOOL hideCheckerView = self.backgroundColorCheckerPatternView.hidden;
    CGFloat maxWidth = CGRectGetMaxX(bounds);
    maxWidth -= (hideCheckerView ? kContentPadding : (kViewColorIndicatorSize + kContentPadding * 2));
    
    CGRect depthIndicatorFrame = self.depthIndicatorView.frame = CGRectMake(
        kContentPadding, 0, self.viewDepth * kDepthIndicatorWidthMultiplier, CGRectGetHeight(bounds)
    );
    
    // Circle goes after depth, and its center Y = textLabel's center Y
    CGRect circleFrame = self.colorCircleImageView.frame;
    circleFrame.origin.x = CGRectGetMaxX(depthIndicatorFrame) + kContentPadding;
    circleFrame.origin.y = FLEXFloor(textLabelCenterY - CGRectGetHeight(circleFrame) / 2.f);
    self.colorCircleImageView.frame = circleFrame;
    
    // Text label goes after random color circle, width extends to the edge
    // of the contentView or to the padding before the color indicator view
    CGRect textLabelFrame = self.textLabel.frame;
    CGFloat textOriginX = CGRectGetMaxX(circleFrame) + kContentPadding;
    textLabelFrame.origin.x = textOriginX;
    textLabelFrame.size.width = maxWidth - textOriginX;
    self.textLabel.frame = textLabelFrame;
    
    // detailTextLabel leading edge lines up with the circle, and the
    // width extends to the same max X as the same max X as the textLabel
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    CGFloat detailOriginX = circleFrame.origin.x;
    detailTextLabelFrame.origin.x = detailOriginX;
    detailTextLabelFrame.size.width = maxWidth - detailOriginX;
    self.detailTextLabel.frame = detailTextLabelFrame;
    
    // Checker pattern view starts after the padding after the max X of textLabel,
    // and is centered vertically within the entire contentView
    self.backgroundColorCheckerPatternView.frame = CGRectMake(
        CGRectGetMaxX(self.textLabel.frame) + kContentPadding,
        centerY - kViewColorIndicatorSize / 2.f,
        kViewColorIndicatorSize,
        kViewColorIndicatorSize
    );
    
    // Background color view fills it's superview
    self.viewBackgroundColorView.frame = self.backgroundColorCheckerPatternView.bounds;
    self.backgroundColorCheckerPatternView.layer.cornerRadius = kViewColorIndicatorSize / 2.f;
}

- (void)setRandomColorTag:(UIColor *)randomColorTag {
    if (![_randomColorTag isEqual:randomColorTag]) {
        _randomColorTag = randomColorTag;
        self.colorCircleImageView.image = [FLEXUtility circularImageWithColor:randomColorTag radius:6];
    }
}

- (void)setViewDepth:(NSInteger)viewDepth {
    if (_viewDepth != viewDepth) {
        _viewDepth = viewDepth;
        [self setNeedsLayout];
    }
}

- (UIColor *)indicatedViewColor {
    return self.viewBackgroundColorView.backgroundColor;
}

- (void)setIndicatedViewColor:(UIColor *)color {
    self.viewBackgroundColorView.backgroundColor = color;
    
    // Hide the checker pattern view if there is no background color
    self.backgroundColorCheckerPatternView.hidden = color == nil;
    [self setNeedsLayout];
}

@end
