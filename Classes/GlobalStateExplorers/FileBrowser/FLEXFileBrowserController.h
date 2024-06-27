//
//  FLEXFileBrowserController.h
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//  Based on previous work by Evan Doll
//

#import "FLEXTableViewController.h"
#import "FLEXGlobalsEntry.h"

@interface FLEXFileBrowserController : FLEXTableViewController <FLEXGlobalsEntry>

+ (instancetype)path:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@end
