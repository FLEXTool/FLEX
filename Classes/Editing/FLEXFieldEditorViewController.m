//
//  FLEXFieldEditorViewController.m
//  FLEX
//
//  Created by Tanner on 11/22/18.
//  Copyright © 2018 Flipboard. All rights reserved.
//

#import "FLEXFieldEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXUtility.h"

@interface FLEXFieldEditorViewController () <FLEXArgumentInputViewDelegate>

@property (nonatomic) FLEXProperty *property;
@property (nonatomic) FLEXIvar *ivar;

@property (nonatomic, readonly) id currentValue;
@property (nonatomic, readonly) const FLEXTypeEncoding *typeEncoding;
@property (nonatomic, readonly) NSString *fieldDescription;

@end

@implementation FLEXFieldEditorViewController

#pragma mark - Initialization

+ (instancetype)target:(id)target property:(FLEXProperty *)property {
    id value = [FLEXRuntimeUtility valueForProperty:property.objc_property onObject:target];
    if (![self canEditProperty:property onObject:target currentValue:value]) {
        return nil;
    }

    FLEXFieldEditorViewController *editor = [self target:target];
    editor.title = @"Property";
    editor.property = property;
    return editor;
}

+ (instancetype)target:(id)target ivar:(nonnull FLEXIvar *)ivar {
    FLEXFieldEditorViewController *editor = [self target:target];
    editor.title = @"Instance Variable";
    editor.ivar = ivar;
    return editor;
}

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create getter button
    _getterButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Get"
        style:UIBarButtonItemStyleDone
        target:self
        action:@selector(getterButtonPressed:)
    ];
    self.navigationItem.rightBarButtonItems = @[self.setterButton, self.getterButton];

    // Configure input view
    self.fieldEditorView.fieldDescription = self.fieldDescription;
    FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:self.typeEncoding];
    inputView.inputValue = self.currentValue;
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.delegate = self;
    self.fieldEditorView.argumentInputViews = @[inputView];

    // Don't show a "set" button for switches; we mutate when the switch is flipped
    if ([inputView isKindOfClass:[FLEXArgumentInputSwitchView class]]) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)actionButtonPressed:(id)sender {
    [super actionButtonPressed:sender];

    if (self.property) {
        id userInputObject = self.firstInputView.inputValue;
        NSArray *arguments = userInputObject ? @[userInputObject] : nil;
        SEL setterSelector = self.property.likelySetter;
        NSError *error = nil;
        [FLEXRuntimeUtility performSelector:setterSelector onObject:self.target withArguments:arguments error:&error];
        if (error) {
            [FLEXAlert showAlert:@"Property Setter Failed" message:error.localizedDescription from:self];
            sender = nil; // Don't pop back
        }
    } else {
        // TODO: check mutability and use mutableCopy if necessary;
        // this currently could and would assign NSArray to NSMutableArray

        [FLEXRuntimeUtility setValue:self.firstInputView.inputValue forIvar:self.ivar.objc_ivar onObject:self.target];
    }

    // Go back after setting, but not for switches.
    if (sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        self.firstInputView.inputValue = self.currentValue;
    }
}

- (void)getterButtonPressed:(id)sender {
    [self.fieldEditorView endEditing:YES];

    [self exploreObjectOrPopViewController:self.currentValue];
}

- (void)argumentInputViewValueDidChange:(FLEXArgumentInputView *)argumentInputView {
    if ([argumentInputView isKindOfClass:[FLEXArgumentInputSwitchView class]]) {
        [self actionButtonPressed:nil];
    }
}

#pragma mark - Private

- (id)currentValue {
    if (self.property) {
        return [FLEXRuntimeUtility valueForProperty:self.property.objc_property onObject:self.target];
    } else {
        return [FLEXRuntimeUtility valueForIvar:self.ivar.objc_ivar onObject:self.target];
    }
}

- (const FLEXTypeEncoding *)typeEncoding {
    if (self.property) {
        return self.property.attributes.typeEncoding.UTF8String;
    } else {
        return self.ivar.typeEncoding.UTF8String;
    }
}

- (NSString *)fieldDescription {
    if (self.property) {
        return [FLEXRuntimeUtility fullDescriptionForProperty:self.property.objc_property];
    } else {
        return [FLEXRuntimeUtility prettyNameForIvar:self.ivar.objc_ivar];
    }
}

+ (BOOL)canEditProperty:(FLEXProperty *)property onObject:(id)object currentValue:(id)value {
    const FLEXTypeEncoding *typeEncoding = property.attributes.typeEncoding.UTF8String;
    BOOL canEditType = [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:value];
    return canEditType && [object respondsToSelector:property.likelySetter];
}

+ (BOOL)canEditIvar:(Ivar)ivar currentValue:(id)value {
    return [FLEXArgumentInputViewFactory canEditFieldWithTypeEncoding:ivar_getTypeEncoding(ivar) currentValue:value];
}

@end
