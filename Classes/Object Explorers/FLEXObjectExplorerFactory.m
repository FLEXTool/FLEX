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

@implementation FLEXObjectExplorerFactory

+ (FLEXObjectExplorerViewController *)explorerViewControllerForObject:(id)object
{
    // Bail for nil object. We can't explore nil.
    if (!object) {
        return nil;
    }
    
    static NSDictionary *explorerSubclassesForObjectTypeStrings = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        explorerSubclassesForObjectTypeStrings = @{NSStringFromClass([NSArray class])          : [FLEXArrayExplorerViewController class],
                                                   NSStringFromClass([NSSet class])            : [FLEXSetExplorerViewController class],
                                                   NSStringFromClass([NSDictionary class])     : [FLEXDictionaryExplorerViewController class],
                                                   NSStringFromClass([NSUserDefaults class])   : [FLEXDefaultsExplorerViewController class],
                                                   NSStringFromClass([UIViewController class]) : [FLEXViewControllerExplorerViewController class]};
    });
    
    Class explorerClass = [FLEXObjectExplorerViewController class];
    for (NSString *objectTypeString in explorerSubclassesForObjectTypeStrings) {
        Class objectClass = NSClassFromString(objectTypeString);
        if ([object isKindOfClass:objectClass]) {
            explorerClass = [explorerSubclassesForObjectTypeStrings objectForKey:objectTypeString];
            break;
        }
    }
    
    FLEXObjectExplorerViewController *explorerViewController = [[explorerClass alloc] init];
    explorerViewController.object = object;
    
    return explorerViewController;
}

@end
