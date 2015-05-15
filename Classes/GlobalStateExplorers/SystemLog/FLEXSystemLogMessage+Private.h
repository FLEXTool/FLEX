//
//  FLEXSystemLogMessage+LogMessageFromASLMessage.h
//  UICatalog
//
//  Created by Max Odnovolyk on 5/16/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import "FLEXSystemLogMessage.h"
#import <asl.h>

/// Hiding public asl.h import to prevent 'Include of non-modular header inside framework module' error when building FLEX as framework.
@interface FLEXSystemLogMessage ()

+(instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;

@end
