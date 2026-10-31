//
//  FLEXMacUtility.m
//  FLEX (macOS)
//

#import "FLEXMacUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXMacArgumentInputView.h"
#import <QuartzCore/QuartzCore.h>

static __weak NSWindow *_FLEXMacLastAppKeyWindow = nil;

@implementation FLEXMacUtility

#pragma mark Windows

+ (BOOL)isFLEXWindow:(NSWindow *)window {
    if (!window) {
        return NO;
    }
    if ([window conformsToProtocol:@protocol(FLEXMacInternalWindow)]) {
        return YES;
    }
    // Sheets and alerts presented from FLEX's windows also belong to FLEX
    NSWindow *parent = window.sheetParent ?: window.parentWindow;
    return parent ? [self isFLEXWindow:parent] : NO;
}

+ (NSArray<NSWindow *> *)appWindows {
    NSMutableArray<NSWindow *> *windows = [NSMutableArray new];
    for (NSWindow *window in NSApp.windows) {
        if (![self isFLEXWindow:window]) {
            [windows addObject:window];
        }
    }
    return windows;
}

+ (NSWindow *)appKeyWindow {
    NSWindow *key = NSApp.keyWindow;
    if (key && ![self isFLEXWindow:key]) {
        return key;
    }
    if (_FLEXMacLastAppKeyWindow) {
        return _FLEXMacLastAppKeyWindow;
    }

    NSWindow *main = NSApp.mainWindow;
    if (main && ![self isFLEXWindow:main]) {
        return main;
    }

    for (NSWindow *window in NSApp.orderedWindows) {
        if (window.isVisible && ![self isFLEXWindow:window]) {
            return window;
        }
    }

    return nil;
}

+ (void)startTrackingKeyWindow {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSWindow *key = NSApp.keyWindow;
        if (key && ![self isFLEXWindow:key]) {
            _FLEXMacLastAppKeyWindow = key;
        }

        [NSNotificationCenter.defaultCenter
            addObserverForName:NSWindowDidBecomeKeyNotification
            object:nil queue:nil usingBlock:^(NSNotification *note) {
                NSWindow *window = note.object;
                if (![self isFLEXWindow:window]) {
                    _FLEXMacLastAppKeyWindow = window;
                }
            }
        ];
    });
}

#pragma mark Views

+ (NSString *)descriptionForView:(NSView *)view includingFrame:(BOOL)includeFrame {
    NSMutableString *description = [NSMutableString new];
    [description appendString:NSStringFromClass(view.class)];

    NSString *identifier = view.identifier;
    if (identifier.length && ![identifier hasPrefix:@"_NS:"]) {
        [description appendFormat:@" \"%@\"", identifier];
    }

    if ([view isKindOfClass:[NSTextField class]]) {
        NSString *text = [(NSTextField *)view stringValue];
        if (text.length) {
            if (text.length > 30) {
                text = [[text substringToIndex:30] stringByAppendingString:@"…"];
            }
            [description appendFormat:@" '%@'", text];
        }
    } else if ([view isKindOfClass:[NSButton class]]) {
        NSString *title = [(NSButton *)view title];
        if (title.length) {
            [description appendFormat:@" '%@'", title];
        }
    }

    if (includeFrame) {
        [description appendFormat:@" %@", [self stringForRect:view.frame]];
    }

    if (view.isHidden) {
        [description appendString:@" (hidden)"];
    }

    return description;
}

+ (NSString *)stringForRect:(NSRect)rect {
    return [NSString stringWithFormat:@"{(%g, %g), (%g, %g)}",
        rect.origin.x, rect.origin.y, rect.size.width, rect.size.height
    ];
}

+ (NSRect)screenRectForView:(NSView *)view {
    NSWindow *window = view.window;
    if (!window) {
        return NSZeroRect;
    }
    NSRect inWindow = [view convertRect:view.bounds toView:nil];
    return [window convertRectToScreen:inWindow];
}

+ (NSViewController *)viewControllerForView:(NSView *)view {
    NSResponder *next = view.nextResponder;
    if ([next isKindOfClass:[NSViewController class]] && [(NSViewController *)next isViewLoaded] && [(NSViewController *)next view] == view) {
        return (id)next;
    }
    return nil;
}

+ (NSViewController *)viewControllerForAncestralView:(NSView *)view {
    while (view) {
        NSViewController *controller = [self viewControllerForView:view];
        if (controller) {
            return controller;
        }
        view = view.superview;
    }
    return nil;
}

+ (NSImage *)snapshotOfView:(NSView *)view {
    NSRect bounds = view.bounds;
    if (NSIsEmptyRect(bounds) || bounds.size.width > 10000 || bounds.size.height > 10000) {
        return nil;
    }

    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:bounds];
    if (!rep) {
        return nil;
    }
    [view cacheDisplayInRect:bounds toBitmapImageRep:rep];

    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    [image addRepresentation:rep];
    return image;
}

+ (NSImage *)snapshotOfLayer:(CALayer *)layer {
    CGSize size = layer.bounds.size;
    if (size.width < 1 || size.height < 1 || size.width > 10000 || size.height > 10000) {
        return nil;
    }

    return [NSImage imageWithSize:size flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
        CGContextRef context = NSGraphicsContext.currentContext.CGContext;
        [layer renderInContext:context];
        return YES;
    }];
}

+ (NSColor *)consistentRandomColorForObject:(id)object {
    CGFloat hue = (((NSUInteger)(__bridge void *)object >> 4) % 256) / 255.0;
    return [NSColor colorWithCalibratedHue:hue saturation:0.8 brightness:0.95 alpha:1.0];
}

+ (NSView *)rootViewForWindow:(NSWindow *)window {
    NSView *contentView = window.contentView;
    return contentView.superview ?: contentView;
}

