//
//  FLEXImageExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/12/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXImageExplorerViewController.h"
#import "FLEXImagePreviewViewController.h"

typedef NS_ENUM(NSUInteger, FLEXImageExplorerRow) {
    FLEXImageExplorerRowImage
};

@interface FLEXImageExplorerViewController ()

@property (nonatomic, readonly) UIImage *image;

@end

@implementation FLEXImageExplorerViewController

- (UIImage *)image
{
    return [self.object isKindOfClass:[UIImage class]] ? self.object : nil;
}

#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Shortcuts";
}

- (NSArray *)customSectionRowCookies
{
    return @[@(FLEXImageExplorerRowImage)];
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;
    if ([rowCookie isEqual:@(FLEXImageExplorerRowImage)]) {
        title = @"Show Image";
    }
    return title;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return nil;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    if ([rowCookie isEqual:@(FLEXImageExplorerRowImage)]) {
        drillInViewController = [[FLEXImagePreviewViewController alloc] initWithImage:self.image];
    }
    return drillInViewController;
}

@end
