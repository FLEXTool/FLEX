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
#import "FLEXImagePreviewViewController.h"
#import "FLEXPropertyEditorViewController.h"

typedef NS_ENUM(NSUInteger, FLEXViewExplorerRow) {
    FLEXViewExplorerRowViewController,
    FLEXViewExplorerRowPreview,
    FLEXViewExplorerRowViewControllerForAncestor
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
    NSMutableArray *rowCookies = [NSMutableArray array];
    
    if ([FLEXUtility viewControllerForView:self.viewToExplore]) {
        [rowCookies addObject:@(FLEXViewExplorerRowViewController)];
    }else{
        [rowCookies addObject:@(FLEXViewExplorerRowViewControllerForAncestor)];
    }
    
    [rowCookies addObject:@(FLEXViewExplorerRowPreview)];
    [rowCookies addObjectsFromArray:[super customSectionRowCookies]];
    
    return rowCookies;
}

- (NSArray<NSString *> *)shortcutPropertyNames
{
    NSArray *propertyNames = @[@"frame", @"bounds", @"center", @"transform",
                               @"backgroundColor", @"alpha", @"opaque", @"hidden",
                               @"clipsToBounds", @"userInteractionEnabled", @"layer"];
    
    if ([self.viewToExplore isKindOfClass:[UILabel class]]) {
        propertyNames = [@[@"text", @"font", @"textColor"] arrayByAddingObjectsFromArray:propertyNames];
    }
    
    return propertyNames;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;
    
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXViewExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXViewExplorerRowViewController:
                title = @"View Controller";
                break;
                
            case FLEXViewExplorerRowPreview:
                title = @"Preview Image";
                break;
            
            case FLEXViewExplorerRowViewControllerForAncestor:
                title = @"View Controller For Ancestor";
                break;
        }
    } else if ([rowCookie isKindOfClass:[NSString class]]) {
        title = [super customSectionTitleForRowCookie:rowCookie];
    }
    
    return title;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    NSString *subtitle = nil;
    
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXViewExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXViewExplorerRowViewController:
                subtitle = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[FLEXUtility viewControllerForView:self.viewToExplore]];
                break;
                
            case FLEXViewExplorerRowPreview:
                break;
            
            case FLEXViewExplorerRowViewControllerForAncestor:
                subtitle = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[FLEXUtility viewControllerForAncestralView:self.viewToExplore]];
                break;
        }
    } else if ([rowCookie isKindOfClass:[NSString class]]) {
        return [super customSectionSubtitleForRowCookie:rowCookie];
    }
    
    return subtitle;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXViewExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXViewExplorerRowViewController:
                drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[FLEXUtility viewControllerForView:self.viewToExplore]];
                break;
                
            case FLEXViewExplorerRowPreview:
                drillInViewController = [[self class] imagePreviewViewControllerForView:self.viewToExplore];
                break;
                
            case FLEXViewExplorerRowViewControllerForAncestor:
                drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[FLEXUtility viewControllerForAncestralView:self.viewToExplore]];
                break;
        }
    } else if ([rowCookie isKindOfClass:[NSString class]]) {
        return [super customSectionDrillInViewControllerForRowCookie:rowCookie];
    }

    return drillInViewController;
}

+ (UIViewController *)imagePreviewViewControllerForView:(UIView *)view
{
    UIViewController *imagePreviewViewController = nil;
    if (!CGRectIsEmpty(view.bounds)) {
        CGSize viewSize = view.bounds.size;
        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
        [view drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
        UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imagePreviewViewController = [[FLEXImagePreviewViewController alloc] initWithImage:previewImage];
    }
    return imagePreviewViewController;
}


#pragma mark - Runtime Adjustment

+ (void)initialize
{
    // A quirk of UIView: a lot of the "@property"s are not actually properties from the perspective of the runtime.
    // We add these properties to the class at runtime if they haven't been added yet.
    // This way, we can use our property editor to access and change them.
    // The property attributes match the declared attributes in UIView.h
    NSDictionary<NSString *, NSString *> *frameAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(CGRect)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"frame" attributes:frameAttributes toClass:[UIView class]];
    
    NSDictionary<NSString *, NSString *> *alphaAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(CGFloat)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"alpha" attributes:alphaAttributes toClass:[UIView class]];
    
    NSDictionary<NSString *, NSString *> *clipsAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"clipsToBounds" attributes:clipsAttributes toClass:[UIView class]];
    
    NSDictionary<NSString *, NSString *> *opaqueAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCustomGetter : @"isOpaque"};
    [FLEXRuntimeUtility tryAddPropertyWithName:"opaque" attributes:opaqueAttributes toClass:[UIView class]];
    
    NSDictionary<NSString *, NSString *> *hiddenAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCustomGetter : @"isHidden"};
    [FLEXRuntimeUtility tryAddPropertyWithName:"hidden" attributes:hiddenAttributes toClass:[UIView class]];
    
    NSDictionary<NSString *, NSString *> *backgroundColorAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(FLEXEncodeClass(UIColor)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCopy : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"backgroundColor" attributes:backgroundColorAttributes toClass:[UIView class]];
}

@end
