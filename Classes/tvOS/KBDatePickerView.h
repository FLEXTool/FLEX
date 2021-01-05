#import <UIKit/UIKit.h>
#import "Macros.h"
#define NUMBER_OF_CELLS 100000

#define TABLE_TAG(XX) \
XX(KBTableViewTagMonths, = 501) \
XX(KBTableViewTagDays, )\
XX(KBTableViewTagYears, )\
XX(KBTableViewTagHours, )\
XX(KBTableViewTagMinutes, )\
XX(KBTableViewTagAMPM, )\
XX(KBTaleViewWeekday, )
DECLARE_ENUM(KBTableViewTag, TABLE_TAG)

#define PICKER_MODE(XX) \
XX(KBDatePickerModeTime, ) \
XX(KBDatePickerModeDate, ) \
XX(KBDatePickerModeDateAndTime, ) \
XX(KBDatePickerModeCountDownTimer, )
DECLARE_ENUM(KBDatePickerMode, PICKER_MODE)

@interface UIView (Helper)
-(void)removeAllSubviews;
@end

@interface UIStackView (Helper)
- (void)removeAllArrangedSubviews;
- (void)setArrangedViews:(NSArray * _Nonnull )views;
@end

@interface KBTableView: UITableView
@property NSIndexPath * _Nullable selectedIndexPath;
@property CGFloat customWidth;
@property id _Nullable selectedValue;
- (instancetype _Nonnull )initWithTag:(KBTableViewTag)tag delegate:(id _Nonnull )delegate;
- (id _Nullable )valueForIndexPath:(NSIndexPath *_Nonnull)indexPath;
- (NSArray *_Nonnull)visibleValues;
@end

 // Enums are all defined like this to make it easier to convert them to / from string versions of themselves.
 
@interface KBDatePickerView: UIControl <UITableViewDelegate, UITableViewDataSource>
@property (nonnull, nonatomic, strong) NSDate *date;
@property (nullable, nonatomic, strong) NSDate *minimumDate;
@property (nullable, nonatomic, strong) NSDate *maximumDate;
@property BOOL showDateLabel;
@property KBDatePickerMode datePickerMode;
@property NSInteger topOffset;
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(NSDate * _Nullable date);
+(id _Nonnull )todayInYear:(NSInteger)year;
+ (NSDateFormatter * _Nonnull )sharedDateFormatter;
@end

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"[KBDatePickerView] %@ %@", self, NSStringFromSelector(_cmd))
#define DPLog(format, ...) NSLog(@"[KBDatePickerView] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
