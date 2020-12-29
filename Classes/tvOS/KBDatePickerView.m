#import "KBDatePickerView.h"

#define STACK_VIEW_HEIGHT 128
DEFINE_ENUM(KBTableViewTag, TABLE_TAG)
DEFINE_ENUM(KBDatePickerMode, PICKER_MODE)

@implementation NSString (format)
+ (id)kb_stringWithFormat:(const char*) fmt,...{
    va_list args;
    char temp[2048];
    va_start(args, fmt);
    vsprintf(temp, fmt, args);
    va_end(args);
    return [[NSString alloc] initWithUTF8String:temp];
}
@end

@interface UITableView (yep)
- (NSIndexPath *)_focusedCellIndexPath;
@end

@implementation UIView (Helper)

- (void)removeAllSubviews {
    [[self subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

@end

@implementation UIStackView (Helper)

- (void)removeAllArrangedSubviews {
    [[self arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj respondsToSelector:@selector(removeAllArrangedSubviews)]){
            [obj removeAllArrangedSubviews];
        }
        [self removeArrangedSubview:obj];
    }];
}

- (void)setArrangedViews:(NSArray *)views {
    if ([self arrangedSubviews].count > 0){
        [self removeAllArrangedSubviews];
    }
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addArrangedSubview:obj];
    }];
}

@end

@interface KBTableView(){
    NSIndexPath *_selectedIndexPath;
}
@end
@implementation KBTableView

- (instancetype)initWithTag:(KBTableViewTag)tag delegate:(id)delegate {
    self = [super initWithFrame:CGRectZero style:UITableViewStylePlain];
    if (self){
        self.tag = tag;
        self.dataSource = delegate;
        self.delegate = delegate;
    }
    return self;
}

- (NSArray *)visibleValues {
    __block NSMutableArray *visibleValues = [NSMutableArray new];
    [self.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *value = obj.textLabel.text;
        [visibleValues addObject:value];
    }];
    return visibleValues;;
}

- (NSIndexPath *)selectedIndexPath {
    return _selectedIndexPath;
}

- (id)valueForIndexPath:(NSIndexPath *)indexPath {
    return [self cellForRowAtIndexPath:indexPath].textLabel.text;
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    _selectedIndexPath = selectedIndexPath;
    id value = [self valueForIndexPath:selectedIndexPath];
    if (value){
        //DPLog(@"found cell in %lu", self.tag);
        _selectedValue = value;
        //DPLog(@"selected value set: %@ for index; %lu", _selectedValue, selectedIndexPath.row);
    }
}

@end

@interface KBDatePickerView () {
    NSDate *_currentDate;
    NSDate *_minimumDate;
    NSDate *_maximumDate;
    NSArray *_tableViews;
    BOOL _pmSelected;
    NSMutableDictionary *_selectedRowData;
    KBDatePickerMode _datePickerMode;
    NSInteger _minYear;
    NSInteger _maxYear;
    NSInteger _yearSelected;
    NSInteger _monthSelected;
    NSInteger _daySelected;
    NSInteger _hourSelected;
    NSInteger _minuteSelected;
    NSInteger _currentMonthDayCount; //current months
}

@property (nonatomic, strong) NSArray *hourData;
@property (nonatomic, strong) NSArray *minutesData;
@property (nonatomic, strong) NSArray *dayData;
@property UIStackView *datePickerStackView;
@property KBTableView *monthTable;
@property KBTableView *dayTable;
@property KBTableView *yearTable;
@property KBTableView *hourTable;
@property KBTableView *minuteTable;
@property KBTableView *amPMTable;
@property UILabel *monthLabel;
@property UILabel *dayLabel;
@property UILabel *yearLabel;
@property UILabel *datePickerLabel;
@property NSLayoutConstraint *widthConstraint;
@property UILabel *unsupportedLabel;
@end

@implementation KBDatePickerView

