//
//  NSTimer+Blocks.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//

#import "NSTimer+FLEX.h"

@interface Block : NSObject
- (void)invoke;
@end

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NSTimer (Blocks)

+ (instancetype)fireSecondsFromNow:(NSTimeInterval)delay block:(VoidBlock)block {
    if (@available(iOS 10, *)) {
        return [self scheduledTimerWithTimeInterval:delay repeats:NO block:(id)block];
    } else {
        return [self scheduledTimerWithTimeInterval:delay target:block selector:@selector(invoke) userInfo:nil repeats:NO];
    }
}

@end
