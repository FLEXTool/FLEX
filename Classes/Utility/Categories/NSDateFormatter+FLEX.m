//
//  NSDateFormatter+FLEX.m
//  libflex:FLEX
//
//  Created by Tanner Bennett on 7/24/22.
//  Copyright © 2022 Flipboard. All rights reserved.
//

#import "NSDateFormatter+FLEX.h"

@implementation NSDateFormatter (FLEX)

+ (NSString *)flex_stringFrom:(NSDate *)date format:(FLEXDateFormat)format {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
    }
    
    switch (format) {
        case FLEXDateFormatClock:
            formatter.dateFormat = @"h:mm a";
            break;
        case FLEXDateFormatPreciseClock:
            formatter.dateFormat = @"h:mm:ss a";
            break;
        case FLEXDateFormatVerbose:
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            break;
    }
    
    return [formatter stringFromDate:date];
}

@end