- (void)menuGestureRecognized:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        id superview = [self superview];
        if ([superview respondsToSelector:@selector(delegate)]){
            UIViewController *vc = [superview delegate];
            DPLog(@"delegateView: %@", vc);
            [vc setNeedsFocusUpdate];
            [vc updateFocusIfNeeded];
        }
        
        /*
         //[self setPreferredFocusedItem:self.toggleTypeButton]; //PRIVATE_API call, trying to avoid those to stay app store friendly!
         UIApplication *sharedApp = [UIApplication sharedApplication];
         #pragma clang diagnostic push
         #pragma clang diagnostic ignored "-Wdeprecated-declarations"
         UIWindow *window = [sharedApp keyWindow];
         #pragma clang diagnostic pop
         UIViewController *rootViewController = [window rootViewController];
         if (rootViewController.view == self.superview){
         [rootViewController setNeedsFocusUpdate];
         [rootViewController updateFocusIfNeeded];
         } */
    }
    
}

+ (NSDateFormatter *)sharedDateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *shared = nil;
    if(shared == nil) {
        dispatch_once(&onceToken, ^{
            shared = [[NSDateFormatter alloc] init];
            [shared setTimeZone:[NSTimeZone localTimeZone]];
            [shared setDateFormat:@"E, MMM d, yyyy h:mm a"];
        });
    }
    return shared;
}



- (NSDateComponents *)currentComponents:(NSCalendarUnit)unitFlags {
    return [[self calendar] components:unitFlags fromDate:self.date];
}


- (NSDate *)date {
    if (!_currentDate){
        [self setDate:[NSDate date]];
    }
    return _currentDate;
}

- (NSCalendar *)calendar {
    return [NSCalendar currentCalendar];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated {
    _currentDate = date;
    [self scrollToCurrentDateAnimated:animated];
}

- (void)setMinimumDate:(NSDate *)minimumDate {
    _minimumDate = minimumDate;
    [self populateYearsForDateRange];
}

- (NSDate *)minimumDate {
    return _minimumDate;
}

- (NSDate *)maximumDate {
    return _maximumDate;
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    _maximumDate = maximumDate;
    [self populateYearsForDateRange];
}

- (void)setDate:(NSDate *)date {
    _currentDate = date;
    [self setDate:date animated:true];
}

- (BOOL)isEnabled {
    return FALSE;
}

- (id)init {
    self = [super init];
    _pmSelected = false;
    _showDateLabel = true;
    if (![self date]){
        [self setDate:[NSDate date]];
    }
    _topOffset = 80;
    UITapGestureRecognizer *menuTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuGestureRecognized:)];
    menuTap.numberOfTapsRequired = 1;
    menuTap.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self addGestureRecognizer:menuTap];
    _selectedRowData = [NSMutableDictionary new];
    _datePickerMode = KBDatePickerModeDate;
    [self layoutViews];
    return self;
}

- (void)layoutForTime {
    
    if (self.hourTable){
        [self.hourTable removeFromSuperview];
        self.hourTable = nil;
        [self.minuteTable removeFromSuperview];
        self.minuteTable = nil;
        [self.amPMTable removeFromSuperview];
        self.amPMTable = nil;
        _tableViews = nil;
    }
    
    [self setupTimeData];
    self.hourTable = [[KBTableView alloc] initWithTag:KBTableViewTagHours delegate:self];
    self.minuteTable = [[KBTableView alloc] initWithTag:KBTableViewTagMinutes delegate:self];
    self.amPMTable = [[KBTableView alloc] initWithTag:KBTableViewTagAMPM delegate:self];
    self.amPMTable.contentInset = UIEdgeInsetsMake(0, 0, 40, 0);
    _tableViews = @[_hourTable, _minuteTable, _amPMTable];
}

