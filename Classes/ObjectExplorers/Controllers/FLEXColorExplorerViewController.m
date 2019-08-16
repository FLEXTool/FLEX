//
//  FLEXColorExplorerViewController.m
//  Flipboard
//
//  Created by Tanner on 10/18/18.
//  Copyright © 2018 Flipboard. All rights reserved.
//

#import "FLEXColorExplorerViewController.h"

@interface FLEXColorExplorerViewController ()
@property (nonatomic, readonly) UIColor *colorObject;
@end

@implementation FLEXColorExplorerViewController

- (UIColor *)colorObject
{
    return (UIColor *)self.object;
}

- (NSString *)displayedObjectDescription
{
    CGFloat h, s, l;
    CGFloat r, g, b, a;
    [self.colorObject getRed:&r green:&g blue:&b alpha:&a];
    [self.colorObject getHue:&h saturation:&s brightness:&l alpha:nil];
    
    return [NSString stringWithFormat:@"HSL: (%.3f, %.3f, %.3f)\nRGB: (%.3f, %.3f, %.3f)\nAlpha: %.3f", h, s, l, r, g, b, a];
}

- (NSString *)customSectionTitle
{
    return @"Color";
}

- (NSArray *)customSectionRowCookies
{
    return @[@0];
}

- (UIView *)customViewForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        CGFloat width = UIScreen.mainScreen.bounds.size.width;
        switch ([rowCookie integerValue]) {
            case 0: {
                UIView *square = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
                square.backgroundColor = (UIColor *)self.object;
                return square;
            }
        }
    }
    
    return [super customViewForRowCookie:rowCookie];
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    if ([@0 isEqual:rowCookie]) {
        return NO;
    }
    
    return [super customSectionCanDrillIntoRowWithCookie:rowCookie];
}

@end
