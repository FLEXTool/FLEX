//
//  FLEXKeyPathTokenizer.m
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathTokenizer.h"

#define TBCountOfStringOccurence(target, str) ([target componentsSeparatedByString:str].count - 1)


@implementation TBKeyPathTokenizer

#pragma mark Initialization

static NSCharacterSet *firstAllowed      = nil;
static NSCharacterSet *identifierAllowed = nil;
static NSCharacterSet *filenameAllowed   = nil;
static NSCharacterSet *keyPathDisallowed = nil;
static NSCharacterSet *methodAllowed     = nil;
+ (void)initialize {
    if (self == [self class]) {
        NSString *_methodFirstAllowed    = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        NSString *_identifierAllowed     = [_methodFirstAllowed stringByAppendingString:@"1234567890"];
        NSString *_methodAllowedSansType = [_identifierAllowed stringByAppendingString:@":"];
        NSString *_filenameNameAllowed   = [_identifierAllowed stringByAppendingString:@"-+?!"];
        firstAllowed      = [NSCharacterSet characterSetWithCharactersInString:_methodFirstAllowed];
        identifierAllowed = [NSCharacterSet characterSetWithCharactersInString:_identifierAllowed];
        filenameAllowed   = [NSCharacterSet characterSetWithCharactersInString:_filenameNameAllowed];
        methodAllowed     = [NSCharacterSet characterSetWithCharactersInString:_methodAllowedSansType];

        NSString *_kpDisallowed = [_identifierAllowed stringByAppendingString:@"-+:\\.*"];
        keyPathDisallowed = [NSCharacterSet characterSetWithCharactersInString:_kpDisallowed].invertedSet;
    }
}

#pragma mark Public

+ (TBKeyPath *)tokenizeString:(NSString *)userInput {
    if (!userInput.length) {
        return nil;
    }

    NSUInteger tokens = [self tokenCountOfString:userInput];
    if (tokens == 0) {
        return nil;
    }

    if ([userInput containsString:@"**"]) {
        @throw NSInternalInconsistencyException;
    }

    NSNumber *instance = nil;
    NSScanner *scanner = [NSScanner scannerWithString:userInput];
    TBToken *bundle    = [self scanToken:scanner allowed:filenameAllowed first:filenameAllowed];
    TBToken *cls       = [self scanToken:scanner allowed:identifierAllowed first:firstAllowed];
    TBToken *method    = tokens > 2 ? [self scanMethodToken:scanner instance:&instance] : nil;

    return [TBKeyPath bundle:bundle
                       class:cls
                      method:method
                  isInstance:instance
                      string:userInput];
}

+ (BOOL)allowedInKeyPath:(NSString *)text {
    if (!text.length) {
        return YES;
    }
    
    return [text rangeOfCharacterFromSet:keyPathDisallowed].location == NSNotFound;
}

#pragma mark Private

+ (NSUInteger)tokenCountOfString:(NSString *)userInput {
    NSUInteger escapedCount = TBCountOfStringOccurence(userInput, @"\\.");
    NSUInteger tokenCount  = TBCountOfStringOccurence(userInput, @".") - escapedCount + 1;

    return tokenCount;
}

+ (TBToken *)scanToken:(NSScanner *)scanner allowed:(NSCharacterSet *)allowedChars first:(NSCharacterSet *)first {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."]) {
            return [TBToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    TBWildcardOptions options = TBWildcardOptionsNone;
    NSMutableString *token = [NSMutableString string];

    // Token cannot start with '.'
    if ([scanner scanString:@"." intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }

    if ([scanner scanString:@"*." intoString:nil]) {
        options = TBWildcardOptionsAny;
        return [TBToken string:nil options:TBWildcardOptionsAny];
    } else if ([scanner scanString:@"*" intoString:nil]) {
        if (scanner.isAtEnd) {
            options = TBWildcardOptionsAny;
            return [TBToken string:nil options:TBWildcardOptionsAny];
        }
        
        options |= TBWildcardOptionsPrefix;
    }

    NSString *tmp = nil;
    BOOL stop = NO, didScanDelimiter = NO, didScanFirstAllowed = NO;
    NSCharacterSet *disallowed = allowedChars.invertedSet;
    while (!stop && ![scanner scanString:@"." intoString:&tmp] && !scanner.isAtEnd) {
        // Scan word chars
        if (!didScanFirstAllowed) {
            if ([scanner scanCharactersFromSet:first intoString:&tmp]) {
                [token appendString:tmp];
                didScanFirstAllowed = YES;
            } else {
                // Token starts with a number or something else not allowed
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:allowedChars intoString:&tmp]) {
            [token appendString:tmp];
        }
        // Scan '\.'
        else if ([scanner scanString:@"\\" intoString:nil]) {
            if ([scanner scanString:@"." intoString:nil]) {
                [token appendString:@"."];
            } else {
                // Invalid token, forward slash not followed by period
                @throw NSInternalInconsistencyException;
            }
        }
        // Scan '*.'
        else if ([scanner scanString:@"*." intoString:nil]) {
            options |= TBWildcardOptionsSuffix;
            stop = YES;
            didScanDelimiter = YES;
        }
        // Scan '*' not followed by .
        else if ([scanner scanString:@"*" intoString:nil]) {
            if (!scanner.isAtEnd) {
                // Invalid token, wildcard in middle of token
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:disallowed intoString:nil]) {
            // Invalid token, invalid characters
            @throw NSInternalInconsistencyException;
        }
    }

    if ([tmp isEqualToString:@"."]) {
        didScanDelimiter = YES;
    }

    if (!didScanDelimiter) {
        options |= TBWildcardOptionsSuffix;
    }

    return [TBToken string:token options:options];
}

+ (TBToken *)scanMethodToken:(NSScanner *)scanner instance:(NSNumber **)instance {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."]) {
            return [TBToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    if ([scanner.string hasSuffix:@"."] && ![scanner.string hasSuffix:@"\\."]) {
        // Methods cannot end with '.' except for '\.'
        @throw NSInternalInconsistencyException;
    }
    
    if ([scanner scanString:@"-" intoString:nil]) {
        *instance = @YES;
    } else if ([scanner scanString:@"+" intoString:nil]) {
        *instance = @NO;
    } else {
        if ([scanner scanString:@"*" intoString:nil]) {
            // Just checking... It has to start with one of these three!
            scanner.scanLocation--;
        } else {
            @throw NSInternalInconsistencyException;
        }
    }

    // -*foo not allowed
    if (*instance && [scanner scanString:@"*" intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }

    if (scanner.isAtEnd) {
        return [TBToken string:@"" options:TBWildcardOptionsSuffix];
    }

    return [self scanToken:scanner allowed:methodAllowed first:firstAllowed];
}

@end
