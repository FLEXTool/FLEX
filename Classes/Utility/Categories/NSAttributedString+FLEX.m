//
//  NSAttributedString+FLEX.m
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSAttributedString+FLEX.h"

@implementation NSAttributedString (FLEX)
+ (instancetype)stringByJoiningArray:(NSArray<NSAttributedString *> *)array withSeparator:(NSAttributedString *)separator {
    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    for (int i = 0; i < array.count; i++) {
        [attributedString appendAttributedString:array[i]];
        if (i != array.count - 1)
            [attributedString appendAttributedString:separator];
    }
    return attributedString;
}
+ (instancetype)stringWithFormat:(NSString *)format, ... {
    va_list arguments;
    va_start(arguments, format);

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:format];
    scanner.charactersToBeSkipped = [NSCharacterSet new];
    while (![scanner isAtEnd]) {
        NSString *discarded;
        [scanner scanUpToString:@"%" intoString:&discarded];
        if (discarded) {
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:discarded]];
        }
        if ([scanner scanString:@"%%" intoString:NULL]) {
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"%"]];
        } else if ([scanner scanString:@"%@" intoString:NULL]) {
            id object = va_arg(arguments, id);
            if(![object isKindOfClass:NSAttributedString.class]) {
                object = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", object]];
            }
            [attributedString appendAttributedString:object];
        } else if ([scanner scanString:@"%" intoString:NULL]) {
            NSString *specifier = [format substringFromIndex:scanner.scanLocation];
            if(specifier.length > 1) {
                specifier = [specifier substringToIndex:1];
            }
            NSAssert(NO, @"Unsupported format specifier '%@'", specifier);
        }
    }
    return attributedString;
}
+ (instancetype)stringWithAttributes:(NSDictionary *)attributes format:(NSString *)format, ... {
    va_list arguments;
    va_start(arguments, format);
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString stringWithFormat:format, arguments];
    [attributedString setAttributes:attributes range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}
- (instancetype)stringByAppendingAttributedString:(NSAttributedString *)aString {
    NSMutableAttributedString *attributedString = self.mutableCopy;
    [attributedString appendAttributedString:aString];
    return attributedString;
}
- (instancetype)stringByReplacingOccurrencesOfString:(NSAttributedString *)aString withString:(NSAttributedString *)replacement {
    NSMutableAttributedString *attributedString = self.mutableCopy;
    [attributedString replaceOccurencesOfString:aString withString:replacement];
    return attributedString;
}
@end

