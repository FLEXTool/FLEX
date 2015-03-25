//
//  FLEXClassExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/18/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXClassExplorerViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXInstancesTableViewController.h"

typedef NS_ENUM(NSUInteger, FLEXClassExplorerRow) {
    FLEXClassExplorerRowNew,
    FLEXClassExplorerRowAlloc,
    FLEXClassExplorerRowLiveInstances
};

@interface FLEXClassExplorerViewController ()

@property (nonatomic, readonly) Class theClass;

@end

@implementation FLEXClassExplorerViewController

- (Class)theClass
{
    Class theClass = Nil;
    if (class_isMetaClass(object_getClass(self.object))) {
        theClass = self.object;
    }
    return theClass;
}

#pragma mark - Superclass Overrides

- (NSArray *)possibleExplorerSections
{
    // Move class methods to between our custom section and the properties section since
    // we are more interested in the class sections than in the instance level sections.
    NSMutableArray *mutableSections = [[super possibleExplorerSections] mutableCopy];
    [mutableSections removeObject:@(FLEXObjectExplorerSectionClassMethods)];
    [mutableSections insertObject:@(FLEXObjectExplorerSectionClassMethods) atIndex:[mutableSections indexOfObject:@(FLEXObjectExplorerSectionProperties)]];
    return mutableSections;
}

- (NSString *)customSectionTitle
{
    return @"Shortcuts";
}

- (NSArray *)customSectionRowCookies
{
    NSMutableArray *cookies = [NSMutableArray array];
    if ([self.theClass respondsToSelector:@selector(new)]) {
        [cookies addObject:@(FLEXClassExplorerRowNew)];
    }
    if ([self.theClass respondsToSelector:@selector(alloc)]) {
        [cookies addObject:@(FLEXClassExplorerRowAlloc)];
    }
    [cookies addObject:@(FLEXClassExplorerRowLiveInstances)];
    return cookies;
}

- (NSString *)customSectionTitleForRowCookie:(id)rowCookie
{
    NSString *title = nil;
    FLEXClassExplorerRow row = [rowCookie unsignedIntegerValue];
    switch (row) {
        case FLEXClassExplorerRowNew:
            title = @"+ (id)new";
            break;
            
        case FLEXClassExplorerRowAlloc:
            title = @"+ (id)alloc";
            break;
            
        case FLEXClassExplorerRowLiveInstances:
            title = @"Live Instances";
            break;
    }
    return title;
}

- (NSString *)customSectionSubtitleForRowCookie:(id)rowCookie
{
    return nil;
}

- (BOOL)customSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    return YES;
}

- (UIViewController *)customSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    UIViewController *drillInViewController = nil;
    FLEXClassExplorerRow row = [rowCookie unsignedIntegerValue];
    switch (row) {
        case FLEXClassExplorerRowNew:
            drillInViewController = [[FLEXMethodCallingViewController alloc] initWithTarget:self.theClass method:class_getClassMethod(self.theClass, @selector(new))];
            break;
            
        case FLEXClassExplorerRowAlloc:
            drillInViewController = [[FLEXMethodCallingViewController alloc] initWithTarget:self.theClass method:class_getClassMethod(self.theClass, @selector(alloc))];
            break;
            
        case FLEXClassExplorerRowLiveInstances:
            drillInViewController = [FLEXInstancesTableViewController instancesTableViewControllerForClassName:NSStringFromClass(self.theClass)];
            break;
    }
    return drillInViewController;
}

- (BOOL)shouldShowDescription
{
    // Redundant with our title.
    return NO;
}

- (BOOL)canCallInstanceMethods
{
    return NO;
}

- (BOOL)canHaveInstanceState
{
    return NO;
}

@end
