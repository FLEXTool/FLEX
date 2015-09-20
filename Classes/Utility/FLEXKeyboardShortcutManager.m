//
//  FLEXKeyboardShortcutManager.m
//  FLEX
//
//  Created by Ryan Olson on 9/19/15.
//  Copyright © 2015 Flipboard. All rights reserved.
//

#import "FLEXKeyboardShortcutManager.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>
#import <objc/message.h>

#if TARGET_OS_SIMULATOR

@interface UIEvent (UIPhysicalKeyboardEvent)

@property (nonatomic, strong) NSString *_modifiedInput;
@property (nonatomic, strong) NSString *_unmodifiedInput;
@property (nonatomic, assign) UIKeyModifierFlags _modifierFlags;
@property (nonatomic, assign) BOOL _isKeyDown;

@end

@interface FLEXKeyInput : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, assign, readonly) UIKeyModifierFlags flags;
@property (nonatomic, copy, readonly) NSString *helpDescription;

@end

@implementation FLEXKeyInput

- (BOOL)isEqual:(id)object
{
    BOOL isEqual = NO;
    if ([object isKindOfClass:[FLEXKeyInput class]]) {
        FLEXKeyInput *keyCommand = (FLEXKeyInput *)object;
        BOOL equalKeys = self.key == keyCommand.key || [self.key isEqual:keyCommand.key];
        BOOL equalFlags = self.flags == keyCommand.flags;
        isEqual = equalKeys && equalFlags;
    }
    return isEqual;
}

- (NSUInteger)hash
{
    return [self.key hash] ^ self.flags;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[self class] keyInputForKey:self.key flags:self.flags helpDescription:self.helpDescription];
}

- (NSString *)description
{
    NSDictionary *keyMappings = @{ UIKeyInputUpArrow : @"↑",
                                   UIKeyInputDownArrow : @"↓",
                                   UIKeyInputLeftArrow : @"←",
                                   UIKeyInputRightArrow : @"→",
                                   UIKeyInputEscape : @"␛",
                                   @" " : @"␠"};
    
    NSString *prettyKey = nil;
    if (self.key && [keyMappings objectForKey:self.key]) {
        prettyKey = [keyMappings objectForKey:self.key];
    } else {
        prettyKey = [self.key uppercaseString];
    }
    
    NSString *prettyFlags = @"";
    if (self.flags & UIKeyModifierControl) {
        prettyFlags = [prettyFlags stringByAppendingString:@"⌃"];
    }
    if (self.flags & UIKeyModifierAlternate) {
        prettyFlags = [prettyFlags stringByAppendingString:@"⌥"];
    }
    if (self.flags & UIKeyModifierShift) {
        prettyFlags = [prettyFlags stringByAppendingString:@"⇧"];
    }
    if (self.flags & UIKeyModifierCommand) {
        prettyFlags = [prettyFlags stringByAppendingString:@"⌘"];
    }
    
    // Fudging to get easy columns with tabs
    if ([prettyFlags length] < 2) {
        prettyKey = [prettyKey stringByAppendingString:@"\t"];
    }
    
    return [NSString stringWithFormat:@"%@%@\t%@", prettyFlags, prettyKey, self.helpDescription];
}

+ (instancetype)keyInputForKey:(NSString *)key flags:(UIKeyModifierFlags)flags
{
    return [self keyInputForKey:key flags:flags helpDescription:nil];
}

+ (instancetype)keyInputForKey:(NSString *)key flags:(UIKeyModifierFlags)flags helpDescription:(NSString *)helpDescription
{
    FLEXKeyInput *keyInput = [[self alloc] init];
    if (keyInput) {
        keyInput->_key = key;
        keyInput->_flags = flags;
        keyInput->_helpDescription = helpDescription;
    }
    return keyInput;
}

@end

@interface FLEXKeyboardShortcutManager ()

@property (nonatomic, strong) NSMutableDictionary *actionsForKeyInputs;

@end

@implementation FLEXKeyboardShortcutManager

