//
//  FLEXClassesTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"
#import "FLEXGlobalsEntry.h"

@interface FLEXClassesTableViewController : FLEXTableViewController <FLEXGlobalsEntry>

+ (instancetype)binaryImageName:(NSString *)binaryImageName;

@end
