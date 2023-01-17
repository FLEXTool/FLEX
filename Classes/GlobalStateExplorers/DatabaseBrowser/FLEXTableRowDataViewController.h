//
//  FLEXTableRowDataViewController.h
//  FLEX
//
//  Created by Chaoshuai Lu on 7/8/20.
//

#import "Classes/Headers/FLEXFilteringTableViewController.h"

@interface FLEXTableRowDataViewController : FLEXFilteringTableViewController

+ (instancetype)rows:(NSDictionary<NSString *, id> *)rowData;

@end
