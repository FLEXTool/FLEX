//
//  FLEXArgumentInputView.h
//  Flipboard
//
//  Created by Ryan Olson on 5/30/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXArgumentInputView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *inputText;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, readonly) BOOL inputViewIsFirstResponder;
@property (nonatomic, assign) NSUInteger numberOfInputLines;

@end
