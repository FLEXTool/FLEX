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
    [rowCookies addObjectsFromArray:[self shortcutPropertyNames]];
    
    return rowCookies;
}

- (NSArray *)shortcutPropertyNames
{
    NSArray *propertyNames = @[@"frame", @"bounds", @"center", @"transform", @"backgroundColor", @"alpha", @"opaque", @"hidden", @"clipsToBounds", @"userInteractionEnabled", @"layer"];
    
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
        objc_property_t property = [self viewPropertyForName:rowCookie];
        if (property) {
            NSString *prettyPropertyName = [FLEXRuntimeUtility prettyNameForProperty:property];
            // Since we're outside of the "properties" section, prepend @property for clarity.
            title = [NSString stringWithFormat:@"@property %@", prettyPropertyName];
        }
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
        objc_property_t property = [self viewPropertyForName:rowCookie];
        if (property) {
            id value = [FLEXRuntimeUtility valueForProperty:property onObject:self.viewToExplore];
            subtitle = [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:value];
        }
    }
    
    return subtitle;
}

- (objc_property_t)viewPropertyForName:(NSString *)propertyName
{
    return class_getProperty([self.viewToExplore class], [propertyName UTF8String]);
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
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
        objc_property_t property = [self viewPropertyForName:rowCookie];
        if (property) {
            id currentValue = [FLEXRuntimeUtility valueForProperty:property onObject:self.viewToExplore];
            if ([FLEXPropertyEditorViewController canEditProperty:property currentValue:currentValue]) {
                drillInViewController = [[FLEXPropertyEditorViewController alloc] initWithTarget:self.object property:property];
            } else {
                drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:currentValue];
            }
        }
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
    NSDictionary *frameAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(CGRect)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"frame" attributes:frameAttributes toClass:[UIView class]];
    
    NSDictionary *alphaAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(CGFloat)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"alpha" attributes:alphaAttributes toClass:[UIView class]];
    
    NSDictionary *clipsAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"clipsToBounds" attributes:clipsAttributes toClass:[UIView class]];
    
    NSDictionary *opaqueAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCustomGetter : @"isOpaque"};
    [FLEXRuntimeUtility tryAddPropertyWithName:"opaque" attributes:opaqueAttributes toClass:[UIView class]];
    
    NSDictionary *hiddenAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(@encode(BOOL)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCustomGetter : @"isHidden"};
    [FLEXRuntimeUtility tryAddPropertyWithName:"hidden" attributes:hiddenAttributes toClass:[UIView class]];
    
    NSDictionary *backgroundColorAttributes = @{kFLEXUtilityAttributeTypeEncoding : @(FLEXEncodeClass(UIColor)), kFLEXUtilityAttributeNonAtomic : @"", kFLEXUtilityAttributeCopy : @""};
    [FLEXRuntimeUtility tryAddPropertyWithName:"backgroundColor" attributes:backgroundColorAttributes toClass:[UIView class]];
}

@end
