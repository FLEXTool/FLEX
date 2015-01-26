//
//  FLEXSystemLogMessage.h
//  UICatalog
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <asl.h>

@interface FLEXSystemLogMessage : NSObject

+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *sender;
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, assign) long long messageID;

@end
