//
//  NSDate+Timestamp.m
//

#import "NSDate+Timestamp.h"

@implementation NSDate (Timestamp)

+ (NSTimeInterval)unixTimestampFromDate:(NSDate *)date
{
    return [date timeIntervalSince1970];
}

+ (NSTimeInterval)timeIntervalUntilUnixTimeStamp:(NSTimeInterval)timestamp;
{
    NSDate *timeStampDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
    
    return [timeStampDate timeIntervalSinceNow];
}

- (NSTimeInterval)unixTimestamp
{
    return [self timeIntervalSince1970];
}

+ (NSDate *)dateWithUnixTimestamp:(NSTimeInterval)timestamp
{
    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

+ (NSTimeInterval)unixTimestampForToday
{
    return [self unixTimestampDayForDate:[NSDate date]];
}

+ (NSTimeInterval)unixTimestampDayForDate:(NSDate *)date
{
    NSTimeInterval timestamp = [self unixTimestampFromDate:date];
    
    //
    // Cut away seconds and hours and milliseconds
    //
    
    NSInteger seconds = timestamp;
    
    seconds = seconds / 86400;
    
    seconds = seconds * 86400;
    
    return (NSTimeInterval)seconds;
}

@end
