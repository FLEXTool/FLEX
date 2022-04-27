//
//  FLEXKeyboardShortcutManager.m
//  FLEX
//
//  Created by Ryan Olson on 9/19/15.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXKeyboardShortcutManager.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>
#import <objc/message.h>

#if TARGET_OS_SIMULATOR || TARGET_OS_MACCATALYST

@interface UIEvent (UIPhysicalKeyboardEvent)

@property (nonatomic) NSString *_modifiedInput;
@property (nonatomic) NSString *_unmodifiedInput;
@property (nonatomic) UIKeyModifierFlags _modifierFlags;
@property (nonatomic) BOOL _isKeyDown;
@property (nonatomic) long _keyCode;

@end

#if TARGET_OS_MACCATALYST

@interface FLEXKeyInput : UIKeyCommand @end

@interface UIKeyCommand (FLEX)

@property (nonatomic, assign, readonly) BOOL isCreatedByFLEX;

#else

@interface FLEXKeyInput : NSObject <NSCopying>

#endif

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, readonly) UIKeyModifierFlags flags;
@property (nonatomic, copy, readonly) NSString *helpDescription;

@end

#if TARGET_OS_MACCATALYST

@implementation FLEXKeyInput @end

@implementation UIKeyCommand (FLEX)

- (NSString *)key {

    return objc_getAssociatedObject(self, @selector(key));
}

- (void)setKey:(NSString *)key {

    objc_setAssociatedObject(self, @selector(key), key, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIKeyModifierFlags)flags {

    UIKeyModifierFlags (^block)() = objc_getAssociatedObject(self, @selector(flags));

    return (block ? block() : kNilOptions);
}

- (void)setFlags:(UIKeyModifierFlags)flags {

    UIKeyModifierFlags (^block)() = ^{
        return flags;
    };

    objc_setAssociatedObject(self, @selector(flags), block, OBJC_ASSOCIATION_COPY);
}

- (NSString *)helpDescription {

    return objc_getAssociatedObject(self, @selector(helpDescription));
}

- (void)setHelpDescription:(NSString *)helpDescription {

    objc_setAssociatedObject(self, @selector(helpDescription), helpDescription, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)isCreatedByFLEX {

    BOOL (^block)() = objc_getAssociatedObject(self, @selector(isCreatedByFLEX));

    return (block ? block() : NO);
}

- (void)setIsCreatedByFLEX:(BOOL)isCreatedByFLEX {

    BOOL (^block)() = ^{
        return isCreatedByFLEX;
    };

    objc_setAssociatedObject(self, @selector(isCreatedByFLEX), block, OBJC_ASSOCIATION_COPY);
}

#else

@implementation FLEXKeyInput

#endif

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
#if TARGET_OS_MACCATALYST
    if ([object isKindOfClass:[UIKeyCommand class]]) {
        UIKeyCommand *keyCommand = (UIKeyCommand *)object;
        if (!keyCommand.isCreatedByFLEX) {
            // Not FLEX's business anymore.

            return [super isEqual:object];
        }
#else
    if ([object isKindOfClass:[FLEXKeyInput class]]) {
        FLEXKeyInput *keyCommand = (FLEXKeyInput *)object;
#endif
        BOOL equalKeys = self.key == keyCommand.key || [self.key isEqual:keyCommand.key];
        BOOL equalFlags = self.flags == keyCommand.flags;
        isEqual = equalKeys && equalFlags;
    }
    return isEqual;
}

- (NSUInteger)hash {
    return self.key.hash ^ self.flags;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self class] keyInputForKey:self.key flags:self.flags helpDescription:self.helpDescription];
}

