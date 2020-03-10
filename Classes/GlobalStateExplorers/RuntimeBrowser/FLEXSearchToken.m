//
//  FLEXSearchToken.m
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXSearchToken.h"

@interface FLEXSearchToken () {
    NSString *flex_description;
}
@end

@implementation FLEXSearchToken

+ (instancetype)any {
    static FLEXSearchToken *any = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        any = [self string:nil options:TBWildcardOptionsAny];
    });

    return any;
}

+ (instancetype)string:(NSString *)string options:(TBWildcardOptions)options {
    FLEXSearchToken *token  = [self new];
    token->_string  = string;
    token->_options = options;
    return token;
}

- (BOOL)isAbsolute {
    return _options == TBWildcardOptionsNone;
}

- (BOOL)isAny {
    return _options == TBWildcardOptionsAny;
}

- (BOOL)isEmpty {
    return self.isAny && self.string.length == 0;
}

- (NSString *)description {
    if (flex_description) {
        return flex_description;
    }

    switch (_options) {
        case TBWildcardOptionsNone:
            flex_description = _string;
            break;
        case TBWildcardOptionsAny:
            flex_description = @"*";
            break;
        default: {
            NSMutableString *desc = [NSMutableString new];
            if (_options & TBWildcardOptionsPrefix) {
                [desc appendString:@"*"];
            }
            [desc appendString:_string];
            if (_options & TBWildcardOptionsSuffix) {
                [desc appendString:@"*"];
            }
            flex_description = desc;
        }
    }

    return flex_description;
}

- (NSUInteger)hash {
    return self.description.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[FLEXSearchToken class]]) {
        FLEXSearchToken *token = object;
        return [_string isEqualToString:token->_string] && _options == token->_options;
    }

    return NO;
}

@end
