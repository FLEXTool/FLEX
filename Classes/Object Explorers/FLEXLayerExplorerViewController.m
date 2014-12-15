//
//  FLEXLayerExplorerViewController.m
//  UICatalog
//
//  Created by Ryan Olson on 12/14/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXLayerExplorerViewController.h"
#import "FLEXImagePreviewViewController.h"

typedef NS_ENUM(NSUInteger, FLEXLayerExplorerRow) {
    FLEXLayerExplorerRowPreview
};

@interface FLEXLayerExplorerViewController ()

@property (nonatomic, readonly) CALayer *layerToExplore;

@end

@implementation FLEXLayerExplorerViewController

- (CALayer *)layerToExplore
{
    return [self.object isKindOfClass:[CALayer class]] ? self.object : nil;
}

#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Shortcuts";
}

- (NSArray *)customSectionRowCookies
{
    return @[@(FLEXLayerExplorerRowPreview)];
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;

    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXLayerExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXLayerExplorerRowPreview:
                title = @"Preview Image";
                break;
        }
    }

    return title;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;

    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXLayerExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXLayerExplorerRowPreview:
                drillInViewController = [[self class] imagePreviewViewControllerForLayer:self.layerToExplore];
                break;
        }
    }

    return drillInViewController;
}

+ (UIViewController *)imagePreviewViewControllerForLayer:(CALayer *)layer
{
    UIViewController *imagePreviewViewController = nil;
    if (!CGRectIsEmpty(layer.bounds)) {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, 0.0);
        CGContextRef imageContext = UIGraphicsGetCurrentContext();
        [layer renderInContext:imageContext];
        UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imagePreviewViewController = [[FLEXImagePreviewViewController alloc] initWithImage:previewImage];
    }
    return imagePreviewViewController;
}

@end
