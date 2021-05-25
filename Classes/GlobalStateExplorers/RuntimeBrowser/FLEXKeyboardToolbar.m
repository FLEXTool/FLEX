//
//  FLEXKeyboardToolbar.m
//  FLEX
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXKeyboardToolbar.h"
#import "FLEXUtility.h"

#define kToolbarHeight 44
#define kButtonSpacing 6
#define kScrollViewHorizontalMargins 3

@interface FLEXKeyboardToolbar ()

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

@implementation FLEXKeyboardToolbar

+ (instancetype)toolbarWithButtons:(NSArray *)buttons {
    return [[self alloc] initWithButtons:buttons];
}

- (id)initWithButtons:(NSArray *)buttons {
    self = [super initWithFrame:CGRectMake(0, 0, self.window.rootViewController.view.bounds.size.width, kToolbarHeight)];
    if (self) {
        _buttons = [buttons copy];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if (@available(iOS 13, *)) {
            self.appearance = UIKeyboardAppearanceDefault;
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
    
    // Layout top border
    CGRect frame = _toolbarView.bounds;
    frame.size.height = 0.5;
    _topBorder.frame = frame;
    
    // Scroll view //
    
    frame = CGRectMake(0, 0, self.bounds.size.width, kToolbarHeight);
    CGSize contentSize = self.scrollView.contentSize;
    CGFloat scrollViewWidth = frame.size.width;
    
    // If our content size is smaller than the scroll view,
    // we want to right-align all the content
    if (contentSize.width < scrollViewWidth) {
        // Compute the content size to scroll view size difference
        UIEdgeInsets insets = self.scrollView.contentInset;
        CGFloat margin = insets.left + insets.right;
        CGFloat difference = scrollViewWidth - contentSize.width - margin;
        // Update the content size to be the full width of the scroll view
        contentSize.width += difference;
        self.scrollView.contentSize = contentSize;
        
        // Offset every button by the difference above
        // so that every button appears right-aligned
        for (UIView *button in self.scrollView.subviews) {
            CGRect f = button.frame;
            f.origin.x += difference;
            button.frame = f;
        }
    }
}

- (UIView *)inputAccessoryView {
    _topBorder       = [CALayer new];
    _topBorder.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, 0.5);
    [self makeScrollView];
    
    UIColor *borderColor = nil, *backgroundColor = nil;
    UIColor *lightColor = [UIColor colorWithHue:216.0/360.0 saturation:0.05 brightness:0.85 alpha:1];
    UIColor *darkColor = [UIColor colorWithHue:220.0/360.0 saturation:0.07 brightness:0.16 alpha:1];
    
    switch (_appearance) {
        case UIKeyboardAppearanceDefault:
            if (@available(iOS 13, *)) {
                borderColor = UIColor.systemBackgroundColor;
                
                if (self.usingDarkMode) {
                    // style = UIBlurEffectStyleSystemThickMaterial;
                    backgroundColor = darkColor;
                } else {
                    // style = UIBlurEffectStyleSystemUltraThinMaterialLight;
                    backgroundColor = lightColor;
                }
                break;
            }
        case UIKeyboardAppearanceLight: {
            borderColor = UIColor.clearColor;
            backgroundColor = lightColor;
            break;
        }
        case UIKeyboardAppearanceDark: {
            borderColor = [UIColor colorWithWhite:0.100 alpha:1.000];
            backgroundColor = darkColor;
            break;
        }
    }
    
    self.toolbarView = [UIView new];
    [self.toolbarView addSubview:self.scrollView];
    [self.toolbarView.layer addSublayer:self.topBorder];
    self.toolbarView.frame = CGRectMake(0, 0, self.bounds.size.width, kToolbarHeight);
    self.toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.backgroundColor = backgroundColor;
    self.topBorder.backgroundColor = borderColor.CGColor;
    
    return self.toolbarView;
}

- (UIScrollView *)makeScrollView {
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.backgroundColor  = UIColor.clearColor;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.contentInset     = UIEdgeInsetsMake(
        8.f, kScrollViewHorizontalMargins, 4.f, kScrollViewHorizontalMargins
    );
    scrollView.showsHorizontalScrollIndicator = NO;
    
    self.scrollView = scrollView;
    [self addButtons];
    
    return scrollView;
}

- (void)addButtons {
    NSUInteger originX = 0.f;
    
    CGRect originFrame;
    CGFloat top    = self.scrollView.contentInset.top;
    CGFloat bottom = self.scrollView.contentInset.bottom;
    
    for (FLEXKBToolbarButton *button in self.buttons) {
        button.appearance = self.appearance;
        
        originFrame             = button.frame;
        originFrame.origin.x    = originX;
        originFrame.origin.y    = 0.f;
        originFrame.size.height = kToolbarHeight - (top + bottom);
        button.frame            = originFrame;
        
        [self.scrollView addSubview:button];
        
        // originX tracks the origin of the next button to be added,
        // so at the end of each iteration of this loop we increment
        // it by the size of the last button with some padding
        originX += button.bounds.size.width + kButtonSpacing;
    }
    
    // Update contentSize,
    // set to the max x value of the last button added
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.width  = originX - kButtonSpacing;
    self.scrollView.contentSize = contentSize;
    
    // Needed to potentially right-align buttons
    [self setNeedsLayout];
}

- (void)setButtons:(NSArray<FLEXKBToolbarButton *> *)buttons {
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _buttons = buttons.copy;
    
    [self addButtons];
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
