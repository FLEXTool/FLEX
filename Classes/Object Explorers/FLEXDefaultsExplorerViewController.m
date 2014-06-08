//
//  FLEXDefaultsExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXDefaultsExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXDefaultEditorViewController.h"

@interface FLEXDefaultsExplorerViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;

@end

@implementation FLEXDefaultsExplorerViewController

- (NSUserDefaults *)defaults
{
    return [self.object isKindOfClass:[NSUserDefaults class]] ? self.object : nil;
}


#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Defaults";
}

- (NSArray *)customSectionRowCookies
{
    return [[[self.defaults dictionaryRepresentation] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    return rowCookie;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[self.defaults objectForKey:rowCookie]];
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    NSString *key = rowCookie;
    id drillInObject = [self.defaults objectForKey:key];
    if ([FLEXDefaultEditorViewController canEditDefaultWithValue:drillInObject]) {
        drillInViewController = [[FLEXDefaultEditorViewController alloc] initWithDefaults:self.defaults key:key];
    } else {
        drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:drillInObject];
    }
    return drillInViewController;
}

- (BOOL)shouldShowDescription
{
    return NO;
}

@end
