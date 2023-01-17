//
//  FLEXASLLogController.h
//  FLEX
//
//  Created by Tanner on 3/14/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "Classes/GlobalStateExplorers/SystemLog/FLEXLogController.h"

@interface FLEXASLLogController : NSObject <FLEXLogController>

/// Guaranteed to call back on the main thread.
+ (instancetype)withUpdateHandler:(void(^)(NSArray<FLEXSystemLogMessage *> *newMessages))newMessagesHandler;

- (BOOL)startMonitoring;

@end
