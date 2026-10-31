//
//  FLEXMacHighlightWindow.m
//  FLEX (macOS)
//

#import "FLEXMacHighlightWindow.h"

static const CGFloat kFLEXMacHighlightLabelHeight = 18;

@interface FLEXMacHighlightContentView : NSView
@property (nonatomic, copy) NSString *label;
@property (nonatomic) NSColor *color;
@end

@implementation FLEXMacHighlightContentView

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    NSRect target = NSMakeRect(0, kFLEXMacHighlightLabelHeight, bounds.size.width, bounds.size.height - kFLEXMacHighlightLabelHeight);

    [[self.color colorWithAlphaComponent:0.18] setFill];
    NSRectFillUsingOperation(target, NSCompositingOperationSourceOver);

    NSBezierPath *border = [NSBezierPath bezierPathWithRect:NSInsetRect(target, 1, 1)];
    border.lineWidth = 2;
    [self.color setStroke];
    [border stroke];

    if (self.label.length) {
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightSemibold],
            NSForegroundColorAttributeName: NSColor.whiteColor,
        };
        NSSize textSize = [self.label sizeWithAttributes:attributes];
        NSRect pill = NSMakeRect(0, 0, MIN(textSize.width + 10, bounds.size.width), kFLEXMacHighlightLabelHeight - 2);
        [[self.color blendedColorWithFraction:0.35 ofColor:NSColor.blackColor] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:pill xRadius:4 yRadius:4] fill];

        NSRect textRect = NSMakeRect(5, (pill.size.height - textSize.height) / 2, pill.size.width - 10, textSize.height);
        [self.label drawWithRect:textRect
                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                      attributes:attributes context:nil];
    }
}

@end

@interface FLEXMacHighlightWindow ()
@property (nonatomic, readwrite, weak) NSView *highlightedView;
@property (nonatomic) FLEXMacHighlightContentView *highlightContent;
@property (nonatomic, weak) NSWindow *observedWindow;
@end

@implementation FLEXMacHighlightWindow

+ (FLEXMacHighlightWindow *)selectionHighlight {
    static FLEXMacHighlightWindow *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

+ (void)flashView:(NSView *)view {
    if (!view.window) {
        NSBeep();
        return;
    }

    FLEXMacHighlightWindow *flash = [self new];
    flash.highlightContent.color = NSColor.systemOrangeColor;
    [flash highlightView:view];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            flash.animator.alphaValue = 0;
        } completionHandler:^{
            [flash highlightView:nil];
        }];
    });
}

- (instancetype)init {
    self = [super initWithContentRect:NSMakeRect(0, 0, 10, 10)
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered
                                defer:YES];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = NSColor.clearColor;
        self.hasShadow = NO;
        self.ignoresMouseEvents = YES;
        self.releasedWhenClosed = NO;
        self.level = NSStatusWindowLevel;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorTransient |
            NSWindowCollectionBehaviorIgnoresCycle;

        self.highlightContent = [FLEXMacHighlightContentView new];
        self.highlightContent.color = NSColor.systemBlueColor;
        self.contentView = self.highlightContent;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)highlightView:(NSView *)view {
    self.highlightedView = view;
    [self observeWindow:view.window];

    if (!view || !view.window.isVisible) {
        [self orderOut:nil];
        return;
    }

    NSRect rect = [FLEXMacUtility screenRectForView:view];
    // Keep zero-size views visible
    rect.size.width = MAX(rect.size.width, 2);
    rect.size.height = MAX(rect.size.height, 2);
    // Room for the label above the view
    rect.size.height += kFLEXMacHighlightLabelHeight;

    self.highlightContent.label = [NSString stringWithFormat:@"%@  %g × %g",
        NSStringFromClass(view.class), view.frame.size.width, view.frame.size.height
    ];
    self.alphaValue = 1;
    [self setFrame:rect display:YES];
    [self.highlightContent setNeedsDisplay:YES];
    [self orderFrontRegardless];
}

- (void)observeWindow:(NSWindow *)window {
    if (window == self.observedWindow) {
        return;
    }

    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    if (self.observedWindow) {
        [center removeObserver:self name:nil object:self.observedWindow];
    }
    self.observedWindow = window;
    if (window) {
        for (NSNotificationName name in @[
            NSWindowDidMoveNotification, NSWindowDidResizeNotification,
            NSWindowDidMiniaturizeNotification, NSWindowDidDeminiaturizeNotification,
            NSWindowWillCloseNotification,
        ]) {
            [center addObserver:self selector:@selector(observedWindowChanged:) name:name object:window];
        }
    }
}

- (void)observedWindowChanged:(NSNotification *)note {
    if ([note.name isEqualToString:NSWindowWillCloseNotification] ||
        [note.name isEqualToString:NSWindowDidMiniaturizeNotification]) {
        [self orderOut:nil];
        return;
    }
    if (self.isVisible || [note.name isEqualToString:NSWindowDidDeminiaturizeNotification]) {
        [self highlightView:self.highlightedView];
    }
}

@end
