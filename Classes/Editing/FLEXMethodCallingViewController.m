//
//  FLEXMethodCallingViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 5/23/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXMethodCallingViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXFieldEditorView.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXArgumentInputView.h"

@interface FLEXMethodCallingViewController ()

@property (nonatomic, assign) Method method;

@end

@implementation FLEXMethodCallingViewController

- (id)initWithTarget:(id)target method:(Method)method
{
    self = [super initWithTarget:target];
    if (self) {
        self.method = method;
        self.title = [self isClassMethod] ? @"Class Method" : @"Method";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = [FLEXRuntimeUtility prettyNameForMethod:self.method isClassMethod:[self isClassMethod]];
    
    NSArray *methodComponents = [FLEXRuntimeUtility prettyArgumentComponentsForMethod:self.method];
    NSMutableArray *argumentInputViews = [NSMutableArray array];
    unsigned int argumentIndex = kFLEXNumberOfImplicitArgs;
    for (NSString *methodComponent in methodComponents) {
        FLEXArgumentInputView *inputView = [[FLEXArgumentInputView alloc] init];
        inputView.backgroundColor = self.view.backgroundColor;
        inputView.title = methodComponent;
        
        // Prepopulate the structs that we parse from strings with the default values.
        // This shows the intended formatting which would be less clear otherwise.
        char *argumentTypeEncoding = method_copyArgumentType(self.method, argumentIndex);
        NSValue *defaultValue = [[self class] defaultValueForEncoding:argumentTypeEncoding];
        if (defaultValue) {
            inputView.inputText = [FLEXRuntimeUtility editiableDescriptionForObject:defaultValue];
        }
        free(argumentTypeEncoding);
        
        [argumentInputViews addObject:inputView];
        argumentIndex++;
    }
    self.fieldEditorView.argumentInputViews = argumentInputViews;
}

- (BOOL)isClassMethod
{
    return self.target && self.target == [self.target class];
}

- (NSString *)titleForActionButton
{
    return @"Call";
}

- (void)actionButtonPressed:(id)sender
{
    [super actionButtonPressed:sender];
    
    NSMutableArray *arguments = [NSMutableArray array];
    for (FLEXArgumentInputView *inputView in self.fieldEditorView.argumentInputViews) {
        NSString *argumentString = inputView.inputText;
        if (!argumentString) {
            // Use empty string as a placeholder in the array. It will be interpreted as nil.
            argumentString = @"";
        }
        [arguments addObject:argumentString];
    }
    
    id returnedObject = [FLEXRuntimeUtility performSelector:method_getName(self.method) onObject:self.target withArguments:arguments error:NULL];
    
    // For non-nil (or void) return types, push an explorer view controller to display the returned object
    if (returnedObject) {
        FLEXObjectExplorerViewController *explorerViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:returnedObject];
        [self.navigationController pushViewController:explorerViewController animated:YES];
    }
}

+ (NSValue *)defaultValueForEncoding:(const char *)typeEncoding
{
    NSValue *value = nil;
    
    if (strcmp(typeEncoding, @encode(CGRect)) == 0) {
        value = [NSValue valueWithCGRect:CGRectZero];
    } else if (strcmp(typeEncoding, @encode(CGSize)) == 0) {
        value = [NSValue valueWithCGPoint:CGPointZero];
    } else if (strcmp(typeEncoding, @encode(CGPoint)) == 0) {
        value = [NSValue valueWithCGSize:CGSizeZero];
    } else if (strcmp(typeEncoding, @encode(CGAffineTransform)) == 0) {
        value = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    } else if (strcmp(typeEncoding, @encode(NSRange)) == 0) {
        value = [NSValue valueWithRange:NSMakeRange(0, 0)];
    } else if (strcmp(typeEncoding, @encode(UIEdgeInsets)) == 0) {
        value = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
    } else if (strcmp(typeEncoding, @encode(UIOffset)) == 0) {
        value = [NSValue valueWithUIOffset:UIOffsetZero];
    }
    
    return value;
}

@end
