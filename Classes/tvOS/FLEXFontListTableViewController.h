#import <UIKit/UIKit.h>

@interface FLEXFontListTableViewController : UITableViewController
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSString * _Nullable fontName);
@end
