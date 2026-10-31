//
//  FLEXMacEditorViewControllers.m
//  FLEX (macOS)
//

#import "FLEXMacEditorViewControllers.h"
#import "FLEXMacArgumentInputView.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacNavigationController.h"
#import "FLEXMacUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXTypeEncodingParser.h"

#pragma mark - Form base

/// A flipped view so that the scroll view's document starts at the top
@interface FLEXMacFlippedView : NSView
@end
@implementation FLEXMacFlippedView
- (BOOL)isFlipped { return YES; }
@end

@implementation FLEXMacFormViewController

- (void)loadView {
    NSScrollView *scrollView = [NSScrollView new];
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    scrollView.drawsBackground = NO;

    FLEXMacFlippedView *document = [FLEXMacFlippedView new];
    document.translatesAutoresizingMaskIntoConstraints = NO;

    self.stack = [NSStackView stackViewWithViews:@[]];
    self.stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.stack.alignment = NSLayoutAttributeLeading;
    self.stack.spacing = 10;
    self.stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [document addSubview:self.stack];

    scrollView.documentView = document;
    [NSLayoutConstraint activateConstraints:@[
        [document.leadingAnchor constraintEqualToAnchor:scrollView.contentView.leadingAnchor],
        [document.trailingAnchor constraintEqualToAnchor:scrollView.contentView.trailingAnchor],
        [document.topAnchor constraintEqualToAnchor:scrollView.contentView.topAnchor],
        [self.stack.leadingAnchor constraintEqualToAnchor:document.leadingAnchor],
        [self.stack.trailingAnchor constraintEqualToAnchor:document.trailingAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:document.topAnchor],
        [self.stack.bottomAnchor constraintEqualToAnchor:document.bottomAnchor],
    ]];

    self.view = scrollView;
    self.view.frame = NSMakeRect(0, 0, 560, 600);

    self.statusLabel = [NSTextField wrappingLabelWithString:@""];
    self.statusLabel.selectable = YES;
    self.statusLabel.font = [FLEXMacUtility monospacedFontOfSize:12];

    [self buildForm];
}

- (void)buildForm { }

- (NSView *)flex_preferredFirstResponder {
    return self.initialFocus;
}

- (void)addFullWidth:(NSView *)view {
    [self.stack addArrangedSubview:view];
    [view.leadingAnchor constraintEqualToAnchor:self.stack.leadingAnchor constant:16].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.stack.trailingAnchor constant:-16].active = YES;
}

- (NSTextField *)addInfo:(NSString *)title value:(NSString *)value {
    NSTextField *titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    titleLabel.textColor = NSColor.secondaryLabelColor;

    NSTextField *valueLabel = [NSTextField wrappingLabelWithString:value ?: @""];
    valueLabel.font = [FLEXMacUtility monospacedFontOfSize:12];
    valueLabel.selectable = YES;

    NSStackView *group = [NSStackView stackViewWithViews:@[titleLabel, valueLabel]];
    group.orientation = NSUserInterfaceLayoutOrientationVertical;
    group.alignment = NSLayoutAttributeLeading;
    group.spacing = 2;
    [self addFullWidth:group];
    [valueLabel.trailingAnchor constraintLessThanOrEqualToAnchor:group.trailingAnchor].active = YES;
    return valueLabel;
}

- (void)setStatus:(NSString *)status isError:(BOOL)isError {
    self.statusLabel.stringValue = status ?: @"";
    self.statusLabel.textColor = isError ? NSColor.systemRedColor : NSColor.labelColor;
}

@end

#pragma mark - Field editor

@interface FLEXMacFieldEditorViewController ()
@property (nonatomic) id target;
@property (nonatomic, nullable) FLEXProperty *property;
@property (nonatomic, nullable) FLEXIvar *ivar;
@property (nonatomic, copy, nullable) void (^commitHandler)(void);
@property (nonatomic) FLEXMacArgumentInputView *input;
@property (nonatomic) NSTextField *currentValueLabel;
@end

@implementation FLEXMacFieldEditorViewController

+ (const char *)setterArgumentTypeForProperty:(FLEXProperty *)property target:(id)target {
    if (!target) {
        return NULL;
    }
    SEL setter = property.likelySetter;
    if (!setter || ![FLEXRuntimeUtility safeObject:target respondsToSelector:setter]) {
        return NULL;
    }

    FLEXMethod *method = [FLEXMethod selector:setter class:object_getClass(target)];
    NSMethodSignature *signature = method.signature;
    if (signature.numberOfArguments != 3) {
        return NULL;
    }
    return [signature getArgumentTypeAtIndex:2];
}

+ (BOOL)canEditProperty:(FLEXProperty *)property target:(id)target {
    const char *type = [self setterArgumentTypeForProperty:property target:target];
    return type && [FLEXMacArgumentInputView supportsTypeEncoding:type];
}

