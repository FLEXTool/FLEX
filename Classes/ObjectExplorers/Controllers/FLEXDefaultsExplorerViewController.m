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
@property (nonatomic) BOOL onlyShowKeysForAppPrefs;
@property (nonatomic) NSArray *keyWhitelist;
@property (nonatomic) NSArray *keys;

@end

@implementation FLEXDefaultsExplorerViewController
@synthesize keys = _keys;

- (NSUserDefaults *)defaults
{
    return [self.object isKindOfClass:[NSUserDefaults class]] ? self.object : nil;
}

- (NSArray *)keys
{
    if (!_keys) {
        self.keys = self.defaults.dictionaryRepresentation.allKeys;
    }
    
    return _keys;
}

- (void)setKeys:(NSArray *)keys {
    _keys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)setOnlyShowKeysForAppPrefs:(BOOL)onlyShowKeysForAppPrefs
{
    if (_onlyShowKeysForAppPrefs == onlyShowKeysForAppPrefs) return;
    _onlyShowKeysForAppPrefs = onlyShowKeysForAppPrefs;
    
    if (onlyShowKeysForAppPrefs) {
        // Read keys from preferences file
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
        NSString *prefsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences"];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, bundle];
        self.keys = [NSDictionary dictionaryWithContentsOfFile:filePath].allKeys;
    }
}

#pragma mark - Superclass Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hide keys not present in the preferences file.
    // Useful because standardUserDefaults includes a lot of keys that are
    // included by default in every app, and probably aren't what you wan to see.
    self.onlyShowKeysForAppPrefs = self.defaults == [NSUserDefaults standardUserDefaults];
}

- (NSString *)customSectionTitle
{
    return @"Defaults";
}

- (NSArray *)customSectionRowCookies
{
    return self.keys;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    return rowCookie;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return [FLEXRuntimeUtility descriptionForIvarOrPropertyValue:[self.defaults objectForKey:rowCookie]];
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

@end
