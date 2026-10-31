//
//  FLEXMacViewSelector.m
//  FLEX (macOS)
//

#import "FLEXMacViewSelector.h"
#import "FLEXMacHighlightWindow.h"
#import "FLEXMacUtility.h"

@interface FLEXMacViewSelector ()
@property (nonatomic, readwrite) BOOL isActive;
@property (nonatomic, copy) void (^handler)(NSView *);
@property (nonatomic) id eventMonitor;
@property (nonatomic) NSTimer *hoverTimer;
@property (nonatomic, weak) NSView *hoveredView;
@property (nonatomic) BOOL pushedCursor;
@end

@implementation FLEXMacViewSelector

+ (FLEXMacViewSelector *)sharedSelector {
    static FLEXMacViewSelector *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

+ (NSWindow *)appWindowAtScreenPoint:(NSPoint)point {
    NSInteger windowNumber = [NSWindow windowNumberAtPoint:point belowWindowWithWindowNumber:0];
    for (NSWindow *window in NSApp.orderedWindows) {
        if (!window.isVisible || window.isMiniaturized || [FLEXMacUtility isFLEXWindow:window]) {
            continue;
        }
        if (NSPointInRect(point, window.frame)) {
            // If another app's window covers this point, there is nothing to select
            if (windowNumber > 0 && windowNumber != window.windowNumber && ![NSApp windowWithWindowNumber:windowNumber]) {
                return nil;
            }
            return window;
        }
    }
    return nil;
}

+ (NSView *)viewAtScreenPoint:(NSPoint)point {
    NSWindow *window = [self appWindowAtScreenPoint:point];
    NSView *root = window ? [FLEXMacUtility rootViewForWindow:window] : nil;
    if (!root) {
        return nil;
    }

    NSPoint windowPoint = [window convertPointFromScreen:point];
    NSPoint rootPoint = root.superview ? [root.superview convertPoint:windowPoint fromView:nil] : windowPoint;
    return [root hitTest:rootPoint] ?: root;
}

- (void)beginWithHandler:(void (^)(NSView *))handler {
    if (self.isActive) {
        [self finishWithView:nil];
    }

    self.handler = handler;
    self.isActive = YES;

    __weak typeof(self) weakSelf = self;
    NSEventMask mask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged |
        NSEventMaskRightMouseDown | NSEventMaskRightMouseUp | NSEventMaskKeyDown | NSEventMaskMouseMoved;
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent *(NSEvent *event) {
        return [weakSelf handleEvent:event];
    }];

    self.hoverTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        [weakSelf updateHover];
    }];
    [NSRunLoop.mainRunLoop addTimer:self.hoverTimer forMode:NSRunLoopCommonModes];
    [self updateHover];
}

- (void)cancel {
    if (self.isActive) {
        [self finishWithView:nil];
    }
}

- (void)updateHover {
    NSView *view = [FLEXMacViewSelector viewAtScreenPoint:NSEvent.mouseLocation];
    if (view != self.hoveredView) {
        self.hoveredView = view;
        [FLEXMacHighlightWindow.selectionHighlight highlightView:view];
    }

    if (view && !self.pushedCursor) {
        [NSCursor.crosshairCursor push];
        self.pushedCursor = YES;
    } else if (!view && self.pushedCursor) {
        [NSCursor pop];
        self.pushedCursor = NO;
    }
    if (view) {
        [NSCursor.crosshairCursor set];
    }
}

- (NSEvent *)handleEvent:(NSEvent *)event {
    if (event.type == NSEventTypeKeyDown) {
        if (event.keyCode == 53) { // Escape
            [self finishWithView:nil];
            return nil;
        }
        return event;
    }

    // Leave events for FLEX's own windows alone, so the toolbar keeps working
    if ([FLEXMacUtility isFLEXWindow:event.window]) {
        return event;
    }

    if (event.type == NSEventTypeMouseMoved) {
        return event;
    }

    if (event.type == NSEventTypeLeftMouseDown) {
        NSPoint screenPoint = event.window ?
            [event.window convertPointToScreen:event.locationInWindow] : NSEvent.mouseLocation;
        NSView *view = [FLEXMacViewSelector viewAtScreenPoint:screenPoint];
        if (view) {
            [self finishWithView:view];
            return nil;
        }
        return event;
    }

    // Swallow the rest of the click while selecting, so the app doesn't react
    return self.hoveredView ? nil : event;
}

- (void)finishWithView:(NSView *)view {
    if (self.eventMonitor) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
    [self.hoverTimer invalidate];
    self.hoverTimer = nil;
    if (self.pushedCursor) {
        [NSCursor pop];
        self.pushedCursor = NO;
    }
    [NSCursor.arrowCursor set];

    self.isActive = NO;
    self.hoveredView = nil;
    // Always clear the live hover outline. On a successful pick, briefly flash
    // the chosen view to confirm it; on cancel, leave nothing on screen.
    [FLEXMacHighlightWindow.selectionHighlight highlightView:nil];
    if (view) {
        [FLEXMacHighlightWindow flashView:view];
    }

    void (^handler)(NSView *) = self.handler;
    self.handler = nil;
    if (handler) {
        handler(view);
    }
}

@end
