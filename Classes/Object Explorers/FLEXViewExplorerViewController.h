//
//  FLEXViewExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 6/11/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXObjectExplorerViewController.h"

@interface FLEXViewExplorerViewController : FLEXObjectExplorerViewController

/// Array of NSStrings that match property names on the view we're exploring.
/// Subclasses can override to modify or append properties that should show up in the custom "shortcuts" section.
- (NSArray *)shortcutPropertyNames;

@end
