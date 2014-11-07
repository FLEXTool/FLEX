//
//  NSDate+Additional.h
//

#import <Foundation/Foundation.h>

@interface NSDate (Additional)

/*!
 *  Compares NSDate date part to another NSDate.
 *
 *  @param NSDate date to be compared
 *  @return NSComparisonResult result of comparison
 */
- (NSComparisonResult)compareDateWithoutTimeTo:(NSDate *)date;

@end
