//
//  FLEXArgumentInputTextView.h
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXArgumentInputTextView : FLEXArgumentInputView <UITextViewDelegate>

// For subclass eyes only

@property (nonatomic, readonly) UITextView *inputTextView;
@property (nonatomic, nullable) NSString *inputPlaceholderText;

@end

NS_ASSUME_NONNULL_END
