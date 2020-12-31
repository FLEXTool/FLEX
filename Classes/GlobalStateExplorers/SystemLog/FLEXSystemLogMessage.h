//
//  FLEXSystemLogMessage.h
//  FLEX
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>
#import "ActivityStreamAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXSystemLogMessage : NSObject

+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;
+ (instancetype)logMessageFromDate:(NSDate *)date text:(NSString *)text;

// ASL specific properties
@property (nonatomic, readonly, nullable) NSString *sender;
@property (nonatomic, readonly, nullable) aslmsg aslMessage;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSString *messageText;
@property (nonatomic, readonly) long long messageID;

@end

NS_ASSUME_NONNULL_END
