//
//  FLEXIvarEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXMutableFieldEditorViewController.h"
#import <objc/runtime.h>

@interface FLEXIvarEditorViewController : FLEXMutableFieldEditorViewController

- (id)initWithTarget:(id)target ivar:(Ivar)ivar;

+ (BOOL)canEditIvar:(Ivar)ivar currentValue:(id)value;

@end
