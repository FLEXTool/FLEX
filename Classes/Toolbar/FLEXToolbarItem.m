//
//  FLEXToolbarItem.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXToolbarItem.h"
#import "FLEXUtility.h"

@interface FLEXToolbarItem ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@end

@implementation FLEXToolbarItem

+ (instancetype)toolbarItemWithTitle:(NSString *)title image:(UIImage *)image
{
    FLEXToolbarItem *toolbarItem = [self buttonWithType:UIButtonTypeSystem];
    toolbarItem.title = title;
    toolbarItem.backgroundColor = [self defaultBackgroundColor];
    toolbarItem.image = image;
    toolbarItem.titleLabel.font = [FLEXUtility defaultFontOfSize:12.0];
    [toolbarItem setTitle:title forState:UIControlStateNormal];
    [toolbarItem setImage:image forState:UIControlStateNormal];
    [toolbarItem setTitleColor:[FLEXColor primaryTextColor] forState:UIControlStateNormal];
    [toolbarItem setTitleColor:[FLEXColor deemphasizedTextColor] forState:UIControlStateDisabled];
    [toolbarItem setTintColor:[FLEXColor iconColor]];
    return toolbarItem;
}


#pragma mark - Display Defaults

+ (NSDictionary<NSString *, id> *)titleAttributes
{
    return @{NSFontAttributeName : [FLEXUtility defaultFontOfSize:12.0]};
}

+ (UIColor *)highlightedBackgroundColor
{
    return [FLEXColor toolbarItemHighlightedColor];
}

+ (UIColor *)selectedBackgroundColor
{
    return [FLEXColor toolbarItemSelectedColor];
}

+ (UIColor *)defaultBackgroundColor
{
    return UIColor.clearColor;
}

+ (CGFloat)topMargin
{
    return 2.0;
}


#pragma mark - State Changes

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateColors];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateColors];
}

+ (id)_selectedIndicatorImage { return nil; }

- (void)updateColors
{
    // Background color
    if (self.highlighted) {
        self.backgroundColor = [[self class] highlightedBackgroundColor];
    } else if (self.selected) {
        self.backgroundColor = [[self class] selectedBackgroundColor];
    } else {
        self.backgroundColor = [[self class] defaultBackgroundColor];
    }
}


#pragma mark - UIButton Layout Overrides

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    NSDictionary *attrs = [[self class] titleAttributes];
    // Bottom aligned and centered.
    CGRect titleRect = CGRectZero;
    CGSize titleSize = [self.title boundingRectWithSize:contentRect.size
                                                options:0
                                             attributes:attrs
                                                context:nil].size;
    titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
    titleRect.size = titleSize;
    titleRect.origin.y = contentRect.origin.y + CGRectGetMaxY(contentRect) - titleSize.height;
    titleRect.origin.x = contentRect.origin.x + FLEXFloor((contentRect.size.width - titleSize.width) / 2.0);
    return titleRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGSize imageSize = self.image.size;
    CGRect titleRect = [self titleRectForContentRect:contentRect];
    CGFloat availableHeight = contentRect.size.height - titleRect.size.height - [[self class] topMargin];
    CGFloat originY = [[self class] topMargin] + FLEXFloor((availableHeight - imageSize.height) / 2.0);
    CGFloat originX = FLEXFloor((contentRect.size.width - imageSize.width) / 2.0);
    CGRect imageRect = CGRectMake(originX, originY, imageSize.width, imageSize.height);
    return imageRect;
}

@end
