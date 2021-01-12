#import <UIKit/UIKit.h>
#import "Macros.h"
#define NUMBER_OF_CELLS 100000

// Enums are all defined like this to make it easier to convert them to / from string versions of themselves.
#define TABLE_TAG(XX) \
XX(KBTableViewTagMonths, = 501) \
XX(KBTableViewTagDays, )\
XX(KBTableViewTagYears, )\
XX(KBTableViewTagHours, )\
XX(KBTableViewTagMinutes, )\
XX(KBTableViewTagAMPM, )\
XX(KBTableViewTagWeekday, )\
XX(KBTableViewTagCDHours,)\
XX(KBTableViewTagCDMinutes,)\
XX(KBTableViewTagCDSeconds,)
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
@end
 
@interface KBDatePickerView: UIControl <UITableViewDelegate, UITableViewDataSource>

@property (nullable, nonatomic, strong) NSLocale *locale;   // default is [NSLocale currentLocale]. setting nil returns to default
@property (null_resettable, nonatomic, copy) NSCalendar *calendar; // default is [NSCalendar currentCalendar]. setting nil returns to default
@property (nullable, nonatomic, strong) NSTimeZone *timeZone; // default is nil. use current time zone or time zone from calendar

@property (nonnull, nonatomic, strong) NSDate *date;
@property (nullable, nonatomic, strong) NSDate *minimumDate;
@property (nullable, nonatomic, strong) NSDate *maximumDate;

@property (nonatomic) NSTimeInterval countDownDuration; // for KBDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59 (86,399 seconds). value being set is div 60 (drops remaining seconds).
@property (nonatomic) NSInteger minuteInterval;    // display minutes wheel with interval. interval must be evenly divided into 60. default is 1. min is 1, max is 30 (***not used yet***)

@property BOOL showDateLabel; //defaults to false - whether or not to show a label below the picker for a pretty printed version of the date
@property KBDatePickerMode datePickerMode;
@property NSInteger topOffset;
@property BOOL hybridLayout; //if set to hybrid, we allow manual layout for the width of our view
+(id _Nonnull )todayInYear:(NSInteger)year;
+(NSDateFormatter * _Nonnull )sharedDateFormatter;
-(instancetype _Nonnull )initWithHybridLayout:(BOOL)hybrid;
@end
#define DPLog(format, ...) NSLog(@"[KBDatePickerView] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