+ (BOOL)canEditIvar:(FLEXIvar *)ivar target:(id)target {
    if (!target || object_isClass(target) || [ivar.name isEqualToString:@"isa"]) {
        return NO;
    }
    if (ivar.type == FLEXTypeEncodingObjcObject || ivar.type == FLEXTypeEncodingObjcClass) {
        return ivar.type == FLEXTypeEncodingObjcObject && ![ivar.typeEncoding isEqualToString:@"@?"];
    }
    return [FLEXMacArgumentInputView supportsTypeEncoding:ivar.typeEncoding.UTF8String];
}

+ (instancetype)editorForProperty:(FLEXProperty *)property target:(id)target commit:(void (^)(void))commitHandler {
    if (![self canEditProperty:property target:target]) {
        return nil;
    }
    FLEXMacFieldEditorViewController *editor = [self new];
    editor.property = property;
    editor.target = target;
    editor.commitHandler = commitHandler;
    editor.title = [NSString stringWithFormat:@"Edit %@", property.name];
    return editor;
}

+ (instancetype)editorForIvar:(FLEXIvar *)ivar target:(id)target commit:(void (^)(void))commitHandler {
    if (![self canEditIvar:ivar target:target]) {
        return nil;
    }
    FLEXMacFieldEditorViewController *editor = [self new];
    editor.ivar = ivar;
    editor.target = target;
    editor.commitHandler = commitHandler;
    editor.title = [NSString stringWithFormat:@"Edit %@", ivar.name];
    return editor;
}

- (id)currentValue {
    if (self.property) {
        return [self.property getPotentiallyUnboxedValue:self.target];
    }
    return [self.ivar getPotentiallyUnboxedValue:self.target];
}

- (void)buildForm {
    FLEXMacFormViewController *form = self;
    NSString *declaration = self.property ? self.property.fullDescription : self.ivar.description;
    [form addInfo:self.property ? @"PROPERTY" : @"IVAR" value:declaration];
    [form addInfo:@"TARGET" value:[FLEXMacUtility summaryForObject:self.target maxLength:300]];
    self.currentValueLabel = [form addInfo:@"CURRENT VALUE" value:@""];

    const char *type = self.property ?
        [FLEXMacFieldEditorViewController setterArgumentTypeForProperty:self.property target:self.target] :
        self.ivar.typeEncoding.UTF8String;
    self.input = [[FLEXMacArgumentInputView alloc] initWithTypeEncoding:type title:@"New value"];
    [self.input populateWithValue:[self currentValue]];
    [form addFullWidth:self.input];
    form.initialFocus = self.input.firstInputView;

    NSButton *setButton = [NSButton buttonWithTitle:@"Set Value" target:self action:@selector(commit:)];
    setButton.keyEquivalent = @"\r";
    setButton.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    setButton.toolTip = @"⌘↩";

    NSButton *exploreButton = [NSButton buttonWithTitle:@"Explore Current Value" target:self action:@selector(exploreValue:)];

    NSStackView *buttons = [NSStackView stackViewWithViews:@[setButton, exploreButton]];
    buttons.spacing = 8;
    [form.stack addArrangedSubview:buttons];
    [form addFullWidth:form.statusLabel];

    [self refreshCurrentValue];
}

- (void)refreshCurrentValue {
    self.currentValueLabel.stringValue = [FLEXMacUtility summaryForObject:[self currentValue] maxLength:2000];
}

- (void)commit:(id)sender {
    FLEXMacFormViewController *form = self;
    NSError *error = nil;
    id value = [self.input inputValueWithError:&error];
    if (error) {
        [form setStatus:error.localizedDescription isError:YES];
        return;
    }

    if (self.property) {
        [FLEXRuntimeUtility
            performSelector:self.property.likelySetter
            onObject:self.target
            withArguments:@[value ?: NSNull.null]
            error:&error
        ];
    } else {
        @try {
            [self.ivar setValue:value onObject:self.target];
        } @catch (NSException *exception) {
            error = [NSError errorWithDomain:@"FLEX" code:2 userInfo:@{
                NSLocalizedDescriptionKey: exception.reason ?: exception.name
            }];
        }
    }

    if (error) {
        [form setStatus:error.localizedDescription isError:YES];
        return;
    }

    [self refreshCurrentValue];
    [self.input populateWithValue:[self currentValue]];
    [form setStatus:@"✓ Value updated" isError:NO];

    // Redraw views whose state may have changed
    if ([self.target isKindOfClass:[NSView class]]) {
        [(NSView *)self.target setNeedsDisplay:YES];
    }

    if (self.commitHandler) {
        self.commitHandler();
    }
}

