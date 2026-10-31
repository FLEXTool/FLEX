//
//  FLEXMacToolbarPanel.m
//  FLEX (macOS)
//

#import "FLEXMacToolbarPanel.h"

@interface FLEXMacToolbarButton : NSButton
@end

@implementation FLEXMacToolbarButton

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

@end

@interface FLEXMacToolbarPanel () <NSWindowDelegate>
@property (nonatomic) NSButton *selectButton;
@property (nonatomic) NSButton *detailsButton;
@property (nonatomic) NSTextField *selectionLabel;
@property (nonatomic) NSView *selectionColor;
@end

@implementation FLEXMacToolbarPanel

+ (instancetype)toolbar {
    FLEXMacToolbarPanel *panel = [[self alloc]
        initWithContentRect:NSMakeRect(0, 0, 360, 92)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                  NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskNonactivatingPanel
        backing:NSBackingStoreBuffered
        defer:YES
    ];
    return panel;
}

- (instancetype)initWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    self = [super initWithContentRect:rect styleMask:style backing:backing defer:defer];
    if (self) {
        self.title = @"FLEX";
        self.floatingPanel = YES;
        self.hidesOnDeactivate = NO;
        self.becomesKeyOnlyIfNeeded = YES;
        self.releasedWhenClosed = NO;
        self.level = NSFloatingWindowLevel;
        // Keep the toolbar usable while the host app runs a modal alert.
        self.worksWhenModal = YES;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorFullScreenAuxiliary;
        self.delegate = self;
        [self buildContent];

        if (![self setFrameUsingName:@"com.flex.toolbar"]) {
            NSRect visible = NSScreen.mainScreen.visibleFrame;
            NSRect frame = self.frame;
            frame.origin.x = NSMidX(visible) - frame.size.width / 2;
            frame.origin.y = NSMaxY(visible) - frame.size.height - 40;
            [self setFrame:frame display:NO];
        }
        self.frameAutosaveName = @"com.flex.toolbar";
    }
    return self;
}

- (NSButton *)buttonWithSymbol:(NSString *)symbol title:(NSString *)title tooltip:(NSString *)tooltip action:(SEL)action {
    FLEXMacToolbarButton *button = [FLEXMacToolbarButton buttonWithTitle:title target:self action:action];
    NSImage *image = [FLEXMacUtility symbol:symbol description:title];
    if (image) {
        button.image = image;
        button.imagePosition = NSImageAbove;
    }
    button.bordered = NO;
    button.font = [NSFont systemFontOfSize:10];
    button.toolTip = tooltip;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:56].active = YES;
    return button;
}

