//
//  TBToken.m
//  TBTweakViewController
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBToken.h"


@interface TBToken () {
    NSString *tb_description;
}
@end
@implementation TBToken

+ (instancetype)string:(NSString *)string options:(TBWildcardOptions)options {
    TBToken *token  = [self new];
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

- (NSString *)description {
    if (tb_description) {
        return tb_description;
    }

    switch (_options) {
        case TBWildcardOptionsNone:
            tb_description = _string;
            break;
        case TBWildcardOptionsAny:
            tb_description = @"*";
            break;
        default: {
            NSMutableString *desc = [NSMutableString string];
            if (_options & TBWildcardOptionsPrefix) {
                [desc appendString:@"*"];
            }
            [desc appendString:_string];
            if (_options & TBWildcardOptionsSuffix) {
                [desc appendString:@"*"];
            }
            tb_description = desc;
        }
    }

    return tb_description;
}

- (NSUInteger)hash {
    return self.description.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TBToken class]]) {
        TBToken *token = object;
        return [_string isEqualToString:token->_string] && _options == token->_options;
    }

    return NO;
}

@end
