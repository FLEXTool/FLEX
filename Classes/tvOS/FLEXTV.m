//
//  FLEXTV.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXTV.h"
#import "NSObject+FLEX_Reflection.h"
#import "UIView+FLEX_Layout.h"
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

@interface UIFLEXSwitch() {
    BOOL _isOn;
}
@end

@implementation UIFLEXSwitch

- (BOOL)isOn {
    return _isOn;
}

- (void)initDefaults {
    self.onTintColor = [UIColor greenColor];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self){
        [self initDefaults];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self){
        [self initDefaults];
    }
    return self;
}

- (UIColor *)backgroundColor {
    if ([self isOn]) return self.onTintColor;
    return [super backgroundColor];
}

- (void)setOn:(BOOL)on{
    [self setOn:on animated:true];
}

- (NSString *)onTitle {
    return @"ON";
}

- (NSString *)offTitle {
    return @"OFF";
}

/*
 `<UIFLEXSwitch: 0x1009b3010; baseClass = UIButton; frame = (50 50; 200 70); opaque = NO; gestureRecognizers = <NSArray: 0x2814ba4f0>; layer = <CALayer: 0x281a811c0>>
 | <_UIFloatingContentView: 0x10ec4a820; frame = (0 0; 200 70); opaque = NO; layer = <CALayer: 0x281a92ce0>>
 |    | <UIView: 0x1008744e0; frame = (0 -0.25; 200 70); transform3D = [0.8, 0, 0, 0; 0, 0.8, 0, 0; 0, 0, 1, -0.001; 0, 0, 0, 1]; alpha = 0; opaque = NO; layer = <CALayer: 0x281a93140>>
 |    | <_UIFloatingContentTransformView: 0x10ec3ede0; frame = (0 0; 200 70); layer = <CATransformLayer: 0x281a92c20>>
 |    |    | <_UIFloatingContentCornerRadiusAnimatingView: 0x10ec35500; frame = (0 0; 200 70); opaque = NO; layer = <CALayer: 0x281a93160>>
 |    |    |    | <UIVisualEffectView: 0x10097e050; frame = (0 0; 200 70); layer = <CALayer: 0x281a82b00>> effect=<UIBlurEffect: 0x2819a91b0> style=UIBlurEffectStyleATVSemiAutomatic invertedAutomaticStyle
 |    |    |    |    | <_UIVisualEffectBackdropView: 0x10fa0b4b0; frame = (0 0; 200 70); autoresize = W+H; userInteractionEnabled = NO; layer = <UICABackdropLayer: 0x281a82d40>>
 |    |    |    |    | <_UIVisualEffectSubview: 0x100961a50; frame = (0 0; 200 70); alpha = 0.4; autoresize = W+H; userInteractionEnabled = NO; layer = <CALayer: 0x281a82ee0>>
 |    |    | <_UIFloatingContentCornerRadiusAnimatingScreenScaleInheritingView: 0x10ec4f910; frame = (0 0; 200 70); clipsToBounds = YES; opaque = NO; layer = <CALayer: 0x281a92be0>>
 |    |    |    | <_UIFloatingContentCornerRadiusAnimatingView: 0x1008af590; frame = (0 0; 200 70); layer = <CALayer: 0x281a92b60>>
 |    |    |    | <UIView: 0x10ec547b0; frame = (0 0; 200 70); layer = <CALayer: 0x281a9e900>>
 |    |    |    |    | <UIButtonLabel: 0x100868630; frame = (65 12; 70 46); text = 'OFF'; opaque = NO; userInteractionEnabled = NO; layer = <_UILabelLayer: 0x2838d3520>>`
 
 
 UIButtons have a crazy heirarchy on tvOS - and changing the background color of the ACTUAL button isn't supported (as far as im aware) so this is one way to do it!
 
 */

- (void)_updateBackgroundForMode {
    if ([self isOn]){
        [self setBackgroundColor:self.onTintColor];
    } else {
        [self setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.5]];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    UIView *bgView = [self flex_findFirstSubviewWithClass:objc_getClass("_UIVisualEffectSubview")]; //this class has been around since tvOS 9, so this is definitely safe.
    if (bgView) {
        bgView.backgroundColor = backgroundColor;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateBackgroundForMode];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _isOn = on;
    if (_isOn){
        [self setTitle:[self onTitle] forState:UIControlStateNormal];
    } else {
        [self setTitle:[self offTitle] forState:UIControlStateNormal];
    }
    [self _updateBackgroundForMode];
    //[self sendActionsForControlEvents:[self allControlEvents]];
}

+ (id)newSwitch {
    UIFLEXSwitch *new = [UIFLEXSwitch buttonWithType:UIButtonTypeSystem];
    [new initDefaults];
    return new;
}

@end