- (void)layoutForDate {
    
    if (self.monthLabel){
        [self.monthLabel removeFromSuperview];
        self.monthLabel = nil;
        [self.yearLabel removeFromSuperview];
        self.yearLabel = nil;
        [self.dayLabel removeFromSuperview];
        self.dayLabel = nil;
        self.monthTable = nil;
        self.yearTable = nil;
        self.dayTable = nil;
        _tableViews = nil;
    }
    
    [self populateDaysForCurrentMonth];
    [self populateYearsForDateRange];
    self.monthLabel = [[UILabel alloc] init];
    self.monthLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.monthLabel.text = @"Month";
    self.yearLabel = [[UILabel alloc] init];
    self.yearLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.yearLabel.text = @"Year";
    self.dayLabel = [[UILabel alloc] init];
    self.dayLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.dayLabel.text = @"Day";
    
    self.monthTable = [[KBTableView alloc] initWithTag:KBTableViewTagMonths delegate:self];
    self.yearTable = [[KBTableView alloc] initWithTag:KBTableViewTagYears delegate:self];
    self.dayTable = [[KBTableView alloc] initWithTag:KBTableViewTagDays delegate:self];
    _tableViews = @[_monthTable, _dayTable, _yearTable];
    [self addSubview:self.monthLabel];
    [self addSubview:self.yearLabel];
    [self addSubview:self.dayLabel];
}

- (void)layoutLabelsForDate {
    [self.monthLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:_topOffset].active = true;
    [self.dayLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:_topOffset].active = true;
    [self.dayLabel.centerXAnchor constraintEqualToAnchor:self.dayTable.centerXAnchor].active = true;
    [self.monthLabel.centerXAnchor constraintEqualToAnchor:self.monthTable.centerXAnchor].active = true;
    [self.yearLabel.centerXAnchor constraintEqualToAnchor:self.yearTable.centerXAnchor].active = true;
    [self.yearLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:_topOffset].active = true;
    [self.monthLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:_topOffset].active = true;
}

