//
//  FLEXTrigger.m
//  UICatalog
//
//  Created by Dal Rupnik on 05/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXTrigger.h"

@implementation FLEXTrigger

- (void)integrate
{
    
}

- (void)trigger:(id)sender
{
    [[FLEXManager sharedManager] showExplorer];
}

@end