- (NSString *)description {
    NSDictionary<NSString *, NSString *> *keyMappings = @{
        UIKeyInputUpArrow : @"↑",
        UIKeyInputDownArrow : @"↓",
        UIKeyInputLeftArrow : @"←",
        UIKeyInputRightArrow : @"→",
        UIKeyInputEscape : @"␛",
        @" " : @"␠"
    };
    
    NSString *prettyKey = nil;
    if (self.key && keyMappings[self.key]) {
        prettyKey = keyMappings[self.key];
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
    if (prettyFlags.length < 2) {
        prettyKey = [prettyKey stringByAppendingString:@"\t"];
    }
    
    return [NSString stringWithFormat:@"%@%@\t%@", prettyFlags, prettyKey, self.helpDescription];
}

+ (instancetype)keyInputForKey:(NSString *)key flags:(UIKeyModifierFlags)flags {
    return [self keyInputForKey:key flags:flags helpDescription:nil];
}

#if TARGET_OS_MACCATALYST

+ (instancetype)keyInputForKey:(NSString *)key
                         flags:(UIKeyModifierFlags)flags
               helpDescription:(NSString *)helpDescription {
    FLEXKeyInput *keyInput = [UIKeyCommand keyCommandWithInput:key modifierFlags:flags action:nil];
    if (keyInput) {
        [keyInput setKey:key];
        [keyInput setFlags:flags];
        [keyInput setHelpDescription:helpDescription];

        [keyInput setIsCreatedByFLEX:YES];
    }
    return keyInput;
}

#else

+ (instancetype)keyInputForKey:(NSString *)key
                         flags:(UIKeyModifierFlags)flags
               helpDescription:(NSString *)helpDescription {
    FLEXKeyInput *keyInput = [self new];
    if (keyInput) {
        keyInput->_key = key;
        keyInput->_flags = flags;
        keyInput->_helpDescription = helpDescription;
    }
    return keyInput;
}

#endif

@end

@interface FLEXKeyboardShortcutManager ()

#if TARGET_OS_MACCATALYST
@property (nonatomic, strong) NSMutableDictionary<UIKeyCommand *, dispatch_block_t> *actionsForKeyInputs;
#else
@property (nonatomic) NSMutableDictionary<FLEXKeyInput *, dispatch_block_t> *actionsForKeyInputs;
#endif

@property (nonatomic, getter=isPressingShift) BOOL pressingShift;
@property (nonatomic, getter=isPressingCommand) BOOL pressingCommand;
@property (nonatomic, getter=isPressingControl) BOOL pressingControl;

@end

@implementation FLEXKeyboardShortcutManager

+ (instancetype)sharedManager {
    static FLEXKeyboardShortcutManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

+ (void)load {
    SEL originalKeyEventSelector = NSSelectorFromString(@"handleKeyUIEvent:");
    SEL swizzledKeyEventSelector = [FLEXUtility swizzledSelectorForSelector:originalKeyEventSelector];
    
    void (^handleKeyUIEventSwizzleBlock)(UIApplication *, UIEvent *) = ^(UIApplication *slf, UIEvent *event) {
        
        [[[self class] sharedManager] handleKeyboardEvent:event];
        
        ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledKeyEventSelector, event);
    };
    
    [FLEXUtility replaceImplementationOfKnownSelector:originalKeyEventSelector
        onClass:[UIApplication class]
        withBlock:handleKeyUIEventSwizzleBlock
        swizzledSelector:swizzledKeyEventSelector
    ];
    
    if ([[UITouch class] instancesRespondToSelector:@selector(maximumPossibleForce)]) {
        SEL originalSendEventSelector = NSSelectorFromString(@"sendEvent:");
        SEL swizzledSendEventSelector = [FLEXUtility swizzledSelectorForSelector:originalSendEventSelector];
        
        void (^sendEventSwizzleBlock)(UIApplication *, UIEvent *) = ^(UIApplication *slf, UIEvent *event) {
            if (event.type == UIEventTypeTouches) {
                FLEXKeyboardShortcutManager *keyboardManager = FLEXKeyboardShortcutManager.sharedManager;
                NSInteger pressureLevel = 0;
                if (keyboardManager.isPressingShift) {
                    pressureLevel++;
                }
                if (keyboardManager.isPressingCommand) {
                    pressureLevel++;
                }
                if (keyboardManager.isPressingControl) {
                    pressureLevel++;
                }
                if (pressureLevel > 0) {
                    if (@available(iOS 9.0, *)) {
                        for (UITouch *touch in [event allTouches]) {
                            double adjustedPressureLevel = pressureLevel * 20 * touch.maximumPossibleForce;
                            [touch setValue:@(adjustedPressureLevel) forKey:@"_pressure"];
                        }
                    }
                }
            }
            
            ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzledSendEventSelector, event);
        };
        
        [FLEXUtility replaceImplementationOfKnownSelector:originalSendEventSelector
            onClass:[UIApplication class]
            withBlock:sendEventSwizzleBlock
            swizzledSelector:swizzledSendEventSelector
        ];
        
        SEL originalSupportsTouchPressureSelector = NSSelectorFromString(@"_supportsForceTouch");
        SEL swizzledSupportsTouchPressureSelector = [FLEXUtility swizzledSelectorForSelector:originalSupportsTouchPressureSelector];
        
        BOOL (^supportsTouchPressureSwizzleBlock)(UIDevice *) = ^BOOL(UIDevice *slf) {
            return YES;
        };
        
        [FLEXUtility replaceImplementationOfKnownSelector:originalSupportsTouchPressureSelector
            onClass:[UIDevice class]
            withBlock:supportsTouchPressureSwizzleBlock
            swizzledSelector:swizzledSupportsTouchPressureSelector
        ];
    }
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _actionsForKeyInputs = [NSMutableDictionary new];
        _enabled = YES;
    }
    
    return self;
}

- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description
                           allowOverride:(BOOL)allowOverride {
    FLEXKeyInput *keyInput = [FLEXKeyInput keyInputForKey:key flags:modifiers helpDescription:description];
    if (!allowOverride && self.actionsForKeyInputs[keyInput] != nil) {
        return;
    } else {
        [self.actionsForKeyInputs setObject:action forKey:keyInput];
    }
}

static const long kFLEXControlKeyCode = 0xe0;
static const long kFLEXShiftKeyCode = 0xe1;
static const long kFLEXCommandKeyCode = 0xe3;

- (void)handleKeyboardEvent:(UIEvent *)event {
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
    
    BOOL interactionEnabled = !UIApplication.sharedApplication.isIgnoringInteractionEvents;
    BOOL hasFirstResponder = NO;
    if (isKeyDown && modifiedInput.length > 0 && interactionEnabled) {
        UIResponder *firstResponder = nil;
        for (UIWindow *window in FLEXUtility.allWindows) {
            firstResponder = [window valueForKey:@"firstResponder"];
            if (firstResponder) {
                hasFirstResponder = YES;
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
            
            dispatch_block_t actionBlock = self.actionsForKeyInputs[exactMatch];
            
            if (!actionBlock) {
                FLEXKeyInput *shiftMatch = [FLEXKeyInput
                    keyInputForKey:modifiedInput flags:flags&(~UIKeyModifierShift)
                ];
                actionBlock = self.actionsForKeyInputs[shiftMatch];
            }
            
            if (!actionBlock) {
                FLEXKeyInput *capitalMatch = [FLEXKeyInput
                    keyInputForKey:[unmodifiedInput uppercaseString] flags:flags
                ];
                actionBlock = self.actionsForKeyInputs[capitalMatch];
            }
            
            if (actionBlock) {
                actionBlock();
            }
        }
    }
    
    // Calling _keyCode on events from the simulator keyboard will crash.
    // It is only safe to call _keyCode when there's not an active responder.
    if (!hasFirstResponder && [event respondsToSelector:@selector(_keyCode)]) {
        long keyCode = [event _keyCode];
        if (keyCode == kFLEXControlKeyCode) {
            self.pressingControl = isKeyDown;
        } else if (keyCode == kFLEXCommandKeyCode) {
            self.pressingCommand = isKeyDown;
        } else if (keyCode == kFLEXShiftKeyCode) {
            self.pressingShift = isKeyDown;
        }
    }
}

- (NSString *)keyboardShortcutsDescription {
    NSMutableString *description = [NSMutableString new];
    NSArray<FLEXKeyInput *> *keyInputs = [self.actionsForKeyInputs.allKeys
        sortedArrayUsingComparator:^NSComparisonResult(FLEXKeyInput *input1, FLEXKeyInput *input2) {
            return [input1.key caseInsensitiveCompare:input2.key];
        }
    ];
    for (FLEXKeyInput *keyInput in keyInputs) {
        [description appendFormat:@"%@\n", keyInput];
    }
    return [description copy];
}

#if TARGET_OS_MACCATALYST

- (NSArray<UIKeyCommand *> *)getKeyCommands {
    return self.actionsForKeyInputs.allKeys;
}

#endif

@end

#endif