- (void)layoutUnsupportedView {
    
    if (_datePickerStackView != nil){
        [_datePickerStackView removeAllArrangedSubviews];
        [_datePickerStackView removeFromSuperview];
        _datePickerStackView = nil;
    }
    
    self.unsupportedLabel = [[UILabel alloc] init];
    [self addSubview:self.unsupportedLabel];
    self.unsupportedLabel.translatesAutoresizingMaskIntoConstraints = false;
    [self.unsupportedLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    [self.unsupportedLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    self.unsupportedLabel.text = [NSString kb_stringWithFormat:"Error: currently '%s' is an unsuppported configuration.", [NSStringFromKBDatePickerMode(self.datePickerMode) UTF8String]];
}

- (void)layoutForDateAndTime {
    [self layoutUnsupportedView];
}

- (void)layoutForCountdownTimer {
    [self layoutUnsupportedView];
}

- (void)layoutLabelsForTime {
    
}

- (void)setupLabelsForMode {
    switch (self.datePickerMode) {
        case KBDatePickerModeTime:
            [self layoutLabelsForTime];
            break;
            
        case KBDatePickerModeDate:
            [self layoutLabelsForDate];
            break;
            
        case KBDatePickerModeDateAndTime:
            [self layoutForDateAndTime];
            break;
            
        case KBDatePickerModeCountDownTimer:
            [self layoutForCountdownTimer];
            break;
            
        default:
            break;
    }
}


- (void)viewSetupForMode {
    
    if (self.unsupportedLabel){
        [self.unsupportedLabel removeFromSuperview];
        self.unsupportedLabel = nil;
    }
    switch (self.datePickerMode) {
        case KBDatePickerModeTime:
            [self layoutForTime];
            break;
            
        case KBDatePickerModeDate:
            [self layoutForDate];
            break;
            
        case KBDatePickerModeDateAndTime:
            [self layoutForDateAndTime];
            break;
            
        case KBDatePickerModeCountDownTimer:
            [self layoutForCountdownTimer];
            break;
            
        default:
            break;
    }
}

- (NSArray *)createNumberArray:(NSInteger)count zeroIndex:(BOOL)zeroIndex leadingZero:(BOOL)leadingZero {
    __block NSMutableArray *_newArray = [NSMutableArray new];
    int startIndex = 1;
    if (zeroIndex){
        startIndex = 0;
    }
    for (int i = startIndex; i < count+startIndex; i++){
        if (leadingZero){
            [_newArray addObject:[NSString kb_stringWithFormat:"%02i", i]];
        } else {
            [_newArray addObject:[NSString kb_stringWithFormat:"%i", i]];
        }
    }
    return _newArray;
}
- (NSArray *)monthData {
    return [[self calendar] monthSymbols];
}

- (void)scrollToCurrentDateAnimated:(BOOL)animated {
    
    if (self.datePickerMode == KBDatePickerModeTime){
        [self loadTimeFromDateAnimated:animated];
    } else {
        NSDateComponents *components = [self currentComponents:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay];
        NSInteger monthIndex = components.month-1;
        NSString *monthSymbol = self.monthData[monthIndex];
        if (![self.monthTable.selectedValue isEqualToString:monthSymbol]){
            [self scrollToValue:monthSymbol inTableViewType:KBTableViewTagMonths animated:animated];
        }
        NSInteger dayIndex = components.day;
        NSString *dayString = [NSString kb_stringWithFormat:"%i",dayIndex];
        if (![[_dayTable selectedValue] isEqualToString:dayString]){
            [self scrollToValue:dayString inTableViewType:KBTableViewTagDays animated:animated];
        }
        NSInteger yearIndex = components.year-1;
        //DPLog(@"year index: %lu", yearIndex);
        NSString *yearString = [NSString kb_stringWithFormat:"%i",yearIndex];
        //DPLog(@"year index: %@", yearString);
        if (![[_yearTable selectedValue] isEqualToString:yearString]){
            _yearSelected = yearIndex;
            [self scrollToValue:yearString inTableViewType:KBTableViewTagYears animated:animated];
        }
        [self delayedUpdateFocus];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _monthTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _dayTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _hourTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _minuteTable){
        return [self infiniteNumberOfRowsInSection:section];
    } else if (tableView == _amPMTable){
        return 2;
    } else if (tableView == _yearTable){
        return _maxYear - _minYear;
    }
    return 0;
}

+(id)todayInYear:(NSInteger)year {
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    dc.year = year;
    return [[NSCalendar currentCalendar] dateFromComponents:dc];
}

- (void)updateDetailsIfContinuous:(NSIndexPath *)indexPath inTable:(KBTableView *)tableView {
    NSDateComponents *components = [self currentComponents:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute];
    NSArray *dataSource = nil;
    NSInteger normalizedIndex = NSNotFound;
    if (tableView == _monthTable){
        dataSource = self.monthData;
        normalizedIndex = indexPath.row % dataSource.count;
        //DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, [dataSource objectAtIndex: normalizedIndex]);
        components.month = normalizedIndex + 1;
        _monthSelected = components.month;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _dayTable){
        dataSource = self.dayData;
        normalizedIndex = indexPath.row % dataSource.count;
        //DPLog(@"_dayTable normalizedIndex: %lu s: %@", normalizedIndex, [dataSource objectAtIndex: normalizedIndex]);
        components.day = normalizedIndex + 1;
        _daySelected = components.day;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _minuteTable){
        dataSource = self.minutesData;
        normalizedIndex = indexPath.row % dataSource.count;
        //DPLog(@"_minuteTable normalizedIndex: %lu s: %@", normalizedIndex, [dataSource objectAtIndex: normalizedIndex]);
        components.minute = normalizedIndex;
        _minuteSelected = components.minute;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _hourTable){
        dataSource = self.hourData;
        normalizedIndex = indexPath.row % dataSource.count;
        //NSString *s = [dataSource objectAtIndex: normalizedIndex];
        if (_pmSelected){
            if (normalizedIndex != 11){
                normalizedIndex+=12;
            }
        } else {
            if (normalizedIndex == 11){
                normalizedIndex+=12;
            }
        }
        //DPLog(@"normalizedIndex: %lu s: %@", normalizedIndex, [dataSource objectAtIndex: normalizedIndex]);
        components.hour = normalizedIndex + 1;
        _hourSelected = components.hour;
        NSDate *newDate = [[self calendar] dateFromComponents:components];
        _currentDate = newDate; //set ivar so w dont set off any additional UI craziness.
    } else if (tableView == _yearTable){
        //NSInteger year = [[self calendar] component:NSCalendarUnitYear fromDate:self.date];
        NSInteger year = [_yearTable.selectedIndexPath row];
        NSInteger adjustment = 1;
        //DPLog(@"_minYear: %lu", _minYear);
        if (_minYear > 1){
            //DPLog(@"adjust the year, we dont start at 1!");
            adjustment = 0;
            year = [_yearTable.selectedValue integerValue];
        }
        //DPLog(@"year: %lu", year);
        components.year = year + adjustment;
        _yearSelected = components.year;
        NSDate *newDate = nil;
        do {
            newDate = [[self calendar] dateFromComponents:components];
            components.day -= 1;
        } while (newDate == nil || ([[self calendar] component:NSCalendarUnitMonth fromDate:newDate] != components.month));
        _currentDate = newDate;
    } else if (tableView == _amPMTable){
        BOOL previousState = _pmSelected;
        //DPLog(@"_hourSelected: %lu previousState: %d", _hourSelected, previousState);
        if (indexPath.row == 0){
            _pmSelected = false;
            if(_hourSelected != 0){
                if (previousState != _pmSelected){
                    components.hour-=12;
                    _hourSelected = components.hour;
                    NSDate *date = [[self calendar] dateFromComponents:components];
                    if (date){
                        _currentDate = date;
                    }
                }
            }
        } else if(indexPath.row == 1) {
            _pmSelected = true;
            if(_hourSelected != 0 && previousState != _pmSelected){
                components.hour+=12;
                _hourSelected = components.hour;
                NSDate *date = [[self calendar] dateFromComponents:components];
                if (date){
                    _currentDate = date;
                }
            }
        }
    }
    [self selectionOccured];
}

- (void)selectMonthAtIndex:(NSInteger)index {
    NSDateComponents *comp = [self currentComponents:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear];
    NSInteger adjustedIndex = index;
    if (index > self.monthData.count){
        adjustedIndex = index % self.monthData.count;
    }
    comp.month = adjustedIndex;
    [self setDate:[[self calendar] dateFromComponents:comp]];
    
}

- (BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == KBTableViewTagDays){
        NSInteger normalized = (indexPath.row % self.dayData.count) + 1;
        if (normalized > _currentMonthDayCount){
            return false;
        }
    }
    return true;
}

- (void)toggleMidnight {
    NSInteger index = 1;
    if (_pmSelected){
        index = 0;
    }
    [self.amPMTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:true scrollPosition:UITableViewScrollPositionTop];
    _pmSelected = !_pmSelected;
}

- (void)toggleMidnightIfNecessaryWithPrevious:(NSInteger)previousRow next:(NSInteger)nextRow {
    if (previousRow == 11 && nextRow == 12 && !_pmSelected){
        [self toggleMidnight];
    }
    if (previousRow == 12 && nextRow == 1 && !_pmSelected){
        [self toggleMidnight];
    }
}

- (BOOL)contextBrothers:(UITableViewFocusUpdateContext *)context {
    UIView *previousCell = context.previouslyFocusedView;
    UIView *newCell = context.nextFocusedView;
    return (previousCell.superview == newCell.superview);
    
}

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        
        NSIndexPath *nextIndexPath = context.nextFocusedIndexPath;
        KBTableView *table = (KBTableView *)tableView;
        if ([self contextBrothers:context]){
            if (table.tag == KBTableViewTagHours){
                NSIndexPath *previous = context.previouslyFocusedIndexPath;
                NSInteger previousRow = (previous.row % self.hourData.count)+1;
                NSInteger nextRow = (nextIndexPath.row % self.hourData.count)+1;
                if ((previousRow == 11 && nextRow == 12) || (previousRow == 12 && nextRow == 11)){
                    [self toggleMidnight];
                }
            }
        }
        if ([table respondsToSelector:@selector(setSelectedIndexPath:)]){
            if (nextIndexPath != nil){
                //DPLog(@"next ip: %lu table: %@", ip.row, NSStringFromKBTableViewTag((KBTableViewTag)tableView.tag));
                [table setSelectedIndexPath:nextIndexPath];
                [self updateDetailsIfContinuous:nextIndexPath inTable:table];
                if (tableView.tag == KBTableViewTagMonths){
                    [self populateDaysForCurrentMonth];
                }
            }
        }
        [tableView selectRowAtIndexPath:nextIndexPath animated:false scrollPosition:UITableViewScrollPositionTop];
        
    } completion:^{
        
    }];
}

