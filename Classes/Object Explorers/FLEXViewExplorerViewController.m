//
//  FLEXViewExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/11/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXViewExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXViewSnapshotViewController.h"
#import "FLEXPropertyEditorViewController.h"

typedef NS_ENUM(NSUInteger, FLEXViewExplorerRow) {
    FLEXViewExplorerRowViewController,
    FLEXViewExplorerRowFrame,
    FLEXViewExplorerRowPreview
};

@interface FLEXViewExplorerViewController ()

// Don't clash with UIViewController's view property
@property (nonatomic, readonly) UIView *viewToExplore;

@end

@implementation FLEXViewExplorerViewController

- (UIView *)viewToExplore
{
    return [self.object isKindOfClass:[UIView class]] ? self.object : nil;
}


#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Shortcuts";
}

- (NSArray *)customSectionRowCookies
{
    NSArray *rowCookies = @[@(FLEXViewExplorerRowPreview),
                            @(FLEXViewExplorerRowFrame)];
    
    if ([FLEXUtility viewControllerForView:self.viewToExplore]) {
        rowCookies = [@[@(FLEXViewExplorerRowViewController)] arrayByAddingObjectsFromArray:rowCookies];
    }
    
    return rowCookies;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;
    if ([rowCookie isEqual:@(FLEXViewExplorerRowViewController)]) {
        title = @"View Controller";
    } else if ([rowCookie isEqual:@(FLEXViewExplorerRowFrame)]) {
        title = @"@property CGRect frame";
    } else if ([rowCookie isEqual:@(FLEXViewExplorerRowPreview)]) {
        title = @"Image Preview";
    }
    return title;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    NSString *subtitle = nil;
    if ([rowCookie isEqual:@(FLEXViewExplorerRowViewController)]) {
        subtitle = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[FLEXUtility viewControllerForView:self.viewToExplore]];
    } else if ([rowCookie isEqual:@(FLEXViewExplorerRowFrame)]) {
        subtitle = [FLEXUtility stringForCGRect:self.viewToExplore.frame];
    }
    return subtitle;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    if ([rowCookie isEqual:@(FLEXViewExplorerRowViewController)]) {
        drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[FLEXUtility viewControllerForView:self.viewToExplore]];
    } else if ([rowCookie isEqual:@(FLEXViewExplorerRowFrame)]) {
        // A quirk of UIView: frame is not actually a property from the perspective of the runtime.
        // We add the property to the class at runtime if it hasn't been added yet.
        [FLEXRuntimeUtility addFramePropertyToUIViewIfNeeded];
        objc_property_t frameProperty = class_getProperty([UIView class], "frame");
        drillInViewController = [[FLEXPropertyEditorViewController alloc] initWithTarget:self.viewToExplore property:frameProperty];
    } else if ([rowCookie isEqual:@(FLEXViewExplorerRowPreview)]) {
        if (!CGRectIsEmpty(self.viewToExplore.bounds)) {
            CGSize viewSize = self.viewToExplore.bounds.size;
            UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
            if ([self.viewToExplore respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                [self.viewToExplore drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
            } else {
                CGContextRef imageContext = UIGraphicsGetCurrentContext();
                [self.viewToExplore.layer renderInContext:imageContext];
            }
            UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            drillInViewController = [[FLEXViewSnapshotViewController alloc] initWithImage:previewImage];
        }
    }
    return drillInViewController;
}

- (BOOL)shouldShowDescription
{
    return YES;
}

@end
