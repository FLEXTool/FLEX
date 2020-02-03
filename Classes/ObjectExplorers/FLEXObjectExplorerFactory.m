//
//  FLEXObjectExplorerFactory.m
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorerFactory.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXAlert.h"
#import "FLEXClassShortcuts.h"
#import "FLEXViewShortcuts.h"
#import "FLEXViewControllerShortcuts.h"
#import "FLEXImageShortcuts.h"
#import "FLEXLayerShortcuts.h"
#import "FLEXColorPreviewSection.h"
#import "FLEXDefaultsContentSection.h"
#import "FLEXBundleShortcuts.h"
#import "FLEXBlockShortcuts.h"
#import <objc/runtime.h>

@implementation FLEXObjectExplorerFactory
static NSMutableDictionary<Class, Class> *classesToRegisteredSections = nil;

+ (void)initialize
{
    if (self == [FLEXObjectExplorerFactory class]) {
        #define ClassKey(name) (Class<NSCopying>)[name class]
        #define ClassKeyByName(str) (Class<NSCopying>)NSClassFromString(@ #str)
        classesToRegisteredSections = [NSMutableDictionary dictionaryWithDictionary:@{
            ClassKey(NSArray)          : [FLEXCollectionContentSection class],
            ClassKey(NSSet)            : [FLEXCollectionContentSection class],
            ClassKey(NSDictionary)     : [FLEXCollectionContentSection class],
            ClassKey(NSUserDefaults)   : [FLEXDefaultsContentSection class],
            ClassKey(UIViewController) : [FLEXViewControllerShortcuts class],
            ClassKey(UIView)           : [FLEXViewShortcuts class],
            ClassKey(UIImage)          : [FLEXImageShortcuts class],
            ClassKey(CALayer)          : [FLEXLayerShortcuts class],
            ClassKey(UIColor)          : [FLEXColorPreviewSection class],
            ClassKey(NSBundle)         : [FLEXBundleShortcuts class],
            ClassKeyByName(NSBlock)    : [FLEXBlockShortcuts class],
        }];
        #undef ClassKey
        #undef ClassKeyByName
    }
}

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object
{
    // Can't explore nil
    if (!object) {
        return nil;
    }

    // If we're given an object, this will look up it's class hierarchy
    // until it finds a registration. This will work for KVC classes,
    // since they are children of the original class, and not siblings.
    // If we are given an object, object_getClass will return a metaclass,
    // and the same thing will happen. FLEXClassShortcuts is the default
    // shortcut section for NSObject.
    //
    // TODO: rename it to FLEXNSObjectShortcuts or something?
    Class sectionClass = nil;
    Class cls = object_getClass(object);
    do {
        sectionClass = classesToRegisteredSections[(Class<NSCopying>)cls];
    } while (!sectionClass && (cls = [cls superclass]));

    if (!sectionClass) {
        sectionClass = [FLEXShortcutsSection class];
    }

    return [FLEXObjectExplorerViewController
        exploringObject:object
        customSection:[sectionClass forObject:object]
    ];
}

+ (void)registerExplorerSection:(Class)explorerClass forClass:(Class)objectClass
{
    classesToRegisteredSections[(Class<NSCopying>)objectClass] = explorerClass;
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row 
{
    switch (row) {
        case FLEXGlobalsRowAppDelegate:
            return @"🎟  App Delegate";
        case FLEXGlobalsRowKeyWindow:
            return @"🔑  Key Window";
        case FLEXGlobalsRowRootViewController:
            return @"🌴  Root View Controller";
        case FLEXGlobalsRowProcessInfo:
            return @"🚦  NSProcessInfo.processInfo";
        case FLEXGlobalsRowUserDefaults:
            return @"💾  Preferences";
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
        case FLEXGlobalsRowKeyWindow:
            return [FLEXObjectExplorerFactory
                explorerViewControllerForObject:FLEXUtility.appKeyWindow
            ];
        case FLEXGlobalsRowRootViewController: {
            id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
            if ([delegate respondsToSelector:@selector(window)]) {
                return [self explorerViewControllerForObject:delegate.window.rootViewController];
            }

            return nil;
        }
        default: return nil;
    }
}

+ (FLEXGlobalsTableViewControllerRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row
{
    switch (row) {
        case FLEXGlobalsRowRootViewController: {
            // Check if the app delegate responds to -window. If not, present an alert
            return ^(FLEXGlobalsViewController *host) {
                id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
                if ([delegate respondsToSelector:@selector(window)]) {
                    UIViewController *explorer = [self explorerViewControllerForObject:
                        delegate.window.rootViewController
                    ];
                    [host.navigationController pushViewController:explorer animated:YES];
                } else {
                    NSString *msg = @"The app delegate doesn't respond to -window";
                    [FLEXAlert showAlert:@":(" message:msg from:host];
                }
            };
        }
        default: return nil;
    }
}

@end
