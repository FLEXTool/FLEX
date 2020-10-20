//
//  FLEXMethodCallingViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXVariableEditorViewController.h"
#import "FLEXMethod.h"

@interface FLEXMethodCallingViewController : FLEXVariableEditorViewController

+ (instancetype)target:(id)target method:(FLEXMethod *)method;

@end
