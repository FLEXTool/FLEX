//
//  FLEXArgumentInputView.m
//  Flipboard
//
//  Created by Ryan Olson on 5/30/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXArgumentInputView.h"
#import "FLEXUtility.h"

@interface FLEXArgumentInputView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *inputTextView;

@end

@implementation FLEXArgumentInputView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Default to two lines in the text view. Users of the class can customize.
        self.numberOfInputLines = 2;
        
        self.inputTextView = [[UITextView alloc] init];
        self.inputTextView.font = [[self class] inputFont];
        self.inputTextView.backgroundColor = [UIColor whiteColor];
        self.inputTextView.layer.borderColor = [[UIColor blackColor] CGColor];
        self.inputTextView.layer.borderWidth = 1.0;
        self.inputTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.inputTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        [self addSubview:self.inputTextView];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat originY = 0;
    CGFloat contentWidth = self.bounds.size.width;
    if ([self.title length] > 0) {
        CGSize constrainSize = CGSizeMake(contentWidth, CGFLOAT_MAX);
        CGSize labelSize = [self.titleLabel sizeThatFits:constrainSize];
        self.titleLabel.frame = CGRectMake(0, originY, labelSize.width, labelSize.height);
        originY = CGRectGetMaxY(self.titleLabel.frame) + [[self class] titleBottomPadding];
    }
    
    self.inputTextView.frame = CGRectMake(0, originY, contentWidth, [self inputTextViewHeight]);
}

- (void)setTitle:(NSString *)title
{
    if (![_title isEqual:title]) {
        _title = title;
        self.titleLabel.text = title;
        [self setNeedsLayout];
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.backgroundColor = self.backgroundColor;
        _titleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        _titleLabel.numberOfLines = 0;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}


#pragma mark - Text View Passthroughs

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    self.inputTextView.keyboardType = keyboardType;
}

- (UIKeyboardType)keyboardType
{
    return self.inputTextView.keyboardType;
}

- (void)setInputText:(NSString *)inputText
{
    self.inputTextView.text = inputText;
}

- (NSString *)inputText
{
    return self.inputTextView.text;
}

- (BOOL)inputViewIsFirstResponder
{
    return self.inputTextView.isFirstResponder;
}


#pragma mark - Class Helpers

+ (UIFont *)inputFont
{
    return [FLEXUtility defaultFontOfSize:14.0];
}

+ (UIFont *)titleFont
{
    return [FLEXUtility defaultFontOfSize:12.0];
}

+ (CGFloat)titleBottomPadding
{
    return 4.0;
}


#pragma mark - Sizing

- (CGFloat)inputTextViewHeight
{
    return ceil([[self class] inputFont].lineHeight * self.numberOfInputLines) + 20.0;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = 0;
    
    if ([self.title length] > 0) {
        CGSize constrainSize = CGSizeMake(size.width, CGFLOAT_MAX);
        height += ceil([self.title sizeWithFont:[[self class] titleFont] constrainedToSize:constrainSize].height);
        height += [[self class] titleBottomPadding];
    }
    
    height += [self inputTextViewHeight];
    
    return CGSizeMake(size.width, height);
}

@end
