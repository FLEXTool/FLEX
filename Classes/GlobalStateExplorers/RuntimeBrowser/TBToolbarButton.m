//
//  TBToolbarButton.m
//
//  Created by Rudd Fawcett on 12/3/13.
//  Copyright (c) 2013 Rudd Fawcett. All rights reserved.
//

#import "TBToolbarButton.h"
#import "UIFont+FLEX.h"


@interface TBToolbarButton ()
@property (nonatomic      ) NSString *title;
@property (nonatomic, copy) TBToolbarAction buttonPressBlock;
@end

@implementation TBToolbarButton

+ (instancetype)buttonWithTitle:(NSString *)title {
    return [[self alloc] initWithTitle:title];
}

+ (instancetype)buttonWithTitle:(NSString *)title action:(TBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvent {
    TBToolbarButton *newButton = [TBToolbarButton buttonWithTitle:title];
    [newButton addEventHandler:eventHandler forControlEvents:controlEvent];
    return newButton;
}

+ (instancetype)buttonWithTitle:(NSString *)title action:(TBToolbarAction)eventHandler {
    return [self buttonWithTitle:title action:eventHandler forControlEvents:UIControlEventTouchUpInside];
}

- (id)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        self.layer.cornerRadius = 5.0f;
        self.layer.borderWidth  = 1.0f;
        self.titleLabel.font    = [UIFont flex_codeFont];
        [self setTitle:self.title forState:UIControlStateNormal];
        [self sizeToFit];
        CGRect frame = self.frame;
        frame.size.width  += 40;
        frame.size.height += 10;
        self.frame = frame;
        self.appearance = UIKeyboardAppearanceLight;
    }
    
    return self;
}

- (void)addEventHandler:(TBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvent {
    self.buttonPressBlock = eventHandler;
    [self addTarget:self action:@selector(buttonPressed) forControlEvents:controlEvent];
}

- (void)buttonPressed {
    self.buttonPressBlock(self.title);
}

- (void)setAppearance:(UIKeyboardAppearance)appearance {
    _appearance = appearance;
    
    switch (_appearance) {
        case UIKeyboardAppearanceDefault:
        case UIKeyboardAppearanceLight:
            self.backgroundColor      = [UIColor whiteColor];
            self.layer.borderColor    = [UIColor colorWithWhite:1.000 alpha:0.500].CGColor;
            self.titleLabel.textColor = [UIColor blackColor];
            [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
        case UIKeyboardAppearanceDark:
            self.backgroundColor      = [UIColor colorWithWhite:0.336 alpha:1.000];
            self.layer.borderColor    = [UIColor clearColor].CGColor;
            self.titleLabel.textColor = [UIColor whiteColor];
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
            
        default:
            self.backgroundColor      = [UIColor colorWithWhite:0.9 alpha:1.0];
            self.layer.borderColor    = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
            self.titleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
            [self setTitleColor:[UIColor colorWithWhite:0.5 alpha:1.0] forState:UIControlStateNormal];
            break;
    }
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TBToolbarButton class]]) {
        return [self.title isEqualToString:[object title]];
    }

    return NO;
}

- (NSUInteger)hash {
    return self.title.hash;
}

@end
