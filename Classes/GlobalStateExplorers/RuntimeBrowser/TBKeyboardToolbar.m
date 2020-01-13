//
//  FLEXKeyboardToolbar.m
//
//  Created by Tanner on 6/11/17.
//

#import "TBKeyboardToolbar.h"
#import "FLEXUtility.h"

#define kToolbarHeight 44

@interface TBKeyboardToolbar ()

/// The fake top border to replicate the toolbar.
@property (nonatomic) CALayer      *topBorder;
@property (nonatomic) UIView       *toolbarView;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIVisualEffectView *blurView;
/// YES if appearance is set to `default`
@property (nonatomic, readonly) BOOL useSystemAppearance;
/// YES if the current trait collection is set to dark mode and \c useSystemAppearance is YES
@property (nonatomic, readonly) BOOL usingDarkMode;
@end

@implementation TBKeyboardToolbar

+ (instancetype)toolbarWithButtons:(NSArray *)buttons {
    return [[self alloc] initWithButtons:buttons];
}

- (id)initWithButtons:(NSArray *)buttons {
    self = [super initWithFrame:CGRectMake(0, 0, self.window.rootViewController.view.bounds.size.width, kToolbarHeight)];
    if (self) {
        _buttons = [buttons copy];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if (@available(iOS 13, *)) {
            self.appearance = UIKeyboardTypeDefault;
        } else {
            self.appearance = UIKeyboardAppearanceLight;
        }
    }
    
    return self;
}

- (void)setAppearance:(UIKeyboardAppearance)appearance {
    _appearance = appearance;
    
    // Remove toolbar if it exits because it will be recreated below
    if (self.toolbarView) {
        [self.toolbarView removeFromSuperview];
    }
    
    [self addSubview:self.inputAccessoryView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = _toolbarView.bounds;
    frame.size.height = 0.5f;
    
    _topBorder.frame = frame;
}

- (UIView *)inputAccessoryView {
    _topBorder       = [CALayer layer];
    _topBorder.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, 0.5f);
    
    UIColor *borderColor = nil;
    UIBlurEffectStyle style;
    
    switch (_appearance) {
        case UIKeyboardAppearanceDefault:
            #if FLEX_AT_LEAST_IOS13_SDK
            if (@available(iOS 13, *)) {
                borderColor = [UIColor systemBackgroundColor];
                
                if (self.usingDarkMode) {
                    style = UIBlurEffectStyleSystemThickMaterial;
                    self.backgroundColor = nil;
                } else {
                    style = UIBlurEffectStyleSystemUltraThinMaterialLight;
                    self.backgroundColor = [UIColor colorWithWhite:0.700 alpha:0.750];
                }
                break;
            }
            #endif
        case UIKeyboardAppearanceLight: {
            style = UIBlurEffectStyleLight;
            borderColor = [UIColor clearColor];
            break;
        }
        case UIKeyboardAppearanceDark: {
            style = UIBlurEffectStyleDark;
            borderColor = [UIColor colorWithWhite:0.100 alpha:1.000];
            break;
        }
    }
    
    UIVisualEffect *blur = [UIBlurEffect effectWithStyle:style];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    [self.blurView.contentView.layer addSublayer:self.topBorder];
    [self.blurView.contentView addSubview:[self fakeToolbar]];
    
    self.toolbarView = self.blurView;
    self.toolbarView.frame = CGRectMake(0, 0, self.bounds.size.width, kToolbarHeight);
    self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.topBorder.backgroundColor = borderColor.CGColor;
    
    return self.toolbarView;
}

- (UIScrollView *)fakeToolbar {
    _scrollView                  = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, kToolbarHeight)];
    _scrollView.backgroundColor  = [UIColor clearColor];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.contentInset     = UIEdgeInsetsMake(8.0f, 0.0f, 4.0f, 6.0f);
    _scrollView.showsHorizontalScrollIndicator = NO;
    
    [self addButtons];
    
    return _scrollView;
}

- (void)addButtons {
    NSUInteger spacing = 6;
    NSUInteger originX = spacing;
    
    CGRect originFrame;
    CGFloat top    = _scrollView.contentInset.top;
    CGFloat bottom = _scrollView.contentInset.bottom;
    
    for (TBToolbarButton *button in _buttons) {
        button.appearance = self.appearance;
        
        originFrame             = button.frame;
        originFrame.origin.x    = originX;
        originFrame.origin.y    = 0;
        originFrame.size.height = kToolbarHeight - (top + bottom);
        button.frame            = originFrame;
        
        [_scrollView addSubview:button];
        
        originX += button.bounds.size.width + spacing;
    }
    
    CGSize contentSize = _scrollView.contentSize;
    contentSize.width  = originX - spacing;
    _scrollView.contentSize = contentSize;
}

- (void)setButtons:(NSArray<TBToolbarButton *> *)buttons {
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _buttons = buttons.copy;
    
    [self addButtons];
}

- (void)setButtons:(NSArray<TBToolbarButton *> *)buttons animated:(BOOL)animated {
    if (!animated) {
        self.buttons = buttons;
        return;
    }
    
    NSMutableSet *buttonstoRemove = [NSMutableSet setWithArray:_buttons];
    [buttonstoRemove minusSet:[NSSet setWithArray:buttons]];

    NSMutableSet *buttonsToAdd = [NSMutableSet setWithArray:buttons];
    [buttonsToAdd minusSet:[NSSet setWithArray:_buttons]];

    if (!buttonstoRemove.count && !buttonsToAdd.count) {
        return;
    }

    // New buttons are invisible at first
    for (TBToolbarButton *button in buttons) {
        button.alpha = 0;
    }

    [UIView animateWithDuration:0.1 animations:^{
        // Fade out old buttons
        for (TBToolbarButton *button in _buttons) {
            button.alpha = 0;
        }
    } completion:^(BOOL finished) {
        // Remove old, add new
        self.buttons = buttons;
        [UIView animateWithDuration:0.1 animations:^{
            // Fade in new buttons
            for (TBToolbarButton *button in buttons) {
                button.alpha = 1;
            }
        }];
    }];
}

- (BOOL)useSystemAppearance {
    return self.appearance == UIKeyboardAppearanceDefault;
}

- (BOOL)usingDarkMode {
    if (@available(iOS 12, *)) {
        return self.useSystemAppearance && self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    
    return self.appearance == UIKeyboardAppearanceDark;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    if (@available(iOS 12, *)) {
        // Was darkmode toggled?
        if (previous.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
            if (self.useSystemAppearance) {
                // Recreate the background view with the proper colors
                self.appearance = self.appearance;
            }
        }
    }
}

@end
