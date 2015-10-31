//
//  FLEXDictionaryExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXDictionaryExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXDictionaryExplorerViewController ()

@property (nonatomic, readonly) NSDictionary *dictionary;

@end

@implementation FLEXDictionaryExplorerViewController

- (NSDictionary *)dictionary
{
    return [self.object isKindOfClass:[NSDictionary class]] ? self.object : nil;
}


#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Dictionary Objects";
}

- (NSArray *)customSectionRowCookies
{
    return [self.dictionary allKeys];
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    return [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:rowCookie];
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:self.dictionary[rowCookie]];
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:self.dictionary[rowCookie]];
}

- (BOOL)shouldShowDescription
{
    return NO;
}

@end