- (void)exploreValue:(id)sender {
    id value = [self currentValue];
    NSViewController *explorer = [FLEXMacObjectExplorerViewController explorerForObject:value];
    if (explorer) {
        [self flex_push:explorer];
    } else {
        NSBeep();
    }
}

@end

#pragma mark - Method calling

@interface FLEXMacMethodCallViewController ()
@property (nonatomic) FLEXMethod *method;
@property (nonatomic) id target;
@property (nonatomic) NSArray<FLEXMacArgumentInputView *> *inputs;
@property (nonatomic) NSButton *exploreButton;
@property (nonatomic, nullable) id lastResult;
@end

@implementation FLEXMacMethodCallViewController

+ (BOOL)canCallMethod:(FLEXMethod *)method {
    NSMethodSignature *signature = method.signature;
    if (!signature) {
        return NO;
    }
    for (NSUInteger i = 2; i < signature.numberOfArguments; i++) {
        if (![FLEXMacArgumentInputView supportsTypeEncoding:[signature getArgumentTypeAtIndex:i]]) {
            return NO;
        }
    }
    return YES;
}

+ (instancetype)callerForMethod:(FLEXMethod *)method target:(id)target {
    FLEXMacMethodCallViewController *caller = [self new];
    caller.method = method;
    caller.target = target;
    caller.title = method.selectorString;
    return caller;
}

- (void)buildForm {
    FLEXMacFormViewController *form = self;
    [form addInfo:@"METHOD" value:self.method.description];
    [form addInfo:@"TARGET" value:[FLEXMacUtility summaryForObject:self.target maxLength:300]];

    NSMethodSignature *signature = self.method.signature;
    NSArray<NSString *> *components = [self.method.selectorString componentsSeparatedByString:@":"];
    NSMutableArray<FLEXMacArgumentInputView *> *inputs = [NSMutableArray new];
    for (NSUInteger i = 2; i < signature.numberOfArguments; i++) {
        NSString *name = (i - 2 < components.count) ? [components[i - 2] stringByAppendingString:@":"] : nil;
        FLEXMacArgumentInputView *input = [[FLEXMacArgumentInputView alloc]
            initWithTypeEncoding:[signature getArgumentTypeAtIndex:i] title:name
        ];
        [form addFullWidth:input];
        [inputs addObject:input];
    }
    self.inputs = inputs;
    form.initialFocus = inputs.firstObject.firstInputView;

    if (!inputs.count) {
        NSTextField *label = [NSTextField labelWithString:@"This method takes no arguments."];
        label.textColor = NSColor.secondaryLabelColor;
        [form.stack addArrangedSubview:label];
    }

    NSButton *callButton = [NSButton buttonWithTitle:@"Call" target:self action:@selector(call:)];
    callButton.keyEquivalent = @"\r";
    callButton.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    callButton.toolTip = @"⌘↩";
    callButton.enabled = [FLEXMacMethodCallViewController canCallMethod:self.method];

    self.exploreButton = [NSButton buttonWithTitle:@"Explore Result" target:self action:@selector(exploreResult:)];
    self.exploreButton.enabled = NO;

    NSStackView *buttons = [NSStackView stackViewWithViews:@[callButton, self.exploreButton]];
    buttons.spacing = 8;
    [form.stack addArrangedSubview:buttons];
    [form addFullWidth:form.statusLabel];
}

- (void)call:(id)sender {
    FLEXMacFormViewController *form = self;
    NSMutableArray *arguments = [NSMutableArray new];
    for (FLEXMacArgumentInputView *input in self.inputs) {
        NSError *error = nil;
        id value = [input inputValueWithError:&error];
        if (error) {
            [form setStatus:error.localizedDescription isError:YES];
            return;
        }
        [arguments addObject:value ?: NSNull.null];
    }

    NSError *error = nil;
    id result = [FLEXRuntimeUtility
        performSelector:self.method.selector
        onObject:self.target
        withArguments:arguments
        error:&error
    ];

    if (error) {
        [form setStatus:error.localizedDescription isError:YES];
        self.lastResult = nil;
        self.exploreButton.enabled = NO;
        return;
    }

    const char *returnType = self.method.signature.methodReturnType;
    if (returnType[0] == FLEXTypeEncodingVoid) {
        [form setStatus:@"✓ Method called (void return)" isError:NO];
        self.lastResult = nil;
        self.exploreButton.enabled = NO;
    } else {
        result = [FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:result type:returnType];
        self.lastResult = result;
        self.exploreButton.enabled = result != nil;
        [form setStatus:[@"Returned: " stringByAppendingString:
            [FLEXMacUtility summaryForObject:result maxLength:4000]
        ] isError:NO];
    }
}

- (void)exploreResult:(id)sender {
    NSViewController *explorer = [FLEXMacObjectExplorerViewController explorerForObject:self.lastResult];
    if (explorer) {
        [self flex_push:explorer];
    }
}

@end
