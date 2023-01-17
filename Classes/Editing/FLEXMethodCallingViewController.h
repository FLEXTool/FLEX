//
//  FLEXMethodCallingViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "Classes/Editing/FLEXVariableEditorViewController.h"
#import "Classes/Utility/Runtime/Objc/Reflection/FLEXMethod.h"

@interface FLEXMethodCallingViewController : FLEXVariableEditorViewController

+ (instancetype)target:(id)target method:(FLEXMethod *)method;

@end
