//
//  FLEXArgumentInputTextView.m
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXColor.h"
#import "FLEXArgumentInputTextView.h"
#import "FLEXUtility.h"

@interface FLEXArgumentInputTextView ()

@property (nonatomic) UITextView *inputTextView;
@property (nonatomic) UILabel *placeholderLabel;
@property (nonatomic, readonly) NSUInteger numberOfInputLines;

@end

@implementation FLEXArgumentInputTextView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView = [UITextView new];
        self.inputTextView.font = [[self class] inputFont];
        self.inputTextView.backgroundColor = FLEXColor.secondaryGroupedBackgroundColor;
        self.inputTextView.layer.cornerRadius = 10.f;
        self.inputTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
        self.inputTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.inputTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.inputTextView.delegate = self;
        self.inputTextView.inputAccessoryView = [self createToolBar];
        if (@available(iOS 11, *)) {
            [self.inputTextView.layer setValue:@YES forKey:@"continuousCorners"];
        } else {
            self.inputTextView.layer.borderWidth = 1.f;
            self.inputTextView.layer.borderColor = FLEXColor.borderColor.CGColor;
        }

        self.placeholderLabel = [UILabel new];
        self.placeholderLabel.font = self.inputTextView.font;
        self.placeholderLabel.textColor = FLEXColor.deemphasizedTextColor;
        self.placeholderLabel.numberOfLines = 0;

        [self addSubview:self.inputTextView];
        [self.inputTextView addSubview:self.placeholderLabel];

    }
    return self;
}

#pragma mark - Private

- (UIToolbar *)createToolBar {
    UIToolbar *toolBar = [UIToolbar new];
    [toolBar sizeToFit];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
        target:nil action:nil
    ];
    UIBarButtonItem *pasteItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Paste" style:UIBarButtonItemStyleDone
        target:self.inputTextView action:@selector(paste:)
    ];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self.inputTextView action:@selector(resignFirstResponder)
    ];
    toolBar.items = @[spaceItem, pasteItem, doneItem];
    return toolBar;
}

- (void)setInputPlaceholderText:(NSString *)placeholder {
    self.placeholderLabel.text = placeholder;
    if (placeholder.length) {
        if (!self.inputTextView.text.length) {
            self.placeholderLabel.hidden = NO;
        } else {
            self.placeholderLabel.hidden = YES;
        }
    } else {
        self.placeholderLabel.hidden = YES;
    }

    [self setNeedsLayout];
}

- (NSString *)inputPlaceholderText {
    return self.placeholderLabel.text;
}


#pragma mark - Superclass Overrides

- (BOOL)inputViewIsFirstResponder {
    return self.inputTextView.isFirstResponder;
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.inputTextView.frame = CGRectMake(0, self.topInputFieldVerticalLayoutGuide, self.bounds.size.width, [self inputTextViewHeight]);
    // Placeholder label is positioned by insetting then origin
    // by the content inset then the text container inset
    CGSize s = self.inputTextView.frame.size;
    self.placeholderLabel.frame = CGRectMake(0, 0, s.width, s.height);
    self.placeholderLabel.frame = UIEdgeInsetsInsetRect(
        UIEdgeInsetsInsetRect(self.placeholderLabel.frame, self.inputTextView.contentInset),
        self.inputTextView.textContainerInset
    );
}

- (NSUInteger)numberOfInputLines {
    switch (self.targetSize) {
        case FLEXArgumentInputViewSizeDefault:
            return 2;
        case FLEXArgumentInputViewSizeSmall:
            return 1;
        case FLEXArgumentInputViewSizeLarge:
            return 8;
    }
}

- (CGFloat)inputTextViewHeight {
    return ceil([[self class] inputFont].lineHeight * self.numberOfInputLines) + 16.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height += [self inputTextViewHeight];
    return fitSize;
}


#pragma mark - Class Helpers

+ (UIFont *)inputFont {
    return [UIFont systemFontOfSize:14.0];
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self.delegate argumentInputViewValueDidChange:self];
    self.placeholderLabel.hidden = !(self.inputPlaceholderText.length && !textView.text.length);
}

@end
