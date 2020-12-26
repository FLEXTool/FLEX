#import <UIKit/UIKit.h>

@interface KBDatePickerView: UIView <UITableViewDelegate, UITableViewDataSource>
@property NSDate * _Nonnull date;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
@end
