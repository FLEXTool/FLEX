//
//  FLEXFieldEditorView.h
//  Flipboard
//
//  Created by Ryan Olson on 5/16/14.
//  Copyright (c) 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXArgumentInputView;

@interface FLEXFieldEditorView : UIView

@property (nonatomic, copy) NSString *targetDescription;
@property (nonatomic, copy) NSAttributedString *fieldDescription;

@property (nonatomic, copy) NSArray<FLEXArgumentInputView *> *argumentInputViews;

@end
