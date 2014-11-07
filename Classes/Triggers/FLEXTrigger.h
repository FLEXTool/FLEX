//
//  FLEXTrigger.h
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

@interface FLEXTrigger : NSObject

/**
 *  Installs trigger to UIWindow
 */
- (void)integrate;

/**
 *  Executes trigger, opens FLEX explorer
 *
 *  @param sender Trigger sender
 */
- (void)trigger:(id)sender;

@end
