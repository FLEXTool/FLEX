//
//  FLEXToolbarButton.m
//
//  Created by Tanner on 6/11/17.
//

#import "TBToolbarButton.h"
#import "UIFont+FLEX.h"
#import "FLEXUtility.h"

@interface TBToolbarButton ()
@property (nonatomic      ) NSString *title;
@property (nonatomic, copy) TBToolbarAction buttonPressBlock;
@property (nonatomic      ) UIView *backgroundView;
/// YES if appearance is set to `default`
@property (nonatomic, readonly) BOOL useSystemAppearance;
/// YES if the current trait collection is set to dark mode and \c useSystemAppearance is YES
@property (nonatomic, readonly) BOOL usingDarkMode;
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
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowOpacity = 0.25f;
        self.layer.shadowRadius  = 0.f;
        self.layer.cornerRadius  = 5.f;
        self.layer.borderWidth   = 1.f;
        self.clipsToBounds       = NO;
        self.titleLabel.font     = [UIFont flex_codeFont];
        [self setTitle:self.title forState:UIControlStateNormal];
        [self sizeToFit];
        
        if (@available(iOS 13, *)) {
            self.appearance = UIKeyboardTypeDefault;
        } else {
            self.appearance = UIKeyboardAppearanceLight;
        }
        
        CGRect frame = self.frame;
        frame.size.width  += 40;
        frame.size.height += 10;
        self.frame = frame;
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
    
    if (self.backgroundView.superview) {
        [self.backgroundView removeFromSuperview];
    }
    
    UIColor *titleColor = nil, *borderColor = nil;
    UIBlurEffectStyle style;
    
    switch (_appearance) {
        default:
        case UIKeyboardAppearanceDefault:
            #if FLEX_AT_LEAST_IOS13_SDK
            if (@available(iOS 13, *)) {
                borderColor = [UIColor clearColor];
                titleColor = [UIColor labelColor];
                
                if (self.usingDarkMode) {
                    style = UIBlurEffectStyleSystemUltraThinMaterialLight;
                } else {
                    style = UIBlurEffectStyleSystemMaterialLight;
                }
                break;
            }
            #endif
        case UIKeyboardAppearanceLight:
            borderColor = [UIColor colorWithWhite:1.000 alpha:0.500];
            titleColor = [UIColor blackColor];
            style = UIBlurEffectStyleRegular;
            break;
        case UIKeyboardAppearanceDark:
            borderColor = [UIColor clearColor];
            titleColor = [UIColor whiteColor];
            style = UIBlurEffectStyleDark;
            break;
    }
    
    self.layer.borderColor = borderColor.CGColor;
    [self setTitleColor:titleColor forState:UIControlStateNormal];
    
    UIVisualEffect *blur = [UIBlurEffect effectWithStyle:style];
    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.layer.cornerRadius = self.layer.cornerRadius;
    self.backgroundView.clipsToBounds = YES;
    // Without these, the background view blocks the button's touches
    self.backgroundView.userInteractionEnabled = NO;
    self.backgroundView.exclusiveTouch = NO;
    
    [self insertSubview:self.backgroundView atIndex:0];
    self.backgroundView.frame = self.bounds;
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
