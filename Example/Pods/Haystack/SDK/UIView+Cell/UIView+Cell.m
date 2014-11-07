//
//  UIView+Cell.m
//

#import "UIView+Cell.h"

@implementation UIView (Cell)

- (UITableViewCell *)parentCellForView
{
    UIView *cell = self.superview;
    
    while (![cell isKindOfClass:[UITableViewCell class]] && cell != nil)
    {
        cell = cell.superview;
    }
    
    return (UITableViewCell *)cell;
}

@end
