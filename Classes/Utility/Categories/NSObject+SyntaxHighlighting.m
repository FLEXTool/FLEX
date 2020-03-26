//
//  NSObject+SyntaxHighlighting.m
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSObject+SyntaxHighlighting.h"

@implementation NSObject (SyntaxHighlighting)
- (NSAttributedString *)attributedDescription {
    return self.description.attributedString;
}
- (NSAttributedString *)attributedDebugDescription {
    return self.debugDescription.attributedString;
}
@end