+ (NSUInteger)subviewCountOfView:(NSView *)view {
    NSUInteger count = 0;
    for (NSView *subview in view.subviews) {
        count += 1 + [self subviewCountOfView:subview];
    }
    return count;
}

#pragma mark Images & Fonts

+ (NSImage *)symbol:(NSString *)name {
    return [self symbol:name description:nil];
}

+ (NSImage *)symbol:(NSString *)name description:(NSString *)description {
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:name accessibilityDescription:description];
    }
    return nil;
}

+ (NSFont *)monospacedFontOfSize:(CGFloat)size {
    if (@available(macOS 10.15, *)) {
        return [NSFont monospacedSystemFontOfSize:size weight:NSFontWeightRegular];
    }
    return [NSFont userFixedPitchFontOfSize:size];
}

+ (NSImage *)circleImageWithColor:(NSColor *)color diameter:(CGFloat)diameter {
    return [NSImage imageWithSize:NSMakeSize(diameter, diameter) flipped:NO drawingHandler:^BOOL(NSRect rect) {
        [color setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)] fill];
        [[NSColor.blackColor colorWithAlphaComponent:0.25] setStroke];
        [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 0.5, 0.5)] stroke];
        return YES;
    }];
}

#pragma mark Alerts & Input

/// The FLEX window to attach sheets to, if any. Prefer the explorer window so
/// alerts and prompts appear inside the tool rather than as separate windows.
+ (NSWindow *)sheetHostWindow {
    Class explorerWindowClass = NSClassFromString(@"FLEXMacExplorerWindow");
    Class toolbarClass = NSClassFromString(@"FLEXMacToolbarPanel");

    NSWindow *key = NSApp.keyWindow;
    if ([key isKindOfClass:explorerWindowClass] && key.isVisible && !key.attachedSheet) {
        return key;
    }

    for (NSWindow *window in NSApp.windows) {
        if ([window isKindOfClass:explorerWindowClass] && window.isVisible && !window.attachedSheet) {
            return window;
        }
    }

    // Last resort: the toolbar, so at least we attach to a FLEX window.
    if ([key isKindOfClass:toolbarClass] && key.isVisible && !key.attachedSheet) {
        return key;
    }
    return nil;
}

+ (void)presentAlert:(NSAlert *)alert completion:(void(^)(NSModalResponse response))completion {
    NSWindow *host = [self sheetHostWindow];
    if (host) {
        [alert beginSheetModalForWindow:host completionHandler:^(NSModalResponse response) {
            if (completion) completion(response);
        }];
    } else {
        NSModalResponse response = [alert runModal];
        if (completion) completion(response);
    }
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [NSAlert new];
    alert.messageText = title ?: @"";
    alert.informativeText = message ?: @"";
    [alert addButtonWithTitle:@"OK"];
    [self presentAlert:alert completion:nil];
}

+ (void)showError:(NSError *)error {
    [self showAlertWithTitle:@"Error" message:error.localizedDescription ?: error.description];
}

+ (void)promptWithTitle:(NSString *)title
                message:(NSString *)message
           defaultValue:(NSString *)defaultValue
             completion:(void (^)(NSString *))completion {
    NSAlert *alert = [NSAlert new];
    alert.messageText = title ?: @"";
    alert.informativeText = message ?: @"";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *field = [NSTextField textFieldWithString:defaultValue ?: @""];
    field.frame = NSMakeRect(0, 0, 320, 24);
    field.font = [self monospacedFontOfSize:12];
    alert.accessoryView = field;
    alert.window.initialFirstResponder = field;

    [self presentAlert:alert completion:^(NSModalResponse response) {
        completion(response == NSAlertFirstButtonReturn ? field.stringValue : nil);
    }];
}

+ (void)confirmWithTitle:(NSString *)title
                 message:(NSString *)message
             actionTitle:(NSString *)actionTitle
             destructive:(BOOL)destructive
              completion:(void (^)(void))completion {
    NSAlert *alert = [NSAlert new];
    alert.messageText = title ?: @"";
    alert.informativeText = message ?: @"";
    NSButton *action = [alert addButtonWithTitle:actionTitle];
    if (@available(macOS 11.0, *)) {
        action.hasDestructiveAction = destructive;
    }
    [alert addButtonWithTitle:@"Cancel"];

    [self presentAlert:alert completion:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            completion();
        }
    }];
}

#pragma mark Misc

+ (void)copyToPasteboard:(NSString *)string {
    if (!string) {
        return;
    }
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    [pasteboard clearContents];
    [pasteboard setString:string forType:NSPasteboardTypeString];
}

+ (NSString *)summaryForObject:(id)object maxLength:(NSUInteger)maxLength {
    return [self summaryForObject:object type:nil maxLength:maxLength];
}

+ (NSString *)summaryForObject:(id)object type:(NSString *)typeEncoding maxLength:(NSUInteger)maxLength {
    NSString *summary = nil;
    if ([object isKindOfClass:[NSNumber class]] && typeEncoding.length == 1) {
        // BOOL is 'B' on arm64 and 'c' on x86_64
        unichar type = [typeEncoding characterAtIndex:0];
        if (type == 'B' || (type == 'c' && ([object intValue] == 0 || [object intValue] == 1))) {
            summary = [object boolValue] ? @"YES" : @"NO";
        }
    }
    summary = summary ?: [FLEXMacArgumentInputView descriptionForStructValue:object];
    summary = summary ?: [FLEXRuntimeUtility summaryForObject:object] ?: @"nil";
    summary = [summary stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    if (summary.length > maxLength) {
        summary = [[summary substringToIndex:maxLength] stringByAppendingString:@"…"];
    }
    return summary;
}

+ (NSString *)stringForByteCount:(long long)bytes {
    return [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleBinary];
}

@end
