//
//  NSString+FLEX.m
//  FLEX
//
//  Created by Tanner on 3/26/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "NSString+FLEX.h"

@interface NSMutableString (Replacement)
- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement;
- (void)removeLastKeyPathComponent;
@end

@implementation NSMutableString (Replacement)

- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement {
    [self replaceOccurrencesOfString:string withString:replacement options:0 range:NSMakeRange(0, self.length)];
}

- (void)removeLastKeyPathComponent {
    if (![self containsString:@"."]) {
        [self deleteCharactersInRange:NSMakeRange(0, self.length)];
        return;
    }

    BOOL putEscapesBack = NO;
    if ([self containsString:@"\\."]) {
        [self replaceOccurencesOfString:@"\\." with:@"\\~"];

        // Case like "UIKit\.framework"
        if (![self containsString:@"."]) {
            [self deleteCharactersInRange:NSMakeRange(0, self.length)];
            return;
        }

        putEscapesBack = YES;
    }

    // Case like "Bund" or "Bundle.cla"
    if (![self hasSuffix:@"."]) {
        NSUInteger len = self.pathExtension.length;
        [self deleteCharactersInRange:NSMakeRange(self.length-len, len)];
    }

    if (putEscapesBack) {
        [self replaceOccurencesOfString:@"\\~" with:@"\\."];
    }
}

@end

@implementation NSString (FLEXTypeEncoding)

- (BOOL)typeIsConst {
    return [self characterAtIndex:0] == FLEXTypeEncodingConst;
}

- (FLEXTypeEncoding)firstNonConstType {
    return [self characterAtIndex:(self.typeIsConst ? 1 : 0)];
}

- (BOOL)typeIsObjectOrClass {
    FLEXTypeEncoding type = self.firstNonConstType;
    return type == FLEXTypeEncodingObjcObject || type == FLEXTypeEncodingObjcClass;
}

- (BOOL)typeIsNonObjcPointer {
    FLEXTypeEncoding type = self.firstNonConstType;
    return type == FLEXTypeEncodingPointer ||
           type == FLEXTypeEncodingCString ||
           type == FLEXTypeEncodingSelector;
}

@end

@implementation NSString (KeyPaths)

- (NSString *)stringByRemovingLastKeyPathComponent {
    if (![self containsString:@"."]) {
        return @"";
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    return mself;
}

- (NSString *)stringByReplacingLastKeyPathComponent:(NSString *)replacement {
    // replacement should not have any escaped '.' in it,
    // so we escape all '.'
    if ([replacement containsString:@"."]) {
        replacement = [replacement stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    }

    // Case like "Foo"
    if (![self containsString:@"."]) {
        return [replacement stringByAppendingString:@"."];
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    [mself appendString:replacement];
    [mself appendString:@"."];
    return mself;
}

@end
