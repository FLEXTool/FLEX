//
//  main.m  — SampleAppKitDump
//
//  A self-hosting AppKit sample: builds a representative window (sidebar
//  NSVisualEffectView, known fonts, a layer-backed accent row, Auto Layout
//  constraints) and prints its OWN runtime view tree as JSON, produced by the real
//  FLEXAppKitWalker. No injection, no SIP changes — run with:
//      swift run SampleAppKitDump
//  Eyeball the JSON against the constructed window to verify the AppKit surface.
//

#import <AppKit/AppKit.h>
#import <stdio.h>
@import FLEXAppKit;

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];

        NSWindow *window =
            [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 640, 420)
                                        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskResizable)
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
        window.title = @"Gourmand — Inbox";
        NSView *content = window.contentView;

        // Sidebar: a vibrancy material, the classic source-list look.
        NSVisualEffectView *sidebar = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 200, 420)];
        sidebar.material = NSVisualEffectMaterialSidebar;
        sidebar.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        sidebar.identifier = @"Sidebar";
        [content addSubview:sidebar];

        // A layer-backed selection row: 6pt corner radius, accent fill.
        NSView *selectionRow = [[NSView alloc] initWithFrame:NSMakeRect(8, 350, 184, 28)];
        selectionRow.wantsLayer = YES;
        selectionRow.layer.cornerRadius = 6;
        if (@available(macOS 10.14, *)) {
            selectionRow.layer.backgroundColor = NSColor.controlAccentColor.CGColor;
        } else {
            selectionRow.layer.backgroundColor = NSColor.systemBlueColor.CGColor;
        }
        selectionRow.identifier = @"SelectionRow";
        [sidebar addSubview:selectionRow];

        // A label with a known font.
        NSTextField *rowLabel = [NSTextField labelWithString:@"Inbox"];
        rowLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
        rowLabel.frame = NSMakeRect(16, 354, 160, 18);
        rowLabel.identifier = @"InboxLabel";
        [sidebar addSubview:rowLabel];

        // Detail pane with a constrained title.
        NSView *detail = [[NSView alloc] initWithFrame:NSMakeRect(200, 0, 440, 420)];
        detail.identifier = @"Detail";
        [content addSubview:detail];

        NSTextField *title = [NSTextField labelWithString:@"Welcome"];
        title.font = [NSFont systemFontOfSize:22 weight:NSFontWeightBold];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        title.identifier = @"Title";
        [detail addSubview:title];
        [detail addConstraint:[NSLayoutConstraint constraintWithItem:title
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:detail
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:24]];
        [detail addConstraint:[NSLayoutConstraint constraintWithItem:title
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:detail
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:24]];

        [window orderFront:nil];

        // Walk + project to JSON via the real walker.
        NSArray *windows = [FLEXAppKitWalker snapshotApplicationWindows];
        NSDictionary *out = @{
            @"windows": [FLEXAppKitJSON dictionariesForWindows:windows],
            @"constraintsForTitle": [FLEXAppKitJSON dictionaryForConstraintNode:
                                         [FLEXConstraintNode constraintsForView:title]],
        };

        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:out
                                                      options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys
                                                        error:&error];
        if (json == nil) {
            fprintf(stderr, "JSON error: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }
        fwrite(json.bytes, 1, json.length, stdout);
        printf("\n");
        return 0;
    }
}
