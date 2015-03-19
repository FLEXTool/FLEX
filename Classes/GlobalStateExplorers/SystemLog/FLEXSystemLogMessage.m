//
//  FLEXSystemLogMessage.m
//  UICatalog
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXSystemLogMessage.h"

@implementation FLEXSystemLogMessage

+(instancetype)logMessageFromASLMessage:(aslmsg)aslMessage
{
    FLEXSystemLogMessage *logMessage = [[FLEXSystemLogMessage alloc] init];

    const char *timestamp = asl_get(aslMessage, ASL_KEY_TIME);
    if (timestamp) {
        NSTimeInterval timeInterval = [@(timestamp) integerValue];
        const char *nanoseconds = asl_get(aslMessage, ASL_KEY_TIME_NSEC);
        if (nanoseconds) {
            timeInterval += [@(nanoseconds) doubleValue] / NSEC_PER_SEC;
        }
        logMessage.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }

    const char *sender = asl_get(aslMessage, ASL_KEY_SENDER);
    if (sender) {
        logMessage.sender = @(sender);
    }

    const char *messageText = asl_get(aslMessage, ASL_KEY_MSG);
    if (messageText) {
        logMessage.messageText = @(messageText);
    }

    const char *messageID = asl_get(aslMessage, ASL_KEY_MSG_ID);
    if (messageID) {
        logMessage.messageID = [@(messageID) longLongValue];
    }

    return logMessage;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[FLEXSystemLogMessage class]] && self.messageID == [object messageID];
}

- (NSUInteger)hash
{
    return (NSUInteger)self.messageID;
}

@end
