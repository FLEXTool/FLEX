//
//  FLEXArgumentInputTextView.h
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputView.h"

@interface FLEXArgumentInputTextView : FLEXArgumentInputView

// For subclass eyes only

@property (nonatomic, strong, readonly) UITextView *inputTextView;

@end