+ (instancetype)sharedManager
{
    static FLEXKeyboardShortcutManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

+ (void)load
{
    SEL originalKeyEventSelector = NSSelectorFromString(@"handleKeyUIEvent:");
    SEL swizzledKeyEventSelector = [FLEXUtility swizzledSelectorForSelector:originalKeyEventSelector];
    
    void (^sendEventSwizzleBlock)(UIApplication *, UIEvent *) = ^(UIApplication *slf, UIEvent *event) {
        
        [[[self class] sharedManager] handleKeyboardEvent:event];
        
        ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledKeyEventSelector, event);
    };
    
    [FLEXUtility replaceImplementationOfKnownSelector:originalKeyEventSelector onClass:[UIApplication class] withBlock:sendEventSwizzleBlock swizzledSelector:swizzledKeyEventSelector];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _actionsForKeyInputs = [NSMutableDictionary dictionary];
        _enabled = YES;
    }
    
    return self;
}

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description
{
    FLEXKeyInput *keyInput = [FLEXKeyInput keyInputForKey:key flags:modifiers helpDescription:description];
    [self.actionsForKeyInputs setObject:action forKey:keyInput];
}

- (void)handleKeyboardEvent:(UIEvent *)event
{
    if (!self.enabled) {
        return;
    }
    
    NSString *modifiedInput = nil;
    NSString *unmodifiedInput = nil;
    UIKeyModifierFlags flags = 0;
    BOOL isKeyDown = NO;
    
    if ([event respondsToSelector:@selector(_modifiedInput)]) {
        modifiedInput = [event _modifiedInput];
    }
    
    if ([event respondsToSelector:@selector(_unmodifiedInput)]) {
        unmodifiedInput = [event _unmodifiedInput];
    }
    
    if ([event respondsToSelector:@selector(_modifierFlags)]) {
        flags = [event _modifierFlags];
    }
    
    if ([event respondsToSelector:@selector(_isKeyDown)]) {
        isKeyDown = [event _isKeyDown];
    }
    
    BOOL interactionEnabled = ![[UIApplication sharedApplication] isIgnoringInteractionEvents];
    
    if (isKeyDown && [modifiedInput length] > 0 && interactionEnabled) {
        UIResponder *firstResponder = nil;
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            firstResponder = [window valueForKey:@"firstResponder"];
            if (firstResponder) {
                break;
            }
        }
        
        // Ignore key commands (except escape) when there's an active responder
        if (firstResponder) {
            if ([unmodifiedInput isEqual:UIKeyInputEscape]) {
                [firstResponder resignFirstResponder];
            }
        } else {
            FLEXKeyInput *exactMatch = [FLEXKeyInput keyInputForKey:unmodifiedInput flags:flags];
            
            dispatch_block_t actionBlock = [self.actionsForKeyInputs objectForKey:exactMatch];
            
            if (!actionBlock) {
                FLEXKeyInput *shiftMatch = [FLEXKeyInput keyInputForKey:modifiedInput flags:flags&(!UIKeyModifierShift)];
                actionBlock = [self.actionsForKeyInputs objectForKey:shiftMatch];
            }
            
            if (!actionBlock) {
                FLEXKeyInput *capitalMatch = [FLEXKeyInput keyInputForKey:[unmodifiedInput uppercaseString] flags:flags];
                actionBlock = [self.actionsForKeyInputs objectForKey:capitalMatch];
            }
            
            if (actionBlock) {
                actionBlock();
            }
        }
    }
}

- (NSString *)keyboardShortcutsDescription
{
    NSMutableString *description = [NSMutableString string];
    NSArray *keyInputs = [[self.actionsForKeyInputs allKeys] sortedArrayUsingComparator:^NSComparisonResult(FLEXKeyInput *_Nonnull input1, FLEXKeyInput *_Nonnull input2) {
        return [input1.key caseInsensitiveCompare:input2.key];
    }];
    for (FLEXKeyInput *keyInput in keyInputs) {
        [description appendFormat:@"%@\n", keyInput];
    }
    return [description copy];
}

@end

#endif
