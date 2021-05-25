//
//  FLEXObjectExplorerFactory.m
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXObjectExplorerFactory.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXClassShortcuts.h"
#import "FLEXViewShortcuts.h"
#import "FLEXViewControllerShortcuts.h"
#import "FLEXUIAppShortcuts.h"
#import "FLEXImageShortcuts.h"
#import "FLEXLayerShortcuts.h"
#import "FLEXColorPreviewSection.h"
#import "FLEXDefaultsContentSection.h"
#import "FLEXBundleShortcuts.h"
#import "FLEXNSStringShortcuts.h"
#import "FLEXNSDataShortcuts.h"
#import "FLEXBlockShortcuts.h"
#import "FLEXUtility.h"

@implementation FLEXObjectExplorerFactory
static NSMutableDictionary<id<NSCopying>, Class> *classesToRegisteredSections = nil;

+ (void)initialize {
    if (self == [FLEXObjectExplorerFactory class]) {
        // DO NOT USE STRING KEYS HERE
        // We NEED to use the class as a key, because we CANNOT
        // differentiate a class's name from the metaclass's name.
        // These mappings are per-class-object, not per-class-name.
        //
        // For example, if we used class names, this would result in
        // the object explorer trying to render a color preview for
        // the UIColor class object, which is not a color itself.
        #define ClassKey(name) (id<NSCopying>)[name class]
        #define ClassKeyByName(str) (id<NSCopying>)NSClassFromString(@ #str)
        #define MetaclassKey(meta) (id<NSCopying>)object_getClass([meta class])
        classesToRegisteredSections = [NSMutableDictionary dictionaryWithDictionary:@{
            MetaclassKey(NSObject)     : [FLEXClassShortcuts class],
            ClassKey(NSArray)          : [FLEXCollectionContentSection class],
            ClassKey(NSSet)            : [FLEXCollectionContentSection class],
            ClassKey(NSDictionary)     : [FLEXCollectionContentSection class],
            ClassKey(NSOrderedSet)     : [FLEXCollectionContentSection class],
            ClassKey(NSUserDefaults)   : [FLEXDefaultsContentSection class],
            ClassKey(UIViewController) : [FLEXViewControllerShortcuts class],
            ClassKey(UIApplication)    : [FLEXUIAppShortcuts class],
            ClassKey(UIView)           : [FLEXViewShortcuts class],
            ClassKey(UIImage)          : [FLEXImageShortcuts class],
            ClassKey(CALayer)          : [FLEXLayerShortcuts class],
            ClassKey(UIColor)          : [FLEXColorPreviewSection class],
            ClassKey(NSBundle)         : [FLEXBundleShortcuts class],
            ClassKey(NSString)         : [FLEXNSStringShortcuts class],
            ClassKey(NSData)           : [FLEXNSDataShortcuts class],
            ClassKeyByName(NSBlock)    : [FLEXBlockShortcuts class],
        }];
        #undef ClassKey
        #undef ClassKeyByName
        #undef MetaclassKey
    }
}

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object {
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
    FLEXShortcutsSection *shortcutsSection = [FLEXShortcutsSection forObject:object];
    NSArray *sections = @[shortcutsSection];
    
    Class customSectionClass = nil;
    Class cls = object_getClass(object);
    do {
        customSectionClass = classesToRegisteredSections[(id<NSCopying>)cls];
    } while (!customSectionClass && (cls = [cls superclass]));

    if (customSectionClass) {
        id customSection = [customSectionClass forObject:object];
        BOOL isFLEXShortcutSection = [customSection respondsToSelector:@selector(isNewSection)];
        
        // If the section "replaces" the default shortcuts section,
        // only return that section. Otherwise, return both this
        // section and the default shortcuts section.
        if (isFLEXShortcutSection && ![customSection isNewSection]) {
            sections = @[customSection];
        } else {
            // Custom section will go before shortcuts
            sections = @[customSection, shortcutsSection];            
        }
    }

    return [FLEXObjectExplorerViewController
        exploringObject:object
        customSections:sections
    ];
}

+ (void)registerExplorerSection:(Class)explorerClass forClass:(Class)objectClass {
    classesToRegisteredSections[(id<NSCopying>)objectClass] = explorerClass;
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row  {
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
        case FLEXGlobalsRowURLSession:
            return @"📡  NSURLSession.sharedSession";
        case FLEXGlobalsRowURLCache:
            return @"⏳  NSURLCache.sharedURLCache";
        case FLEXGlobalsRowNotificationCenter:
            return @"🔔  NSNotificationCenter.defaultCenter";
        case FLEXGlobalsRowMenuController:
            return @"📎  UIMenuController.sharedMenuController";
        case FLEXGlobalsRowFileManager:
            return @"🗄  NSFileManager.defaultManager";
        case FLEXGlobalsRowTimeZone:
            return @"🌎  NSTimeZone.systemTimeZone";
        case FLEXGlobalsRowLocale:
            return @"🗣  NSLocale.currentLocale";
        case FLEXGlobalsRowCalendar:
            return @"📅  NSCalendar.currentCalendar";
        case FLEXGlobalsRowMainRunLoop:
            return @"🏃🏻‍♂️  NSRunLoop.mainRunLoop";
        case FLEXGlobalsRowMainThread:
            return @"🧵  NSThread.mainThread";
        case FLEXGlobalsRowOperationQueue:
            return @"📚  NSOperationQueue.mainQueue";
        default: return nil;
    }
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row  {
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
            case FLEXGlobalsRowURLSession:
            return [self explorerViewControllerForObject:NSURLSession.sharedSession];
        case FLEXGlobalsRowURLCache:
            return [self explorerViewControllerForObject:NSURLCache.sharedURLCache];
        case FLEXGlobalsRowNotificationCenter:
            return [self explorerViewControllerForObject:NSNotificationCenter.defaultCenter];
        case FLEXGlobalsRowMenuController:
            return [self explorerViewControllerForObject:UIMenuController.sharedMenuController];
        case FLEXGlobalsRowFileManager:
            return [self explorerViewControllerForObject:NSFileManager.defaultManager];
        case FLEXGlobalsRowTimeZone:
            return [self explorerViewControllerForObject:NSTimeZone.systemTimeZone];
        case FLEXGlobalsRowLocale:
            return [self explorerViewControllerForObject:NSLocale.currentLocale];
        case FLEXGlobalsRowCalendar:
            return [self explorerViewControllerForObject:NSCalendar.currentCalendar];
        case FLEXGlobalsRowMainRunLoop:
            return [self explorerViewControllerForObject:NSRunLoop.mainRunLoop];
        case FLEXGlobalsRowMainThread:
            return [self explorerViewControllerForObject:NSThread.mainThread];
        case FLEXGlobalsRowOperationQueue:
            return [self explorerViewControllerForObject:NSOperationQueue.mainQueue];

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

+ (FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowRootViewController: {
            // Check if the app delegate responds to -window. If not, present an alert
            return ^(UITableViewController *host) {
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
