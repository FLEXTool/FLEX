//
//  FLEXBundleExplorerViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 6/13/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXBundleExplorerViewController.h"
#import "FLEXFileBrowserTableViewController.h"

typedef NS_ENUM(NSUInteger, FLEXBundleExplorerRow) {
    FLEXBundleExplorerRowBundlePath = 1
};

@interface FLEXBundleExplorerViewController ()
@property (nonatomic, readonly) NSBundle *bundleToExplore;
@end

@implementation FLEXBundleExplorerViewController

- (NSBundle *)bundleToExplore
{
    return (id)self.object;
}

- (NSArray<NSString *> *)shortcutPropertyNames
{
    return @[@"bundleIdentifier", @"principalClass", @"infoDictionary",
             @"bundlePath", @"executablePath", @"loaded"];
}

- (NSArray *)customSectionRowCookies
{
    BOOL isDirectory = NO;
    NSString *bundlePath = self.bundleToExplore.bundlePath;
    if ([NSFileManager.defaultManager fileExistsAtPath:bundlePath isDirectory:&isDirectory] && isDirectory) {
        return [@[@(FLEXBundleExplorerRowBundlePath)] arrayByAddingObjectsFromArray:[super customSectionRowCookies]];
    }

    return [super customSectionRowCookies];
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXBundleExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXBundleExplorerRowBundlePath:
                return @"Explore bundle directory";
        }
    } else {
        return [super customSectionTitleForRowCookie:rowCookie];
    }
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        return nil;
    } else {
        return [super customSectionSubtitleForRowCookie:rowCookie];
    }
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSNumber class]]) {
        FLEXBundleExplorerRow row = [rowCookie unsignedIntegerValue];
        switch (row) {
            case FLEXBundleExplorerRowBundlePath:
                return [[FLEXFileBrowserTableViewController alloc] initWithPath:self.bundleToExplore.bundlePath];
        }
    } else {
        return [super customSectionDrillInViewControllerForRowCookie:rowCookie];
    }
}

@end
