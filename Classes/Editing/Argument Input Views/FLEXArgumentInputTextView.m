//
//  FLEXArgumentInputTextView.m
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputTextView.h"
#import "FLEXUtility.h"

@interface FLEXArgumentInputTextView () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, readonly) NSUInteger numberOfInputLines;

@end

@implementation FLEXArgumentInputTextView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding
{
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView = [[UITextView alloc] init];
        self.inputTextView.font = [[self class] inputFont];
        self.inputTextView.backgroundColor = [UIColor whiteColor];
        self.inputTextView.layer.borderColor = [[UIColor blackColor] CGColor];
        self.inputTextView.layer.borderWidth = 1.0;
        self.inputTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.inputTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.inputTextView.delegate = self;
        [self addSubview:self.inputTextView];
    }
    return self;
}


#pragma mark - Text View Changes

- (void)textViewDidChange:(UITextView *)textView
{
    [self.delegate argumentInputViewValueDidChange:self];
}


#pragma mark - Superclass Overrides

- (BOOL)inputViewIsFirstResponder
{
    return self.inputTextView.isFirstResponder;
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.inputTextView.frame = CGRectMake(0, self.topInputFieldVerticalLayoutGuide, self.bounds.size.width, [self inputTextViewHeight]);
}

- (NSUInteger)numberOfInputLines
{
    NSUInteger numberOfInputLines = 0;
    switch (self.targetSize) {
        case FLEXArgumentInputViewSizeDefault:
            numberOfInputLines = 2;
            break;
            
        case FLEXArgumentInputViewSizeSmall:
            numberOfInputLines = 1;
            break;
            
        case FLEXArgumentInputViewSizeLarge:
            numberOfInputLines = 8;
            break;
    }
    return numberOfInputLines;
}

- (CGFloat)inputTextViewHeight
{
    return ceil([[self class] inputFont].lineHeight * self.numberOfInputLines) + 16.0;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height += [self inputTextViewHeight];
    return fitSize;
}


#pragma mark - Class Helpers

+ (UIFont *)inputFont
{
    return [FLEXUtility defaultFontOfSize:14.0];
}

@end
