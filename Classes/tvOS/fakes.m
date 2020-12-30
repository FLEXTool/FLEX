//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "fakes.h"
#import "NSObject+FLEX_Reflection.h"
@interface UIImage (private)
+(UIImage *)symbolImageNamed:(NSString *)symbolName;
@end
@interface KBSearchButton()
@property UITextField *searchField; //helps us get a keyboard onscreen and acts as a proxy to move text to our UISearchBar
@end

@implementation KBSearchButton

+ (instancetype)buttonWithType:(UIButtonType)buttonType {
    KBSearchButton *button = [super buttonWithType:buttonType];
    [button setImage:[UIImage symbolImageNamed:@"magnifyingglass"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 150, 70);
    UITextField *tf = [[UITextField alloc]init];
    tf.clearButtonMode = UITextFieldViewModeAlways;
    button.searchField = tf;
    tf.delegate = button;
    [button addSubview:tf];
    [button addTarget:button action:@selector(triggerSearchField) forControlEvents:UIControlEventPrimaryActionTriggered];
    [button addListeners];
    return button;
}

- (void)textChanged:(NSNotification *)n {
    self.searchBar.text = self.searchField.text;
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)triggerSearchField {
    self.searchField.text = self.searchBar.text;
    //[self.searchBar becomeFirstResponder];
    [self.searchField becomeFirstResponder];
    //wait for 0.1 seconds and then decrease the opacity of UISystemInputViewController presenting our UIKeyboard
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *vc = [self topViewController];
        vc.view.alpha = 0.6;
    });
}

@end

@interface UIFakeSwitch() {
    BOOL _isOn;
}
@end

@implementation UIFakeSwitch

- (BOOL)isOn {
    return _isOn;
}

- (void)setOn:(BOOL)on{
    [self setOn:on animated:true];
}

- (NSString *)onTitle {
    return @"TRUE";
}

- (NSString *)offTitle {
    return @"FALSE";
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    if (_isOn){
        [self setTitle:[self onTitle] forState:UIControlStateNormal];
    } else {
        [self setTitle:[self offTitle] forState:UIControlStateNormal];
    }
    //[self sendActionsForControlEvents:[self allControlEvents]];
}

+ (id)newSwitch {
    return [UIFakeSwitch buttonWithType:UIButtonTypeSystem];
}

-(instancetype)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
}

- (instancetype)initWithCoder:(id)coder {
    return [super initWithCoder:coder];
}

@end

@implementation UIFakeSlider

- (void)setValue:(float)value animated:(BOOL)animated {
    
}

- (void)setThumbImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}
- (void)setMinimumTrackImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}
- (void)setMaximumTrackImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}

- (nullable UIImage *)thumbImageForState:(UIControlState)state {
    return nil;
}
- (nullable UIImage *)minimumTrackImageForState:(UIControlState)state {
    return nil;
}
- (nullable UIImage *)maximumTrackImageForState:(UIControlState)state {
    return nil;
}

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    return CGRectZero;
}

@end
