//
//  UIView+Debug.m
//

#import "UIView+Debug.h"

@implementation UIView (Debug)

- (NSString *)detailedDebugDescription
{
    NSMutableString* debugDescription = [[self debugDescription] mutableCopy];
    
    if ([self isKindOfClass:[UIButton class]])
    {
        UIButton* button = (UIButton *)self;
        
        NSString* title = [button titleForState:button.state];
        
        if ([title length])
        {
            debugDescription = [[debugDescription substringToIndex:[debugDescription length] - 2] mutableCopy];
            [debugDescription appendString:@" title=\""];
            [debugDescription appendString:title];
            [debugDescription appendString:@"\">"];
        }
    }
    
    return [debugDescription copy];
}

@end
