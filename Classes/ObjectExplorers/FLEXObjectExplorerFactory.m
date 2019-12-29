//
//  FLEXObjectExplorerFactory.m
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXArrayExplorerViewController.h"
#import "FLEXSetExplorerViewController.h"
#import "FLEXDictionaryExplorerViewController.h"
#import "FLEXDefaultsExplorerViewController.h"
#import "FLEXViewControllerExplorerViewController.h"
#import "FLEXViewExplorerViewController.h"
#import "FLEXImageExplorerViewController.h"
#import "FLEXClassExplorerViewController.h"
#import "FLEXLayerExplorerViewController.h"
#import "FLEXColorExplorerViewController.h"
#import "FLEXBundleExplorerViewController.h"
#import <objc/runtime.h>

@implementation FLEXObjectExplorerFactory

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object
{
    // Bail for nil object. We can't explore nil.
    if (!object) {
        return nil;
    }
    
    static NSDictionary<NSString *, Class> *explorerSubclassesForObjectTypeStrings = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        explorerSubclassesForObjectTypeStrings = @{NSStringFromClass([NSArray class])          : [FLEXArrayExplorerViewController class],
                                                   NSStringFromClass([NSSet class])            : [FLEXSetExplorerViewController class],
                                                   NSStringFromClass([NSDictionary class])     : [FLEXDictionaryExplorerViewController class],
                                                   NSStringFromClass([NSUserDefaults class])   : [FLEXDefaultsExplorerViewController class],
                                                   NSStringFromClass([UIViewController class]) : [FLEXViewControllerExplorerViewController class],
                                                   NSStringFromClass([UIView class])           : [FLEXViewExplorerViewController class],
                                                   NSStringFromClass([UIImage class])          : [FLEXImageExplorerViewController class],
                                                   NSStringFromClass([CALayer class])          : [FLEXLayerExplorerViewController class],
                                                   NSStringFromClass([UIColor class])          : [FLEXColorExplorerViewController class],
                                                   NSStringFromClass([NSBundle class])         : [FLEXBundleExplorerViewController class],
                                                   };
    });
    
    Class explorerClass = nil;
    BOOL objectIsClass = class_isMetaClass(object_getClass(object));
    if (objectIsClass) {
        explorerClass = [FLEXClassExplorerViewController class];
    } else {
        explorerClass = [FLEXObjectExplorerViewController class];
        for (NSString *objectTypeString in explorerSubclassesForObjectTypeStrings) {
            Class objectClass = NSClassFromString(objectTypeString);
            if ([object isKindOfClass:objectClass]) {
                explorerClass = explorerSubclassesForObjectTypeStrings[objectTypeString];
                break;
            }
        }
    }
    
    FLEXObjectExplorerViewController *explorerViewController = [explorerClass new];
    explorerViewController.object = object;
    
    return explorerViewController;
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row 
{
    switch (row) {
        case FLEXGlobalsRowAppDelegate:
            return @"👉  App delegate";
        case FLEXGlobalsRowRootViewController:
            return @"🌴  Root view controller";
        case FLEXGlobalsRowProcessInfo:
            return @"🚦  NSProcessInfo.processInfo";
        case FLEXGlobalsRowUserDefaults:
            return @"💾  Preferences (NSUserDefaults)";
        case FLEXGlobalsRowMainBundle:
            return @"📦  NSBundle.mainBundle";
        case FLEXGlobalsRowApplication:
            return @"🚀  UIApplication.sharedApplication";
        case FLEXGlobalsRowMainScreen:
            return @"💻  UIScreen.mainScreen";
        case FLEXGlobalsRowCurrentDevice:
            return @"📱  UIDevice.currentDevice";
        case FLEXGlobalsRowPasteboard:
            return @"📋  UIPasteboard.generalPasteboard";
        default: return nil;
    }
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row 
{
    switch (row) {
        case FLEXGlobalsRowAppDelegate: {
            id<UIApplicationDelegate> appDelegate = UIApplication.sharedApplication.delegate;
            return [self explorerViewControllerForObject:appDelegate];
        }
        case FLEXGlobalsRowProcessInfo:
            return [self explorerViewControllerForObject:NSProcessInfo.processInfo];
        case FLEXGlobalsRowUserDefaults:
            return [self explorerViewControllerForObject:NSUserDefaults.standardUserDefaults];
        case FLEXGlobalsRowMainBundle:
            return [self explorerViewControllerForObject:NSBundle.mainBundle];
        case FLEXGlobalsRowApplication:
            return [self explorerViewControllerForObject:UIApplication.sharedApplication];
        case FLEXGlobalsRowMainScreen:
            return [self explorerViewControllerForObject:UIScreen.mainScreen];
        case FLEXGlobalsRowCurrentDevice:
            return [self explorerViewControllerForObject:UIDevice.currentDevice];
        case FLEXGlobalsRowPasteboard:
            return [self explorerViewControllerForObject:UIPasteboard.generalPasteboard];
        case FLEXGlobalsRowRootViewController:
            return [self explorerViewControllerForObject:UIApplication.sharedApplication.delegate.window.rootViewController];
        default: return nil;
    }
}

@end
