//
//  Cocoa+FLEXShortcuts.m
//  Pods
//
//  Created by Tanner on 2/24/21.
//  
//

#import "Cocoa+FLEXShortcuts.h"

@implementation UIAlertAction (FLEXShortcuts)
- (NSString *)flex_styleName {
    switch (self.style) {
        case UIAlertActionStyleDefault:
            return @"Default style";
        case UIAlertActionStyleCancel:
            return @"Cancel style";
        case UIAlertActionStyleDestructive:
            return @"Destructive style";
            
        default:
            return [NSString stringWithFormat:@"Unknown (%@)", @(self.style)];
    }
}
@end
