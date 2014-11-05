//
//  FLEXTriggerManager.h
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXTrigger.h"

/**
 *  Trigger manager handles different FLEX triggers
 */
@interface FLEXTriggerManager : NSObject

@property (nonatomic, readonly) NSArray *triggers;

+ (instancetype)sharedManager;

- (void)addTrigger:(FLEXTrigger *)trigger;


@end
