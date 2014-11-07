
@interface HSMath : NSObject

/*!
 * Converts angle in degrees to angle in radians.
 *
 * @param angle angle in degrees
 * @return angle in radians
 */
+ (double)degreesToRadians:(double)angle;

/*!
 * Converts angle in radians to angle in degrees.
 *
 * @param radians angle in radians
 * @return angle in degrees
 */
+ (double)radiansToDegrees:(double)radians;

/*!
 * Returns pseudo-random number on interval from 0.0 to 1.0.
 *
 * @return random number between 0.0 and 1.0
 */
+ (double)random;

/*!
 * Returns pseudo-random floating point number in desired interval
 *
 * @param min minimum
 * @param max maximum
 * @return random number between minimum and maximum
 */
+ (double)randomBetweenMin:(double)min max:(double)max;

/*!
 * Returns pseudo-random integer number in desired interval
 *
 * @param min minimum
 * @param max maximum
 * @return pseudo-random number
 */
+ (NSInteger)randomIntegerBetweenMin:(NSInteger)min max:(NSInteger)max;

/*!
 *  Returns greatest common divisor between a and b
 *
 *  @param a number
 *  @param b number
 *
 *  @return greatest common divisor
 */
+ (NSInteger)greatestCommonDivisorForA:(NSInteger)a b:(NSInteger)b;

@end
