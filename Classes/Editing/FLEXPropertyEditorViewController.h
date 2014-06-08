//
//  FLEXPropertyEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/20/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXFieldEditorViewController.h"
#import <objc/runtime.h>

@interface FLEXPropertyEditorViewController : FLEXFieldEditorViewController

- (id)initWithTarget:(id)target property:(objc_property_t)property;

+ (BOOL)canEditProperty:(objc_property_t)property currentValue:(id)value;

@end
