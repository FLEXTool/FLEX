//
//  FLEXGlobalsViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXFilteringTableViewController.h"
@class FLEXGlobalsEntry;
@protocol FLEXGlobalsTableViewControllerDelegate;

typedef NS_ENUM(NSUInteger, FLEXGlobalsSectionKind) {
    FLEXGlobalsSectionCustom,
    /// NSProcessInfo, Network history, system log,
    /// heap, address explorer, libraries, app classes
    FLEXGlobalsSectionProcessAndEvents,
    /// Browse container, browse bundle, NSBundle.main,
    /// NSUserDefaults.standard, UIApplication,
    /// app delegate, key window, root VC, cookies
    FLEXGlobalsSectionAppShortcuts,
    /// UIPasteBoard.general, UIScreen, UIDevice
    FLEXGlobalsSectionMisc,
    FLEXGlobalsSectionCount
};

@interface FLEXGlobalsViewController : FLEXFilteringTableViewController

@property (nonatomic, nonnull) NSArray<FLEXGlobalsEntry *> *customEntries;

@end
