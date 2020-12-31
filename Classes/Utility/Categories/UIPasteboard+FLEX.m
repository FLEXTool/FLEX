//
//  UIPasteboard+FLEX.m
//  FLEX
//
//  Created by Tanner Bennett on 12/9/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIPasteboard+FLEX.h"

@implementation UIPasteboard (FLEX)

- (void)flex_copy:(id)object {
    if (!object) {
        return;
    }
    
    if ([object isKindOfClass:[NSString class]]) {
        UIPasteboard.generalPasteboard.string = object;
    } else if([object isKindOfClass:[NSData class]]) {
        [UIPasteboard.generalPasteboard setData:object forPasteboardType:@"public.data"];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        UIPasteboard.generalPasteboard.string = [object stringValue];
    } else {
        // TODO: make this an alert instead of an exception
        [NSException raise:NSInternalInconsistencyException
                    format:@"Tried to copy unsupported type: %@", [object class]];
    }
}

@end
