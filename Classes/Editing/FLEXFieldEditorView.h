//
//  FLEXFieldEditorView.h
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXFieldEditorView : UIView

@property (nonatomic, copy) NSString *targetDescription;
@property (nonatomic, copy) NSString *fieldDescription;

@property (nonatomic, strong) NSArray *argumentInputViews;

@end
