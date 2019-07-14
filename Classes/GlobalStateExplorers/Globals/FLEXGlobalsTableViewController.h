//
//  FLEXGlobalsTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"
@protocol FLEXGlobalsTableViewControllerDelegate;

typedef NS_ENUM(NSUInteger, FLEXGlobalsSection) {
    /// NSProcessInfo, Network history, system log,
    /// heap, address explorer, libraries, app classes
    FLEXGlobalsSectionProcessAndEvents,
    /// Browse container, browse bundle, NSBundle.main,
    /// NSUserDefaults.standard, UIApplication,
    /// app delegate, key window, root VC, cookies
    FLEXGlobalsSectionAppShortcuts,
    /// UIPasteBoard.general, UIScreen, UIDevice
    FLEXGlobalsSectionMisc,
    FLEXGlobalsSectionCustom,
    FLEXGlobalsSectionCount
};

@interface FLEXGlobalsTableViewController : FLEXTableViewController

@property (nonatomic, weak) id <FLEXGlobalsTableViewControllerDelegate> delegate;

/// We pretend that one of the app's windows is still the key window, even though the explorer window may have become key.
/// We want to display debug state about the application, not about this tool.
+ (void)setApplicationWindow:(UIWindow *)applicationWindow;

@end

@protocol FLEXGlobalsTableViewControllerDelegate <NSObject>

- (void)globalsViewControllerDidFinish:(FLEXGlobalsTableViewController *)globalsViewController;

@end
