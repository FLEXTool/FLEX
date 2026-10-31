//
//  FLEXMacNavigationController.m
//  FLEX (macOS)
//

#import "FLEXMacNavigationController.h"
#import "FLEXMacUtility.h"
#import "FLEXMacExplorerWindowController.h"

NSButton *FLEXMacBarButton(NSString *symbolName, NSString *fallbackTitle, NSString *tooltip, id target, SEL action) {
    NSImage *image = [FLEXMacUtility symbol:symbolName description:tooltip];
    NSButton *button;
    if (image) {
        button = [NSButton buttonWithImage:image target:target action:action];
    } else {
        button = [NSButton buttonWithTitle:fallbackTitle target:target action:action];
    }
    button.bezelStyle = NSBezelStyleTexturedRounded;
    button.toolTip = tooltip;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

static void *FLEXMacNavigationTitleContext = &FLEXMacNavigationTitleContext;

@interface FLEXMacNavigationController ()
@property (nonatomic) NSMutableArray<NSViewController *> *stack;
@property (nonatomic) NSButton *backButton;
@property (nonatomic) NSTextField *titleLabel;
@property (nonatomic) NSStackView *accessoryStack;
@property (nonatomic) NSView *containerView;
@property (nonatomic, weak) NSViewController *observedController;
@end

@implementation FLEXMacNavigationController

- (instancetype)initWithRootViewController:(NSViewController *)root {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _stack = [NSMutableArray new];
        [self view];
        [self setRootViewController:root];
    }
    return self;
}

- (void)dealloc {
    [self stopObservingTitle];
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 720)];

    NSVisualEffectView *bar = [NSVisualEffectView new];
    bar.material = NSVisualEffectMaterialHeaderView;
    bar.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    bar.translatesAutoresizingMaskIntoConstraints = NO;

    self.backButton = FLEXMacBarButton(@"chevron.left", @"Back", @"Back (⌘[)", self, @selector(back:));
    self.backButton.keyEquivalent = @"[";
    self.backButton.keyEquivalentModifierMask = NSEventModifierFlagCommand;

    self.titleLabel = [NSTextField labelWithString:@""];
    self.titleLabel.font = [NSFont boldSystemFontOfSize:13];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.titleLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                              forOrientation:NSLayoutConstraintOrientationHorizontal];

    self.accessoryStack = [NSStackView stackViewWithViews:@[]];
    self.accessoryStack.spacing = 6;
    self.accessoryStack.translatesAutoresizingMaskIntoConstraints = NO;

    NSBox *separator = [NSBox new];
    separator.boxType = NSBoxSeparator;
    separator.translatesAutoresizingMaskIntoConstraints = NO;

    self.containerView = [NSView new];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    [bar addSubview:self.backButton];
    [bar addSubview:self.titleLabel];
    [bar addSubview:self.accessoryStack];
    [view addSubview:bar];
    [view addSubview:separator];
    [view addSubview:self.containerView];

    [NSLayoutConstraint activateConstraints:@[
        [bar.topAnchor constraintEqualToAnchor:view.topAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [bar.heightAnchor constraintEqualToConstant:38],

        [self.backButton.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:8],
        [self.backButton.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.backButton.trailingAnchor constant:8],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.accessoryStack.leadingAnchor constant:-8],

        [self.accessoryStack.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-8],
        [self.accessoryStack.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],

        [separator.topAnchor constraintEqualToAnchor:bar.bottomAnchor],
        [separator.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [separator.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

        [self.containerView.topAnchor constraintEqualToAnchor:separator.bottomAnchor],
        [self.containerView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];

    self.view = view;
}

#pragma mark Stack

- (NSArray<NSViewController *> *)viewControllers {
    return self.stack.copy;
}

- (NSViewController *)topViewController {
    return self.stack.lastObject;
}

- (void)pushViewController:(NSViewController *)viewController {
    if (!viewController) {
        return;
    }
    [self.stack addObject:viewController];
    [self addChildViewController:viewController];
    [self showTopViewController];
}

- (void)popViewController {
    if (self.stack.count <= 1) {
        return;
    }
    NSViewController *top = self.stack.lastObject;
    [self.stack removeLastObject];
    [top.view removeFromSuperview];
    [top removeFromParentViewController];
    [self showTopViewController];
}

- (void)popToRootViewController {
    while (self.stack.count > 1) {
        [self popViewController];
    }
}

- (void)setRootViewController:(NSViewController *)viewController {
    for (NSViewController *controller in self.stack) {
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
    }
    [self.stack removeAllObjects];
    [self pushViewController:viewController];
}

- (void)back:(id)sender {
    [self popViewController];
}

- (void)showTopViewController {
    NSViewController *top = self.topViewController;
    for (NSView *subview in self.containerView.subviews.copy) {
        [subview removeFromSuperview];
    }

    if (top) {
        NSView *view = top.view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:view];
        [NSLayoutConstraint activateConstraints:@[
            [view.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
            [view.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
            [view.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
            [view.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
        ]];
    }

    self.backButton.enabled = self.stack.count > 1;
    [self observeTitleOf:top];
    [self reloadNavigationItems];

    if (top.view.window) {
        NSView *firstResponder = top.view;
        if ([top respondsToSelector:@selector(flex_preferredFirstResponder)]) {
            firstResponder = [(id<FLEXMacNavigationItems>)top flex_preferredFirstResponder] ?: top.view;
        }
        [top.view.window makeFirstResponder:firstResponder];
    }
}

- (void)reloadNavigationItems {
    NSViewController *top = self.topViewController;
    for (NSView *view in self.accessoryStack.arrangedSubviews.copy) {
        [self.accessoryStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    if ([top respondsToSelector:@selector(flex_navigationAccessoryViews)]) {
        for (NSView *view in [(id<FLEXMacNavigationItems>)top flex_navigationAccessoryViews]) {
            [self.accessoryStack addArrangedSubview:view];
        }
    }
}

#pragma mark Title

- (void)observeTitleOf:(NSViewController *)controller {
    [self stopObservingTitle];
    self.observedController = controller;
    [controller addObserver:self forKeyPath:@"title" options:0 context:FLEXMacNavigationTitleContext];
    [self updateTitle];
}

- (void)stopObservingTitle {
    if (self.observedController) {
        [self.observedController removeObserver:self forKeyPath:@"title" context:FLEXMacNavigationTitleContext];
        self.observedController = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == FLEXMacNavigationTitleContext) {
        [self updateTitle];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateTitle {
    NSString *title = self.topViewController.title ?: @"";
    self.titleLabel.stringValue = title;
    self.titleLabel.toolTip = title;
    self.title = title;
    self.view.window.title = title.length ? [@"FLEX — " stringByAppendingString:title] : @"FLEX";
}

@end

@implementation NSViewController (FLEXMacNavigation)

- (FLEXMacNavigationController *)flex_navigationController {
    NSViewController *controller = self.parentViewController;
    while (controller) {
        if ([controller isKindOfClass:[FLEXMacNavigationController class]]) {
            return (id)controller;
        }
        controller = controller.parentViewController;
    }
    return nil;
}

- (void)flex_push:(NSViewController *)viewController {
    if (!viewController) {
        return;
    }

    FLEXMacNavigationController *nav = self.flex_navigationController;
    if (nav) {
        [nav pushViewController:viewController];
    } else {
        [FLEXMacExplorerWindowController.sharedController pushViewController:viewController];
    }
}

@end
