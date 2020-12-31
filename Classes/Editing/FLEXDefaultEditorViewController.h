//
//  FLEXDefaultEditorViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXFieldEditorViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXDefaultEditorViewController : FLEXVariableEditorViewController

+ (instancetype)target:(NSUserDefaults *)defaults key:(NSString *)key commitHandler:(void(^_Nullable)())onCommit;

+ (BOOL)canEditDefaultWithValue:(nullable id)currentValue;

@end

NS_ASSUME_NONNULL_END
