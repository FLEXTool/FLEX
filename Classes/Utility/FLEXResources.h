//
//  FLEXResources.h
//  FLEX
//
//  Created by Ryan Olson on 6/8/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
typedef NSImage FLEXResourceImage;
typedef NSColor FLEXResourceColor;
#else
#import <UIKit/UIKit.h>
typedef UIImage FLEXResourceImage;
typedef UIColor FLEXResourceColor;
#endif

@interface FLEXResources : NSObject

#pragma mark - FLEX Toolbar Icons

@property (readonly, class) FLEXResourceImage *closeIcon;
@property (readonly, class) FLEXResourceImage *dragHandle;
@property (readonly, class) FLEXResourceImage *globalsIcon;
@property (readonly, class) FLEXResourceImage *hierarchyIcon;
@property (readonly, class) FLEXResourceImage *recentIcon;
@property (readonly, class) FLEXResourceImage *moveIcon;
@property (readonly, class) FLEXResourceImage *selectIcon;

#pragma mark - Toolbar Icons

@property (readonly, class) FLEXResourceImage *bookmarksIcon;
@property (readonly, class) FLEXResourceImage *openTabsIcon;
@property (readonly, class) FLEXResourceImage *moreIcon;
@property (readonly, class) FLEXResourceImage *gearIcon;
@property (readonly, class) FLEXResourceImage *scrollToBottomIcon;

#pragma mark - Content Type Icons

@property (readonly, class) FLEXResourceImage *jsonIcon;
@property (readonly, class) FLEXResourceImage *textPlainIcon;
@property (readonly, class) FLEXResourceImage *htmlIcon;
@property (readonly, class) FLEXResourceImage *audioIcon;
@property (readonly, class) FLEXResourceImage *jsIcon;
@property (readonly, class) FLEXResourceImage *plistIcon;
@property (readonly, class) FLEXResourceImage *textIcon;
@property (readonly, class) FLEXResourceImage *videoIcon;
@property (readonly, class) FLEXResourceImage *xmlIcon;
@property (readonly, class) FLEXResourceImage *binaryIcon;

#pragma mark - 3D Explorer Icons

@property (readonly, class) FLEXResourceImage *toggle2DIcon;
@property (readonly, class) FLEXResourceImage *toggle3DIcon;
@property (readonly, class) FLEXResourceImage *rangeSliderLeftHandle;
@property (readonly, class) FLEXResourceImage *rangeSliderRightHandle;
@property (readonly, class) FLEXResourceImage *rangeSliderTrack;
@property (readonly, class) FLEXResourceImage *rangeSliderFill;

#pragma mark - Misc Icons

@property (readonly, class) FLEXResourceImage *checkerPattern;
@property (readonly, class) FLEXResourceColor *checkerPatternColor;
@property (readonly, class) FLEXResourceImage *hierarchyIndentPattern;

@end
