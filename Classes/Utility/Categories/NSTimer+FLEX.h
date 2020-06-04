//
//  NSTimer+Blocks.h
//  FLEX
//
//  Created by Tanner on 3/23/17.
//

#import <Foundation/Foundation.h>

typedef void (^VoidBlock)(void);

@interface NSTimer (Blocks)

+ (instancetype)fireSecondsFromNow:(NSTimeInterval)delay block:(VoidBlock)block;

// Forward declaration
//+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block;

@end
