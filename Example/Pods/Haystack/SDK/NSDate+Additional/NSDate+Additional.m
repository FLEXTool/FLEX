//
//  NSDate+Additional.m
//

#import "NSDate+Additional.h"

@implementation NSDate (Timestamp)

- (NSComparisonResult)compareDateWithoutTimeTo:(NSDate *)date
{
    return NSOrderedSame;
}

@end