- (NSInteger)infiniteNumberOfRowsInSection:(NSInteger)section {
    return NUMBER_OF_CELLS;
}

- (void)populateYearsForDateRange {
    
    _minYear = self.minimumDate != nil ? [[self calendar] component:NSCalendarUnitYear fromDate:self.minimumDate] : 1;
    _maxYear = self.maximumDate != nil ? [[self calendar] component:NSCalendarUnitYear fromDate:self.maximumDate] : NUMBER_OF_CELLS;
    //DPLog(@"minYear: %lu", _minYear);
    //DPLog(@"maxYear: %lu", _maxYear);
    //DPLog(@"selectedValue: %@", _yearTable.selectedValue);
    //DPLog(@"currentYear: %lu", _yearSelected);
    if (!_yearTable.selectedValue && _yearSelected != 0){
        if (_minYear > 1){
            NSInteger yearDifference = _yearSelected - _minYear;
            //DPLog(@"year difference: %lu", yearDifference);
            [self.yearTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:yearDifference inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:false];
        }
    }
    [self.yearTable reloadData];
    
}


- (void)populateDaysForCurrentMonth {
    NSRange days = [[self calendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date];
    _currentMonthDayCount = days.length; //this is used to push a date back if they've gone too far.
    if (!self.dayData){ //only need to populate it once
        self.dayData = [self createNumberArray:31 zeroIndex:false leadingZero:false];
        [self.dayTable reloadData];
    }
}

- (void)setupTimeData {
    self.hourData = [self createNumberArray:12 zeroIndex:false leadingZero:false];
    self.minutesData = [self createNumberArray:60 zeroIndex:true leadingZero:true];
}

- (NSInteger)startIndexForHours {
    return 24996;
}

- (NSInteger)startIndexForMinutes {
    return 24000;
}


- (void)loadTimeFromDateAnimated:(BOOL)animated {
    
    NSDateComponents *components = [self currentComponents:NSCalendarUnitHour | NSCalendarUnitMinute];
    NSInteger hour = components.hour;
    NSInteger minutes = components.minute;
    BOOL isPM = (hour >= 12);
    if (isPM){
        _pmSelected = true;
        hour = hour-12;
        NSIndexPath *amPMIndex = [NSIndexPath indexPathForRow:1 inSection:0];
        [self.amPMTable scrollToRowAtIndexPath:amPMIndex atScrollPosition:UITableViewScrollPositionTop animated:false];
    }
    NSString *hourValue = [NSString kb_stringWithFormat:"%lu", hour];
    NSString *minuteValue = [NSString kb_stringWithFormat:"%lu", minutes];
    DPLog(@"hours %@ minutes %@", hourValue, minuteValue);
    if (![[self.hourTable selectedValue] isEqualToString:hourValue]){
        [self scrollToValue:hourValue inTableViewType:KBTableViewTagHours animated:animated];
    }
    if (![[self.minuteTable selectedValue] isEqualToString:minuteValue]){
        [self scrollToValue:minuteValue inTableViewType:KBTableViewTagMinutes animated:animated];
    }
}

- (void)delayedUpdateFocus {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setNeedsFocusUpdate];
        [self updateFocusIfNeeded];
    });
}


