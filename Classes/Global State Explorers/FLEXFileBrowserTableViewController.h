//
//  FLEXFileBrowserTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 6/9/14.
//  Based on previous work by Evan Doll
//

#import <UIKit/UIKit.h>

#import "FLEXFileBrowserSearchOperation.h"

@interface FLEXFileBrowserTableViewController : UITableViewController <UISearchDisplayDelegate, FLEXFileBrowserSearchOperationDelegate>

- (id)initWithPath:(NSString *)path;

@end
