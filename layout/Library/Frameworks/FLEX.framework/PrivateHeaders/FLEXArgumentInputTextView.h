//
//  FLEXArgumentInputTextView.h
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputView.h"
#if TARGET_OS_TV
#import "KBSelectableTextView.h"
#endif

@interface FLEXArgumentInputTextView : FLEXArgumentInputView <UITextViewDelegate>

// For subclass eyes only
#if TARGET_OS_TV
@property (nonatomic, readonly) KBSelectableTextView *inputTextView;
#else
@property (nonatomic, readonly) UITextView *inputTextView;
#endif
@property (nonatomic) NSString *inputPlaceholderText;

@end