- (void)scrollToValue:(id)value inTableViewType:(KBTableViewTag)type animated:(BOOL)animated {
    NSInteger foundIndex = NSNotFound;
    NSIndexPath *ip = nil;
    NSInteger dayCount = self.dayData.count;
    NSInteger relationalIndex = 0;
    CGFloat shiftIndex = 0.0;
    NSString *currentValue = nil;
    switch (type) {
        case KBTableViewTagHours:
            foundIndex = [self.hourData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForHours]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.hourTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [self.hourTable selectRowAtIndexPath:ip animated:animated scrollPosition:UITableViewScrollPositionTop];
                [self delayedUpdateFocus];
            }
            break;
            
        case KBTableViewTagMinutes:
            foundIndex = [self.minutesData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self startIndexForMinutes]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.minuteTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [self.minuteTable selectRowAtIndexPath:ip animated:animated scrollPosition:UITableViewScrollPositionTop];
                [self delayedUpdateFocus];
            }
            break;
            
        case KBTableViewTagMonths:
            currentValue = self.monthTable.selectedValue;
            relationalIndex = [self.monthData indexOfObject:currentValue];
            foundIndex = [self.monthData indexOfObject:value];
            if (foundIndex != NSNotFound){
                shiftIndex = foundIndex - relationalIndex;
                if (self.monthTable.selectedIndexPath && currentValue){
                    //DPLog(@"current value: %@ relationalIndex: %lu found index: %lu, shift index: %.0f", currentValue, relationalIndex, foundIndex, shiftIndex);
                    ip = [NSIndexPath indexPathForRow:self.monthTable.selectedIndexPath.row+shiftIndex inSection:0];
                } else {
                    ip = [NSIndexPath indexPathForRow:[self startIndexForHours]+foundIndex inSection:0];
                }
                [self.monthTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [_monthTable selectRowAtIndexPath:ip animated:animated scrollPosition:UITableViewScrollPositionTop];
                [self delayedUpdateFocus];
            }
            break;
            
        case KBTableViewTagDays:
            foundIndex = [self.dayData indexOfObject:value];
            if (foundIndex != NSNotFound){
                ip = [NSIndexPath indexPathForRow:[self indexForDays:dayCount]+foundIndex inSection:0];
                //DPLog(@"found index: %lu", ip.row);
                [self.dayTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
                [_dayTable selectRowAtIndexPath:ip animated:animated scrollPosition:UITableViewScrollPositionTop];
                [self delayedUpdateFocus];
            }
            break;
        case KBTableViewTagYears:
            foundIndex = [value integerValue];
            if (_minYear > 1){
                NSInteger intValue = [value integerValue];
                foundIndex = intValue - _minYear;
            }
            //DPLog(@"foundIndex: %lu from value:%@", foundIndex, value);
            ip = [NSIndexPath indexPathForRow:foundIndex inSection:0];
            [self.yearTable scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:animated];
            [self delayedUpdateFocus];
        default:
            break;
    }
}

