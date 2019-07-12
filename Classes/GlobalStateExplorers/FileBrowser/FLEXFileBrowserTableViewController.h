//
//  FLEXFileBrowserTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//  Based on previous work by Evan Doll
//

#import "FLEXTableViewController.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXFileBrowserSearchOperation.h"

@interface FLEXFileBrowserTableViewController : FLEXTableViewController <FLEXGlobalsEntry>

- (id)initWithPath:(NSString *)path;

@end
