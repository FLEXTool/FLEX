//
//  FLEXArrayExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXArrayExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXArrayExplorerViewController ()

@property (nonatomic, readonly) NSArray *array;

@end

@implementation FLEXArrayExplorerViewController

- (NSArray *)array
{
    return [self.object isKindOfClass:[NSArray class]] ? self.object : nil;
}


#pragma mark - Superclass Overrides

- (NSString *)customSectionTitle
{
    return @"Array Indices";
}

- (NSArray *)customSectionRowCookies
{
    // Use index numbers as the row cookies
    NSMutableArray *cookies = [NSMutableArray arrayWithCapacity:[self.array count]];
    for (NSUInteger i = 0; i < [self.array count]; i++) {
        [cookies addObject:@(i)];
    }
    return cookies;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    return [rowCookie description];
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[self detailObjectForRowCookie:rowCookie]];
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:[self detailObjectForRowCookie:rowCookie]];
}

- (BOOL)shouldShowDescription
{
    return NO;
}


#pragma mark - Helpers

- (id)detailObjectForRowCookie:(id)rowCookie
{
    NSUInteger index = [rowCookie unsignedIntegerValue];
    return [self.array objectAtIndex:index];
}

@end
