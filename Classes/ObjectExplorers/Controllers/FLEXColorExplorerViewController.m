//
//  FLEXColorExplorerViewController.m
//  Flipboard
//
//  Created by Tanner on 10/18/18.
//  Copyright © 2018 Flipboard. All rights reserved.
//

#import "FLEXColorExplorerViewController.h"

@interface FLEXColorExplorerViewController ()

@end

@implementation FLEXColorExplorerViewController

- (BOOL)shouldShowDescription
{
    return NO;
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
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    UIView *square = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    square.backgroundColor = (UIColor *)self.object;
    return square;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    if ([@0 isEqual:rowCookie]) {
        return NO;
    }
    
    return [super customSectionCanDrillIntoRowWithCookie:rowCookie];
}

@end
