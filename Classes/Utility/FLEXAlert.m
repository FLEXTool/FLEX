//
//  FLEXAlert.m
//  FLEX
//
//  Created by Tanner Bennett on 8/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface FLEXAlert ()
@property (nonatomic, readonly) UIAlertController *_controller;
@property (nonatomic, readonly) NSMutableArray<FLEXAlertAction *> *_actions;
@end

#define FLEXAlertActionMutationAssertion() \
NSAssert(!self._action, @"Cannot mutate action after retreiving underlying UIAlertAction");

@interface FLEXAlertAction ()
@property (nonatomic) UIAlertController *_controller;
@property (nonatomic) NSString *_title;
@property (nonatomic) UIAlertActionStyle _style;
@property (nonatomic) BOOL _disable;
@property (nonatomic) void(^_handler)(UIAlertAction *action);
@property (nonatomic) UIAlertAction *_action;
@end

@implementation FLEXAlert

+ (void)showAlert:(NSString *)title message:(NSString *)message from:(UIViewController *)viewController {
    [self makeAlert:^(FLEXAlert *make) {
        make.title(title).message(message).button(@"Dismiss").cancelStyle();
    } showFrom:viewController];
}

+ (void)showQuickAlert:(NSString *)title from:(UIViewController *)viewController {
    UIAlertController *alert = [self makeAlert:^(FLEXAlert *make) {
        make.title(title);
    }];
    
    [viewController presentViewController:alert animated:YES completion:^{
        flex_dispatch_after(0.5, dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark Initialization

- (instancetype)initWithController:(UIAlertController *)controller {
    self = [super init];
    if (self) {
        __controller = controller;
        __actions = [NSMutableArray new];
    }

    return self;
}

+ (UIAlertController *)make:(FLEXAlertBuilder)block withStyle:(UIAlertControllerStyle)style {
    // Create alert builder
    FLEXAlert *alert = [[self alloc] initWithController:
        [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:style]
    ];

    // Configure alert
    block(alert);

    // Add actions
    for (FLEXAlertAction *builder in alert._actions) {
        [alert._controller addAction:builder.action];
    }

    return alert._controller;
}

+ (void)make:(FLEXAlertBuilder)block
   withStyle:(UIAlertControllerStyle)style
    showFrom:(UIViewController *)viewController
      source:(id)viewOrBarItem {
    UIAlertController *alert = [self make:block withStyle:style];
    if ([viewOrBarItem isKindOfClass:[UIBarButtonItem class]]) {
        alert.popoverPresentationController.barButtonItem = viewOrBarItem;
    } else if ([viewOrBarItem isKindOfClass:[UIView class]]) {
        alert.popoverPresentationController.sourceView = viewOrBarItem;
        alert.popoverPresentationController.sourceRect = [viewOrBarItem bounds];
    } else if (viewOrBarItem) {
        NSParameterAssert(
            [viewOrBarItem isKindOfClass:[UIBarButtonItem class]] ||
            [viewOrBarItem isKindOfClass:[UIView class]] ||
            !viewOrBarItem
        );
    }
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)makeAlert:(FLEXAlertBuilder)block showFrom:(UIViewController *)controller {
    [self make:block withStyle:UIAlertControllerStyleAlert showFrom:controller source:nil];
}

+ (void)makeSheet:(FLEXAlertBuilder)block showFrom:(UIViewController *)controller {
    [self make:block withStyle:UIAlertControllerStyleActionSheet showFrom:controller source:nil];
}

/// Construct and display an action sheet-style alert
+ (void)makeSheet:(FLEXAlertBuilder)block
         showFrom:(UIViewController *)controller
           source:(id)viewOrBarItem {
    [self make:block
     withStyle:UIAlertControllerStyleActionSheet
      showFrom:controller
        source:viewOrBarItem];
}

+ (UIAlertController *)makeAlert:(FLEXAlertBuilder)block {
    return [self make:block withStyle:UIAlertControllerStyleAlert];
}

+ (UIAlertController *)makeSheet:(FLEXAlertBuilder)block {
    return [self make:block withStyle:UIAlertControllerStyleActionSheet];
}

#pragma mark Configuration

- (FLEXAlertStringProperty)title {
    return ^FLEXAlert *(NSString *title) {
        if (self._controller.title) {
            self._controller.title = [self._controller.title stringByAppendingString:title ?: @""];
        } else {
            self._controller.title = title;
        }
        return self;
    };
}

- (FLEXAlertStringProperty)message {
    return ^FLEXAlert *(NSString *message) {
        if (self._controller.message) {
            self._controller.message = [self._controller.message stringByAppendingString:message ?: @""];
        } else {
            self._controller.message = message;
        }
        return self;
    };
}

- (FLEXAlertAddAction)button {
    return ^FLEXAlertAction *(NSString *title) {
        FLEXAlertAction *action = FLEXAlertAction.new.title(title);
        action._controller = self._controller;
        [self._actions addObject:action];
        return action;
    };
}

- (FLEXAlertStringArg)textField {
    return ^FLEXAlert *(NSString *placeholder) {
        [self._controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = placeholder;
        }];

        return self;
    };
}

- (FLEXAlertTextField)configuredTextField {
    return ^FLEXAlert *(void(^configurationHandler)(UITextField *)) {
        [self._controller addTextFieldWithConfigurationHandler:configurationHandler];
        return self;
    };
}

@end

@implementation FLEXAlertAction

- (FLEXAlertActionStringProperty)title {
    return ^FLEXAlertAction *(NSString *title) {
        FLEXAlertActionMutationAssertion();
        if (self._title) {
            self._title = [self._title stringByAppendingString:title ?: @""];
        } else {
            self._title = title;
        }
        return self;
    };
}

- (FLEXAlertActionProperty)destructiveStyle {
    return ^FLEXAlertAction *() {
        FLEXAlertActionMutationAssertion();
        self._style = UIAlertActionStyleDestructive;
        return self;
    };
}

- (FLEXAlertActionProperty)cancelStyle {
    return ^FLEXAlertAction *() {
        FLEXAlertActionMutationAssertion();
        self._style = UIAlertActionStyleCancel;
        return self;
    };
}

- (FLEXAlertActionBOOLProperty)enabled {
    return ^FLEXAlertAction *(BOOL enabled) {
        FLEXAlertActionMutationAssertion();
        self._disable = !enabled;
        return self;
    };
}

- (FLEXAlertActionHandler)handler {
    return ^FLEXAlertAction *(void(^handler)(NSArray<NSString *> *)) {
        FLEXAlertActionMutationAssertion();

        // Get weak reference to the alert to avoid block <--> alert retain cycle
        UIAlertController *controller = self._controller; weakify(controller)
        self._handler = ^(UIAlertAction *action) { strongify(controller)
            // Strongify that reference and pass the text field strings to the handler
            NSArray *strings = [controller.textFields valueForKeyPath:@"text"];
            handler(strings);
        };

        return self;
    };
}

- (UIAlertAction *)action {
    if (self._action) {
        return self._action;
    }

    self._action = [UIAlertAction
        actionWithTitle:self._title
        style:self._style
        handler:self._handler
    ];
    self._action.enabled = !self._disable;

    return self._action;
}

@end
