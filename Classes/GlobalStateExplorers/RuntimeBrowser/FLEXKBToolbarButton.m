//
//  FLEXKBToolbarButton.m
//  FLEX
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXKBToolbarButton.h"
#import "UIFont+FLEX.h"
#import "FLEXUtility.h"
#import "CALayer+FLEX.h"

@interface FLEXKBToolbarButton ()
@property (nonatomic      ) NSString *title;
@property (nonatomic, copy) FLEXKBToolbarAction buttonPressBlock;
/// YES if appearance is set to `default`
@property (nonatomic, readonly) BOOL useSystemAppearance;
/// YES if the current trait collection is set to dark mode and \c useSystemAppearance is YES
@property (nonatomic, readonly) BOOL usingDarkMode;
@end

@implementation FLEXKBToolbarButton

+ (instancetype)buttonWithTitle:(NSString *)title {
    return [[self alloc] initWithTitle:title];
}

+ (instancetype)buttonWithTitle:(NSString *)title action:(FLEXKBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvent {
    FLEXKBToolbarButton *newButton = [self buttonWithTitle:title];
    [newButton addEventHandler:eventHandler forControlEvents:controlEvent];
    return newButton;
}

+ (instancetype)buttonWithTitle:(NSString *)title action:(FLEXKBToolbarAction)eventHandler {
    return [self buttonWithTitle:title action:eventHandler forControlEvents:UIControlEventTouchUpInside];
}

- (id)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowOpacity = 0.35;
        self.layer.shadowRadius  = 0;
        self.layer.cornerRadius  = 5;
        self.clipsToBounds       = NO;
        self.titleLabel.font     = [UIFont systemFontOfSize:18.0];
        self.layer.flex_continuousCorners = YES;
        [self setTitle:self.title forState:UIControlStateNormal];
        [self sizeToFit];
        
        if (@available(iOS 13, *)) {
            self.appearance = UIKeyboardTypeDefault;
        } else {
            self.appearance = UIKeyboardAppearanceLight;
        }
        
        CGRect frame = self.frame;
        frame.size.width  += title.length < 3 ? 30 : 15;
        frame.size.height += 10;
        self.frame = frame;
    }
    
    return self;
}

- (void)addEventHandler:(FLEXKBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvent {
    self.buttonPressBlock = eventHandler;
    [self addTarget:self action:@selector(buttonPressed) forControlEvents:controlEvent];
}

- (void)buttonPressed {
    self.buttonPressBlock(self.title, NO);
}

- (void)setAppearance:(UIKeyboardAppearance)appearance {
    _appearance = appearance;
    
    UIColor *titleColor = nil, *backgroundColor = nil;
    UIColor *lightColor = [UIColor colorWithRed:253.0/255.0 green:253.0/255.0 blue:254.0/255.0 alpha:1];
    UIColor *darkColor = [UIColor colorWithRed:101.0/255.0 green:102.0/255.0 blue:104.0/255.0 alpha:1];
    
    switch (_appearance) {
        default:
        case UIKeyboardAppearanceDefault:
            #if FLEX_AT_LEAST_IOS13_SDK
            if (@available(iOS 13, *)) {
                titleColor = UIColor.labelColor;
                
                if (self.usingDarkMode) {
                    // style = UIBlurEffectStyleSystemUltraThinMaterialLight;
                    backgroundColor = darkColor;
                } else {
                    // style = UIBlurEffectStyleSystemMaterialLight;
                    backgroundColor = lightColor;
                }
                break;
            }
            #endif
        case UIKeyboardAppearanceLight:
            titleColor = UIColor.blackColor;
            backgroundColor = lightColor;
            // style = UIBlurEffectStyleExtraLight;
            break;
        case UIKeyboardAppearanceDark:
            titleColor = UIColor.whiteColor;
            backgroundColor = darkColor;
            // style = UIBlurEffectStyleDark;
            break;
    }
    
    self.backgroundColor = backgroundColor;
    [self setTitleColor:titleColor forState:UIControlStateNormal];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[FLEXKBToolbarButton class]]) {
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


@implementation FLEXKBToolbarSuggestedButton

- (void)buttonPressed {
    self.buttonPressBlock(self.title, YES);
}

@end
