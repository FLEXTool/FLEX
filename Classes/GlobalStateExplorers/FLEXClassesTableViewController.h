//
//  FLEXClassesTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <FLEX/FLEXTableViewController.h>
#import <FLEX/FLEXGlobalsEntry.h>

@interface FLEXClassesTableViewController : FLEXTableViewController <FLEXGlobalsEntry>

@property (nonatomic, copy) NSString *binaryImageName;

@end