- (void)buildContent {
    NSVisualEffectView *content = [NSVisualEffectView new];
    content.material = NSVisualEffectMaterialHUDWindow;
    content.state = NSVisualEffectStateActive;

    NSButton *globals = [self buttonWithSymbol:@"square.grid.2x2" title:@"Menu"
        tooltip:@"Global state and tools" action:@selector(globals:)];
    NSButton *views = [self buttonWithSymbol:@"list.bullet.indent" title:@"Views"
        tooltip:@"View hierarchy of all windows" action:@selector(hierarchy:)];
    self.selectButton = [self buttonWithSymbol:@"cursorarrow.rays" title:@"Select"
        tooltip:@"Hover to highlight, click to select a view (Esc to cancel)" action:@selector(select:)];
    self.selectButton.buttonType = NSButtonTypePushOnPushOff;
    NSButton *network = [self buttonWithSymbol:@"network" title:@"Network"
        tooltip:@"Network history" action:@selector(network:)];
    NSButton *close = [self buttonWithSymbol:@"xmark.circle" title:@"Close"
        tooltip:@"Hide FLEX" action:@selector(closeToolbar:)];

    NSStackView *buttons = [NSStackView stackViewWithViews:@[globals, views, self.selectButton, network, close]];
    buttons.distribution = NSStackViewDistributionFillEqually;
    buttons.spacing = 4;
    buttons.translatesAutoresizingMaskIntoConstraints = NO;

    self.selectionColor = [NSView new];
    self.selectionColor.wantsLayer = YES;
    self.selectionColor.layer.cornerRadius = 4;
    self.selectionColor.translatesAutoresizingMaskIntoConstraints = NO;

    self.selectionLabel = [NSTextField labelWithString:@""];
    self.selectionLabel.font = [FLEXMacUtility monospacedFontOfSize:10.5];
    self.selectionLabel.textColor = NSColor.secondaryLabelColor;
    self.selectionLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.selectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectionLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                                  forOrientation:NSLayoutConstraintOrientationHorizontal];

    self.detailsButton = [NSButton buttonWithTitle:@"Details" target:self action:@selector(details:)];
    self.detailsButton.controlSize = NSControlSizeSmall;
    self.detailsButton.bezelStyle = NSBezelStyleRounded;
    self.detailsButton.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.detailsButton.translatesAutoresizingMaskIntoConstraints = NO;

    [content addSubview:buttons];
    [content addSubview:self.selectionColor];
    [content addSubview:self.selectionLabel];
    [content addSubview:self.detailsButton];

    [NSLayoutConstraint activateConstraints:@[
        [buttons.topAnchor constraintEqualToAnchor:content.topAnchor constant:6],
        [buttons.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:8],
        [buttons.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-8],

        [self.selectionColor.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:12],
        [self.selectionColor.centerYAnchor constraintEqualToAnchor:self.detailsButton.centerYAnchor],
        [self.selectionColor.widthAnchor constraintEqualToConstant:8],
        [self.selectionColor.heightAnchor constraintEqualToConstant:8],

        [self.selectionLabel.leadingAnchor constraintEqualToAnchor:self.selectionColor.trailingAnchor constant:6],
        [self.selectionLabel.centerYAnchor constraintEqualToAnchor:self.detailsButton.centerYAnchor],
        [self.selectionLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.detailsButton.leadingAnchor constant:-6],

        [self.detailsButton.topAnchor constraintEqualToAnchor:buttons.bottomAnchor constant:6],
        [self.detailsButton.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-10],
        [self.detailsButton.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-8],
    ]];

    self.contentView = content;
    [self updateSelection];
}

#pragma mark State

- (void)setSelectedView:(NSView *)selectedView {
    _selectedView = selectedView;
    [self updateSelection];
}

- (void)setSelecting:(BOOL)selecting {
    _selecting = selecting;
    self.selectButton.state = selecting ? NSControlStateValueOn : NSControlStateValueOff;
    self.selectButton.contentTintColor = selecting ? NSColor.controlAccentColor : nil;
    [self updateSelection];
}

- (void)updateSelection {
    NSView *view = self.selectedView;
    if (self.selecting) {
        self.selectionLabel.stringValue = @"Click a view to select it, Esc to cancel";
        self.selectionColor.layer.backgroundColor = NSColor.controlAccentColor.CGColor;
    } else if (view) {
        self.selectionLabel.stringValue = [FLEXMacUtility descriptionForView:view includingFrame:YES];
        self.selectionColor.layer.backgroundColor = [FLEXMacUtility consistentRandomColorForObject:view].CGColor;
    } else {
        self.selectionLabel.stringValue = @"No view selected";
        self.selectionColor.layer.backgroundColor = NSColor.clearColor.CGColor;
    }
    self.selectionLabel.toolTip = self.selectionLabel.stringValue;
    self.detailsButton.enabled = view != nil && !self.selecting;
}

#pragma mark Actions

- (void)globals:(id)sender { [self.toolbarDelegate toolbarDidSelectGlobals:self]; }
- (void)hierarchy:(id)sender { [self.toolbarDelegate toolbarDidSelectHierarchy:self]; }
- (void)select:(id)sender { [self.toolbarDelegate toolbarDidSelectSelect:self]; }
- (void)network:(id)sender { [self.toolbarDelegate toolbarDidSelectNetwork:self]; }
- (void)details:(id)sender { [self.toolbarDelegate toolbarDidSelectDetails:self]; }
- (void)closeToolbar:(id)sender { [self.toolbarDelegate toolbarDidSelectClose:self]; }

- (BOOL)windowShouldClose:(NSWindow *)sender {
    [self.toolbarDelegate toolbarDidSelectClose:self];
    return NO;
}

@end
