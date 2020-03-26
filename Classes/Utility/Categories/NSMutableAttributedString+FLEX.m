//
//  NSMutableAttributedString+FLEX.m
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSMutableAttributedString+FLEX.h"

@implementation NSMutableAttributedString (FLEX)
- (void)replaceOccurencesOfString:(NSAttributedString *)aString withString:(NSAttributedString *)replacement {
    NSRange searchRange = NSMakeRange(0, aString.length);
    while (searchRange.location < self.string.length) {
        searchRange.length = self.length - searchRange.location;
        NSRange foundRange = [self.string rangeOfString:aString.string options:0 range:searchRange];
        if (foundRange.location != NSNotFound) {
            searchRange.location = foundRange.location + foundRange.length;
            [self replaceCharactersInRange:foundRange withAttributedString:replacement];
        } else {
            break;
        }
    }
}
@end
