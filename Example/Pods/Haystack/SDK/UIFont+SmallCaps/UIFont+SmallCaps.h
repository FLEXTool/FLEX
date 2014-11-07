//
//  UIFont+SmallCaps.h
//

@interface UIFont (SmallCaps)

/*!
 * Returns new instance of same font in small cap format
 *
 * @return UIFont small cap font
 */
- (UIFont *)smallCapFont;

/*!
 * Returns true if current font is of same family as system font
 */
- (BOOL)isSystemFont;

/*!
 * Returns true if font has small caps available
 */
- (BOOL)hasSmallCaps;

@end
