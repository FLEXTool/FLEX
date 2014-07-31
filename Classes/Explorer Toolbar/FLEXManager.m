//
//  FLEXManager.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXWindow.h"
#import "FLEXGlobalsTableViewControllerEntry.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"

@interface FLEXManager () <FLEXWindowEventDelegate, FLEXExplorerViewControllerDelegate>

@property (nonatomic, strong) FLEXWindow *explorerWindow;
@property (nonatomic, strong) FLEXExplorerViewController *explorerViewController;

@property (nonatomic, readonly, strong) NSMutableArray *userGlobalEntries;

@end

@implementation FLEXManager

+ (instancetype)sharedManager
{
    static FLEXManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.explorerWindow = [[FLEXWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.explorerWindow.eventDelegate = self;
        
        _userGlobalEntries = [[NSMutableArray alloc] init];
        
        self.explorerViewController = [[FLEXExplorerViewController alloc] init];
        self.explorerViewController.delegate = self;
        self.explorerWindow.rootViewController = self.explorerViewController;
        [self.explorerWindow addSubview:self.explorerViewController.view];
    }
    return self;
}

- (void)showExplorer
{
    self.explorerWindow.hidden = NO;
}

- (void)hideExplorer
{
    self.explorerWindow.hidden = YES;
}

- (BOOL)isHidden
{
    return self.explorerWindow.isHidden;
}


#pragma mark - FLEXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow
{
    // Ask the explorer view controller
    return [self.explorerViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}


#pragma mark - FLEXExplorerViewControllerDelegate

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController
{
    [self hideExplorer];
}


#pragma mark - Extensions

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock
{
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsTableViewControllerEntry *entry = [FLEXGlobalsTableViewControllerEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

@end