- (NSInteger)indexForDays:(NSInteger)days {
    switch (days) {
        case 28: return 24976;
        case 29: return 24969;
        case 30: return 24990;
        case 31: return 24986;
    }
    return 25000;
}

- (UITableViewCell *)infiniteCellForTableView:(KBTableView *)tableView atIndexPath:(NSIndexPath *)indexPath dataSource:(NSArray *)dataSource {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    NSString *s = [dataSource objectAtIndex: indexPath.row % dataSource.count];
    [cell.textLabel setText: s];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}


- (UITableViewCell *)amPMCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"amPMCell";
    UITableViewCell *cell = [_amPMTable dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    if (indexPath.row == 0){
        cell.textLabel.text = @"AM";
    } else {
        cell.textLabel.text = @"PM";
    }
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (tableView == _hourTable){
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.hourData];
    } else if (tableView == _minuteTable) {
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.minutesData];
    } else if (tableView == _amPMTable) {
        return [self amPMCellForRowAtIndexPath:indexPath];
    } else if (tableView == _monthTable) {
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.monthData];
    } else if (tableView == _dayTable){
        return [self infiniteCellForTableView:(KBTableView*)tableView atIndexPath:indexPath dataSource:self.dayData];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"year"];
        if (!cell){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"year"];
        }
        if (_minYear > 1){
            cell.textLabel.text = [NSString kb_stringWithFormat:"%lu", _minYear+indexPath.row+1];
        } else {
            cell.textLabel.text = [NSString kb_stringWithFormat:"%lu", indexPath.row+1];
        }
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)selectionOccured {
    if (self.itemSelectedBlock){
        self.itemSelectedBlock(self.date);
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    if (self.showDateLabel){
        self.datePickerLabel.hidden = false;
        NSDateFormatter *dateFormatter = [KBDatePickerView sharedDateFormatter];
        NSString *strDate = [dateFormatter stringFromDate:self.date];
        DPLog(@"strDate: %@", strDate); // Result: strDate: 2014/05/19 10:51:50
        self.datePickerLabel.text = strDate;
    } else {
        self.datePickerLabel.hidden = true;
    }
}

- (id)valueForTableViewSelectedCell:(KBTableView *)tableView {
    id data = nil;
    if (!tableView.selectedIndexPath){
        return data;
    }
    switch (tableView.tag) {
        case KBTableViewTagMinutes:
            data = [self.minutesData objectAtIndex: tableView.selectedIndexPath.row % self.minutesData.count];
            break;
            
        case KBTableViewTagHours:
            data = [self.hourData objectAtIndex: tableView.selectedIndexPath.row % self.hourData.count];
            break;
            
        case KBTableViewTagMonths:
            data = [self.monthData objectAtIndex:tableView.selectedIndexPath.row % self.monthData.count];
            break;
        default:
            break;
    }
    
    return data;
}

- (KBDatePickerMode)datePickerMode {
    return _datePickerMode;
}

- (void)setDatePickerMode:(KBDatePickerMode)datePickerMode {
    _datePickerMode = datePickerMode;
    [self adaptModeChange];
}

- (void)adaptModeChange {
    [self removeAllSubviews];
    [self layoutViews];
}

- (CGSize)sizeThatFits:(CGSize)size {
    //CGSize sup = [super sizeThatFits:size];
    return CGSizeMake([self widthForMode], STACK_VIEW_HEIGHT+81+60+80);
}

- (CGFloat)widthForMode {
    switch (self.datePickerMode) {
        case KBDatePickerModeDate: return 720;
        case KBDatePickerModeTime: return 500;
        case KBDatePickerModeDateAndTime: return 800;
        case KBDatePickerModeCountDownTimer: return 400;
    }
    return 720;
}

- (void)layoutViews {
    
    [self viewSetupForMode];
    
    if (!_tableViews){
        DPLog(@"no table views, bail!!");
        return;
    }
    
    if (_datePickerStackView != nil){
        [_datePickerStackView removeAllArrangedSubviews];
        [_datePickerStackView removeFromSuperview];
        _datePickerStackView = nil;
    }
    
    self.datePickerStackView = [[UIStackView alloc] initWithArrangedSubviews:_tableViews];
    self.datePickerStackView.translatesAutoresizingMaskIntoConstraints = false;
    self.datePickerStackView.spacing = 10;
    self.datePickerStackView.axis = UILayoutConstraintAxisHorizontal;
    self.datePickerStackView.alignment = UIStackViewAlignmentFill;
    self.datePickerStackView.distribution = UIStackViewDistributionFillEqually;
    self.widthConstraint = [self.datePickerStackView.widthAnchor constraintEqualToConstant:self.widthForMode];
    self.widthConstraint.active = true;
    [self.datePickerStackView.heightAnchor constraintEqualToConstant:STACK_VIEW_HEIGHT].active = true;
    
    [self addSubview:self.datePickerStackView];
    
    [self.datePickerStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    //[self.datePickerStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    
    self.datePickerLabel = [[UILabel alloc] init];
    self.datePickerLabel.translatesAutoresizingMaskIntoConstraints = false;
    self.datePickerLabel.hidden = !_showDateLabel;
    [self addSubview:self.datePickerLabel];
    [self.datePickerLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = true;
    [self.datePickerLabel.topAnchor constraintEqualToAnchor:self.datePickerStackView.bottomAnchor constant:80].active = true;
    
    [self setupLabelsForMode];
    [self.datePickerStackView.topAnchor constraintEqualToAnchor:self.dayLabel.bottomAnchor constant:20].active = true;
    [self scrollToCurrentDateAnimated:false];
    
    
}

@end
