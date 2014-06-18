//
//  FLEXViewControllerExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/11/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXViewControllerExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"

typedef NS_ENUM(NSUInteger, FLEXViewControllerExplorerRow) {
    FLEXViewControllerExplorerRowPush,
    FLEXViewControllerExplorerRowView
};

@interface FLEXViewControllerExplorerViewController ()

@property (nonatomic, readonly) UIViewController *viewController;

@end

@implementation FLEXViewControllerExplorerViewController

- (UIViewController *)viewController
{
    return [self.object isKindOfClass:[UIViewController class]] ? self.object : nil;
}

- (BOOL)canPushViewController
{
    // Only show the "Push View Controller" option if it's not already part of the hierarchy to avoid really disrupting the app.
    return self.viewController.view.window == nil;
}


#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Shortcuts";
}

- (NSArray *)customSectionRowCookies
{
    NSArray *rowCookies = @[@(FLEXViewControllerExplorerRowView)];
    if ([self canPushViewController]) {
        rowCookies = [@[@(FLEXViewControllerExplorerRowPush)] arrayByAddingObjectsFromArray:rowCookies];
    }
    return rowCookies;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;
    if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowPush)]) {
        title = @"Push View Controller";
    } else if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowView)]) {
        title = @"@property UIView *view";
    }
    return title;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    NSString *subtitle = nil;
    if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowView)]) {
        subtitle = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:self.viewController.view];
    }
    return subtitle;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    BOOL canDrillIn = NO;
    if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowPush)]) {
        canDrillIn = [self canPushViewController];
    }else if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowView)]) {
        canDrillIn = self.viewController.view != nil;
    }
    return canDrillIn;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowPush)]) {
        drillInViewController = self.viewController;
    } else if ([rowCookie isEqual:@(FLEXViewControllerExplorerRowView)]) {
        drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.viewController.view];
    }
    return drillInViewController;
}

@end
