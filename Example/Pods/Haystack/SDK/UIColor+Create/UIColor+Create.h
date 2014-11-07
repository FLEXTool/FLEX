//
//  UIColor+Create.h
//

#define UIColorFromKey(color) [UIColor colorWithObject:color]

@import UIKit;

@interface UIColor (Create)

/*!
 * Returns UIColor from separate red, green and blue components.
 *
 * @param red component
 * @param green component
 * @param blue component
 * @param alpha component - between 0.0 and 1.0
 * @return UIColor object
 */
+ (UIColor *)colorWith8BitRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(CGFloat)alpha;

/*!
 * Returns UIColor from separate red, green and blue components.
 *
 * @param red component
 * @param green component
 * @param blue component
 * @return UIColor object
 */
+ (UIColor *)colorWith8BitRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;

/*!
* Converts hex string (HTML color) to UIColor object.
*
* @param hex color in hex notation
* @return UIColor color object
*/
+ (UIColor *)colorWithHex:(NSString *)hex;

/*!
 * Returns UIColor object if object is a Hex value color as string, returns same if it is UIColor already, otherwise nil.
 *
 * @param object as NSString or UIColor object
 * @return UIColor color object
 */
+ (UIColor *)colorWithObject:(id)object;

/*!
 * Returns UIColor object if UIColor responds to name selector as a string.
 *
 * @param name name of color
 * @return UIColor color object
 */
+ (UIColor *)colorWithName:(NSString *)name;

+ (NSArray *)colorsWithName:(NSString *)name;

+ (id)colorObjectWithName:(NSString *)name;

@end
