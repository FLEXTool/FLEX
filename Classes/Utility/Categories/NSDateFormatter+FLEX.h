//
//  NSDateFormatter+FLEX.h
//  libflex:FLEX
//
//  Created by Tanner Bennett on 7/24/22.
//  Copyright © 2022 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FLEXDateFormat) {
    // hour:minute [AM|PM]
    FLEXDateFormatClock,
    // hour:minute:second [AM|PM]
    FLEXDateFormatPreciseClock,
    // year-month-day hour:minute:second.millisecond
    FLEXDateFormatVerbose,
};

@interface NSDateFormatter (FLEX)

+ (NSString *)flex_stringFrom:(NSDate *)date format:(FLEXDateFormat)format;

@end
