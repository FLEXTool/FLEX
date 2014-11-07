//
//  UIButton+Position.h
//

@interface UIButton (Position)

/*!
 * Sets position of title in the button below image in the button
 */
- (void)setTitleBelowWithSpacing:(CGFloat)spacing;

/*!
 * Sets position of title in the button above image in the button
 */
- (void)setTitleAboveWithSpacing:(CGFloat)spacing;

/*!
 * Sets position of title in the button right of the image in the button (default)
 */
- (void)setTitleRightWithSpacing:(CGFloat)spacing;

/*!
 * Sets position of title in the button left of the image in the button
 */
- (void)setTitleLeftWithSpacing:(CGFloat)spacing;

@end
