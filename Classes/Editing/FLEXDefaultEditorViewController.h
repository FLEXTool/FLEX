//
//  FLEXDefaultEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXFieldEditorViewController.h"

@interface FLEXDefaultEditorViewController : FLEXFieldEditorViewController

- (id)initWithDefaults:(NSUserDefaults *)defaults key:(NSString *)key;

+ (BOOL)canEditDefaultWithValue:(id)currentValue;

@end
