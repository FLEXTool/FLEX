//
//  FLEXFileBrowserController.h
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//  Based on previous work by Evan Doll
//

#import "Classes/Headers/FLEXTableViewController.h"
#import "Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h"
#import "Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserSearchOperation.h"

@interface FLEXFileBrowserController : FLEXTableViewController <FLEXGlobalsEntry>

+ (instancetype)path:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@end
