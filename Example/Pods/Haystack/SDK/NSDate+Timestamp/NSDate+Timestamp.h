//
//  NSDate+Timestamp.h
//

#import <Foundation/Foundation.h>

@interface NSDate (Timestamp)

/*!
 *  Converts NSDate into Unix timestamp in milliseconds.
 *
 *  @param date date to be converted to Unix timestamp
 *  @return NSTimeInterval Unix timestamp of passed date
 */
+ (NSTimeInterval)unixTimestampFromDate:(NSDate *)date;

/*!
 * Returns time interval since/until the Unix timestamp in milliseconds.
 *
 * If timestamp is in the future, interval is positive, if it is in the past
 * it is negative.
 *
 * @param timestamp Unix timestamp
 * @return NSTimeInterval Time interval in milliseconds
 */
+ (NSTimeInterval)timeIntervalUntilUnixTimeStamp:(NSTimeInterval)timestamp;

/*!
 * Returns Unix timestamp of current date object.
 *
 * @return NSTimeInterval Unix timestamp
 */
- (NSTimeInterval)unixTimestamp;

/*!
 * Returns NSDate object of provided Unix timestamp.
 *
 * @return NSDate object from Unix timestamp
 */
+ (NSDate *)dateWithUnixTimestamp:(NSTimeInterval)timestamp;

/*!
 * Returns Unix timestamp that starts today, stripping away hours, minutes and seconds.
 *
 * @return NSTimeInterval Unix timestamp for today
 */
+ (NSTimeInterval)unixTimestampForToday;

/*!
 * Returns Unix timestamp that starts on the day of date, stripping away hours, minutes and seconds.
 *
 * @return NSTimeInterval Unix timestamp for day
 */
+ (NSTimeInterval)unixTimestampDayForDate:(NSDate *)date;
@end
