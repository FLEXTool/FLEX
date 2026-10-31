//
//  FLEXMacShortcuts.m
//  FLEX (macOS)
//

#import "FLEXMacShortcuts.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacObjectListViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacHighlightWindow.h"
#import "FLEXMacViewHierarchyViewController.h"
#import "FLEXMacFileBrowserViewController.h"
#import "FLEXMacUtility.h"
#import "FLEXRuntimeUtility.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

/// Maximum number of collection elements listed
static const NSUInteger kFLEXMacMaxElements = 5000;

#define FLEXMacSummary(obj) [FLEXMacUtility summaryForObject:(obj) maxLength:300]

static FLEXMacRow *FLEXMacExploreRow(NSString *title, id value) {
    return [FLEXMacRow title:title subtitle:FLEXMacSummary(value) exploring:value];
}

static FLEXMacRow *FLEXMacInfoRow(NSString *title, NSString *value) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:value ?: @"nil"];
    row.copyString = value;
    return row;
}

static FLEXMacRow *FLEXMacListRow(NSString *title, NSArray *objects) {
    NSString *subtitle = [NSString stringWithFormat:@"%lu %@", (unsigned long)objects.count,
        objects.count == 1 ? @"object" : @"objects"];
    return [FLEXMacRow title:title subtitle:subtitle pushing:^NSViewController *{
        return [FLEXMacObjectListViewController listWithTitle:title objects:objects ?: @[]];
    }];
}

static FLEXMacRow *FLEXMacActionRow(NSString *title, NSString *subtitle, void (^action)(NSViewController *host)) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:subtitle];
    row.action = action;
    row.titleColor = NSColor.linkColor;
    return row;
}

static FLEXMacRow *FLEXMacImageRow(NSString *title, NSImage *image) {
    if (!image) {
        return [FLEXMacRow title:title subtitle:@"Unavailable"];
    }
    FLEXMacRow *row = [FLEXMacRow
        title:title
        subtitle:[NSString stringWithFormat:@"%g × %g", image.size.width, image.size.height]
        pushing:^NSViewController *{
            return [FLEXMacImagePreviewViewController previewForImage:image title:nil];
        }
    ];

    // Small thumbnail
    NSSize size = image.size;
    CGFloat scale = MIN(1, 32.0 / MAX(MAX(size.width, size.height), 1));
    NSImage *thumbnail = [image copy];
    thumbnail.size = NSMakeSize(MAX(size.width * scale, 1), MAX(size.height * scale, 1));
    row.image = thumbnail;
    return row;
}

static FLEXMacRow *FLEXMacTextRow(NSString *title, NSString *text) {
    FLEXMacRow *row = [FLEXMacRow title:title subtitle:text pushing:^NSViewController *{
        return [FLEXMacTextViewController viewerWithText:text title:title];
    }];
    row.copyString = text;
    row.subtitleMaxLines = 6;
    return row;
}

@implementation FLEXMacShortcuts

+ (NSArray<FLEXMacSection *> *)sectionsForObject:(id)object {
    if (!object || object_isClass(object)) {
        return @[];
    }

    NSMutableArray<FLEXMacSection *> *sections = [NSMutableArray new];
    NSMutableArray<FLEXMacRow *> *shortcuts = [NSMutableArray new];

    @try {
        [self addShortcutsForObject:object to:shortcuts sections:sections];
    } @catch (NSException *exception) {
        [shortcuts addObject:[FLEXMacRow title:@"Exception thrown building shortcuts" subtitle:exception.reason]];
    }

    if (shortcuts.count) {
        [sections insertObject:[FLEXMacSection title:@"Shortcuts" rows:shortcuts] atIndex:0];
    }
    return sections;
}

+ (void)addShortcutsForObject:(id)object to:(NSMutableArray<FLEXMacRow *> *)rows sections:(NSMutableArray<FLEXMacSection *> *)sections {
    // AppKit
    if ([object isKindOfClass:[NSView class]]) {
        [self addViewShortcuts:object to:rows];
    } else if ([object isKindOfClass:[NSWindow class]]) {
        [self addWindowShortcuts:object to:rows];
    } else if ([object isKindOfClass:[NSViewController class]]) {
        [self addViewControllerShortcuts:object to:rows];
    } else if ([object isKindOfClass:[NSWindowController class]]) {
        NSWindowController *controller = object;
        [rows addObject:FLEXMacExploreRow(@"window", controller.window)];
        [rows addObject:FLEXMacExploreRow(@"contentViewController", controller.contentViewController)];
        [rows addObject:FLEXMacExploreRow(@"document", controller.document)];
        [rows addObject:FLEXMacExploreRow(@"owner", controller.owner)];
    } else if ([object isKindOfClass:[NSApplication class]]) {
        [self addApplicationShortcuts:object to:rows];
    } else if ([object isKindOfClass:[NSMenu class]]) {
        [self addMenuShortcuts:object to:rows sections:sections];
    } else if ([object isKindOfClass:[NSMenuItem class]]) {
        NSMenuItem *item = object;
        [rows addObject:FLEXMacInfoRow(@"title", item.title)];
        [rows addObject:FLEXMacExploreRow(@"target", item.target)];
        [rows addObject:FLEXMacInfoRow(@"action", item.action ? NSStringFromSelector(item.action) : nil)];
        [rows addObject:FLEXMacInfoRow(@"keyEquivalent", [self keyEquivalentStringForItem:item])];
        [rows addObject:FLEXMacExploreRow(@"submenu", item.submenu)];
        [rows addObject:FLEXMacExploreRow(@"menu", item.menu)];
        [rows addObject:FLEXMacExploreRow(@"representedObject", item.representedObject)];
        if (item.target && item.action) {
            [rows addObject:FLEXMacActionRow(@"Perform Action", @"Sends the item's action to its target", ^(NSViewController *host) {
                [NSApp sendAction:item.action to:item.target from:item];
            })];
        }
    } else if ([object isKindOfClass:[NSImage class]]) {
        NSImage *image = object;
        [rows addObject:FLEXMacImageRow(@"Preview", image)];
        [rows addObject:FLEXMacInfoRow(@"name", image.name)];
        [rows addObject:FLEXMacListRow(@"representations", image.representations)];
    } else if ([object isKindOfClass:[NSColor class]]) {
        NSColor *color = object;
        FLEXMacRow *swatch = [FLEXMacRow title:@"Color" subtitle:color.description];
        swatch.image = [FLEXMacUtility circleImageWithColor:color diameter:24];
        [rows addObject:swatch];
        NSColor *rgb = [color colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
        if (rgb) {
            NSString *hex = [NSString stringWithFormat:@"#%02X%02X%02X",
                (int)round(rgb.redComponent * 255), (int)round(rgb.greenComponent * 255), (int)round(rgb.blueComponent * 255)
            ];
            [rows addObject:FLEXMacInfoRow(@"sRGB", [NSString stringWithFormat:@"%@  alpha %.2f", hex, rgb.alphaComponent])];
        }
    } else if ([object isKindOfClass:[NSScreen class]]) {
        NSScreen *screen = object;
        [rows addObject:FLEXMacInfoRow(@"localizedName", screen.localizedName)];
        [rows addObject:FLEXMacInfoRow(@"frame", [FLEXMacUtility stringForRect:screen.frame])];
        [rows addObject:FLEXMacInfoRow(@"visibleFrame", [FLEXMacUtility stringForRect:screen.visibleFrame])];
        [rows addObject:FLEXMacInfoRow(@"backingScaleFactor", @(screen.backingScaleFactor).stringValue)];
    } else if ([object isKindOfClass:[NSPasteboard class]]) {
        NSPasteboard *pasteboard = object;
        [rows addObject:FLEXMacInfoRow(@"types", [pasteboard.types componentsJoinedByString:@", "])];
        NSString *string = [pasteboard stringForType:NSPasteboardTypeString];
        if (string) {
            [rows addObject:FLEXMacTextRow(@"String Contents", string)];
        }
        [rows addObject:FLEXMacListRow(@"pasteboardItems", pasteboard.pasteboardItems)];
    }

    // Core Animation
    if ([object isKindOfClass:[CALayer class]]) {
        CALayer *layer = object;
        [rows addObject:FLEXMacImageRow(@"Preview", [FLEXMacUtility snapshotOfLayer:layer])];
        [rows addObject:FLEXMacExploreRow(@"superlayer", layer.superlayer)];
        [rows addObject:FLEXMacListRow(@"sublayers", layer.sublayers ?: @[])];
        [rows addObject:FLEXMacExploreRow(@"delegate", layer.delegate)];
        [rows addObject:FLEXMacInfoRow(@"frame", [FLEXMacUtility stringForRect:layer.frame])];
        [rows addObject:FLEXMacInfoRow(@"animationKeys", [layer.animationKeys componentsJoinedByString:@", "] ?: @"none")];
    }

    // Foundation
    if ([object isKindOfClass:[NSUserDefaults class]]) {
        [self addDefaultsShortcuts:object to:rows sections:sections];
    } else if ([object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSMapTable class]]) {
        [sections addObject:[self entriesSectionForDictionary:object]];
    } else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSOrderedSet class]] ||
               [object isKindOfClass:[NSSet class]] || [object isKindOfClass:[NSHashTable class]] ||
               [object isKindOfClass:[NSPointerArray class]]) {
        [sections addObject:[self elementsSectionForCollection:object]];
    } else if ([object isKindOfClass:[NSString class]]) {
        NSString *string = object;
        [rows addObject:FLEXMacTextRow(@"Text", string)];
        [rows addObject:FLEXMacInfoRow(@"length", @(string.length).stringValue)];
    } else if ([object isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *string = object;
        [rows addObject:FLEXMacTextRow(@"string", string.string)];
        [rows addObject:FLEXMacInfoRow(@"length", @(string.length).stringValue)];
    } else if ([object isKindOfClass:[NSData class]]) {
        [self addDataShortcuts:object to:rows];
    } else if ([object isKindOfClass:[NSURL class]]) {
        NSURL *url = object;
        [rows addObject:FLEXMacInfoRow(@"absoluteString", url.absoluteString)];
        if (url.isFileURL) {
            [rows addObject:FLEXMacInfoRow(@"path", url.path)];
            [rows addObject:FLEXMacActionRow(@"Reveal in Finder", nil, ^(NSViewController *host) {
                [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[url]];
            })];
            [rows addObject:[FLEXMacRow title:@"Browse" subtitle:url.path pushing:^NSViewController *{
                return [FLEXMacFileBrowserViewController browserForPath:url.path];
            }]];
        }
    } else if ([object isKindOfClass:[NSBundle class]]) {
        NSBundle *bundle = object;
        [rows addObject:FLEXMacInfoRow(@"bundleIdentifier", bundle.bundleIdentifier)];
        [rows addObject:FLEXMacInfoRow(@"bundlePath", bundle.bundlePath)];
        [rows addObject:FLEXMacInfoRow(@"executablePath", bundle.executablePath)];
        [rows addObject:FLEXMacExploreRow(@"infoDictionary", bundle.infoDictionary)];
        [rows addObject:[FLEXMacRow title:@"Browse Bundle" subtitle:bundle.bundlePath pushing:^NSViewController *{
            return [FLEXMacFileBrowserViewController browserForPath:bundle.bundlePath];
        }]];
    } else if ([object isKindOfClass:[NSProcessInfo class]]) {
        NSProcessInfo *info = object;
        [rows addObject:FLEXMacInfoRow(@"processName", info.processName)];
        [rows addObject:FLEXMacInfoRow(@"processIdentifier", @(info.processIdentifier).stringValue)];
        [rows addObject:FLEXMacInfoRow(@"operatingSystemVersion", info.operatingSystemVersionString)];
        [rows addObject:FLEXMacExploreRow(@"arguments", info.arguments)];
        [rows addObject:FLEXMacExploreRow(@"environment", info.environment)];
    } else if ([object isKindOfClass:[NSHTTPCookie class]]) {
        NSHTTPCookie *cookie = object;
        [rows addObject:FLEXMacInfoRow(@"name", cookie.name)];
        [rows addObject:FLEXMacInfoRow(@"value", cookie.value)];
        [rows addObject:FLEXMacInfoRow(@"domain", cookie.domain)];
        [rows addObject:FLEXMacInfoRow(@"path", cookie.path)];
        [rows addObject:FLEXMacInfoRow(@"expiresDate", cookie.expiresDate.description)];
    }
}

#pragma mark AppKit

+ (void)addViewShortcuts:(NSView *)view to:(NSMutableArray<FLEXMacRow *> *)rows {
    [rows addObject:FLEXMacImageRow(@"Preview", [FLEXMacUtility snapshotOfView:view])];
    [rows addObject:FLEXMacActionRow(@"Highlight on Screen", @"Briefly outlines this view", ^(NSViewController *host) {
        [FLEXMacHighlightWindow flashView:view];
    })];
    [rows addObject:[FLEXMacRow title:@"Show in View Hierarchy" subtitle:nil pushing:^NSViewController *{
        return [FLEXMacViewHierarchyViewController hierarchyFocusingOnView:view];
    }]];

    NSViewController *controller = [FLEXMacUtility viewControllerForAncestralView:view];
    if (controller) {
        [rows addObject:FLEXMacExploreRow(@"View Controller", controller)];
    }
    [rows addObject:FLEXMacExploreRow(@"window", view.window)];
    [rows addObject:FLEXMacExploreRow(@"superview", view.superview)];
    [rows addObject:FLEXMacListRow(@"subviews", view.subviews)];
    [rows addObject:FLEXMacInfoRow(@"frame", [FLEXMacUtility stringForRect:view.frame])];
    [rows addObject:FLEXMacInfoRow(@"bounds", [FLEXMacUtility stringForRect:view.bounds])];
    [rows addObject:FLEXMacInfoRow(@"Frame in Window", [FLEXMacUtility stringForRect:[view convertRect:view.bounds toView:nil]])];
    [rows addObject:FLEXMacExploreRow(@"layer", view.layer)];
    [rows addObject:FLEXMacListRow(@"constraints", view.constraints)];
    [rows addObject:FLEXMacListRow(@"Responder Chain", [self responderChainFrom:view])];

    if ([view isKindOfClass:[NSControl class]]) {
        NSControl *control = (id)view;
        [rows addObject:FLEXMacInfoRow(@"stringValue", control.stringValue)];
        [rows addObject:FLEXMacExploreRow(@"target", control.target)];
        [rows addObject:FLEXMacInfoRow(@"action", control.action ? NSStringFromSelector(control.action) : nil)];
        if (control.action) {
            [rows addObject:FLEXMacActionRow(@"Perform Action", @"Sends the control's action", ^(NSViewController *host) {
                [control sendAction:control.action to:control.target];
            })];
        }
    }
    if ([view isKindOfClass:[NSTableView class]]) {
        NSTableView *table = (id)view;
        [rows addObject:FLEXMacExploreRow(@"dataSource", table.dataSource)];
        [rows addObject:FLEXMacExploreRow(@"delegate", table.delegate)];
        [rows addObject:FLEXMacListRow(@"tableColumns", table.tableColumns)];
    }
    if ([view isKindOfClass:[NSScrollView class]]) {
        NSScrollView *scrollView = (id)view;
        [rows addObject:FLEXMacExploreRow(@"documentView", scrollView.documentView)];
        [rows addObject:FLEXMacExploreRow(@"contentView", scrollView.contentView)];
    }
    if ([view isKindOfClass:[NSStackView class]]) {
        [rows addObject:FLEXMacListRow(@"arrangedSubviews", [(NSStackView *)view arrangedSubviews])];
    }
    if ([view isKindOfClass:[NSImageView class]]) {
        [rows addObject:FLEXMacImageRow(@"image", [(NSImageView *)view image])];
    }
}

+ (void)addWindowShortcuts:(NSWindow *)window to:(NSMutableArray<FLEXMacRow *> *)rows {
    NSView *root = [FLEXMacUtility rootViewForWindow:window];
    if (root) {
        [rows addObject:FLEXMacImageRow(@"Preview", [FLEXMacUtility snapshotOfView:root])];
    }
    [rows addObject:FLEXMacActionRow(@"Highlight on Screen", @"Briefly outlines this window", ^(NSViewController *host) {
        [FLEXMacHighlightWindow flashView:root];
    })];
    [rows addObject:[FLEXMacRow title:@"View Hierarchy" subtitle:nil pushing:^NSViewController *{
        return [FLEXMacViewHierarchyViewController hierarchyFocusingOnView:window.contentView];
    }]];
    if (!window.isVisible) {
        [rows addObject:FLEXMacActionRow(@"Show Window", @"makeKeyAndOrderFront:", ^(NSViewController *host) {
            [window makeKeyAndOrderFront:nil];
        })];
    }
    [rows addObject:FLEXMacInfoRow(@"title", window.title)];
    [rows addObject:FLEXMacInfoRow(@"frame", [FLEXMacUtility stringForRect:window.frame])];
    [rows addObject:FLEXMacExploreRow(@"contentView", window.contentView)];
    [rows addObject:FLEXMacExploreRow(@"contentViewController", window.contentViewController)];
    [rows addObject:FLEXMacExploreRow(@"windowController", window.windowController)];
    [rows addObject:FLEXMacExploreRow(@"delegate", window.delegate)];
    [rows addObject:FLEXMacExploreRow(@"firstResponder", window.firstResponder)];
    [rows addObject:FLEXMacExploreRow(@"toolbar", window.toolbar)];
    [rows addObject:FLEXMacExploreRow(@"screen", window.screen)];
    [rows addObject:FLEXMacExploreRow(@"parentWindow", window.parentWindow)];
    [rows addObject:FLEXMacListRow(@"childWindows", window.childWindows ?: @[])];
    [rows addObject:FLEXMacListRow(@"sheets", window.sheets)];
    [rows addObject:FLEXMacInfoRow(@"State", [NSString stringWithFormat:@"visible: %@, key: %@, main: %@, level: %ld",
        window.isVisible ? @"YES" : @"NO", window.isKeyWindow ? @"YES" : @"NO",
        window.isMainWindow ? @"YES" : @"NO", (long)window.level
    ])];
}

+ (void)addViewControllerShortcuts:(NSViewController *)controller to:(NSMutableArray<FLEXMacRow *> *)rows {
    NSView *view = controller.isViewLoaded ? controller.view : nil;
    if (view) {
        [rows addObject:FLEXMacImageRow(@"Preview", [FLEXMacUtility snapshotOfView:view])];
    }
    [rows addObject:FLEXMacExploreRow(@"view", view)];
    [rows addObject:FLEXMacInfoRow(@"title", controller.title)];
    [rows addObject:FLEXMacExploreRow(@"representedObject", controller.representedObject)];
    [rows addObject:FLEXMacExploreRow(@"parentViewController", controller.parentViewController)];
    [rows addObject:FLEXMacListRow(@"childViewControllers", controller.childViewControllers)];
    [rows addObject:FLEXMacListRow(@"presentedViewControllers", controller.presentedViewControllers ?: @[])];
    [rows addObject:FLEXMacExploreRow(@"presentingViewController", controller.presentingViewController)];
}

+ (void)addApplicationShortcuts:(NSApplication *)app to:(NSMutableArray<FLEXMacRow *> *)rows {
    [rows addObject:FLEXMacExploreRow(@"delegate", app.delegate)];
    [rows addObject:FLEXMacListRow(@"windows", app.windows)];
    [rows addObject:FLEXMacExploreRow(@"keyWindow", app.keyWindow)];
    [rows addObject:FLEXMacExploreRow(@"mainWindow", app.mainWindow)];
    [rows addObject:FLEXMacExploreRow(@"mainMenu", app.mainMenu)];
    [rows addObject:FLEXMacExploreRow(@"effectiveAppearance", app.effectiveAppearance)];
    [rows addObject:FLEXMacExploreRow(@"applicationIconImage", app.applicationIconImage)];
}

+ (void)addMenuShortcuts:(NSMenu *)menu to:(NSMutableArray<FLEXMacRow *> *)rows sections:(NSMutableArray<FLEXMacSection *> *)sections {
    [rows addObject:FLEXMacInfoRow(@"title", menu.title)];
    [rows addObject:FLEXMacExploreRow(@"supermenu", menu.supermenu)];
    [rows addObject:FLEXMacExploreRow(@"delegate", menu.delegate)];

    NSMutableArray *itemRows = [NSMutableArray new];
    for (NSMenuItem *item in menu.itemArray) {
        if (item.isSeparatorItem) {
            continue;
        }
        NSString *subtitle = item.submenu ? @"Submenu" :
            [NSString stringWithFormat:@"%@ → %@",
                item.action ? NSStringFromSelector(item.action) : @"no action",
                item.target ? [FLEXRuntimeUtility safeClassNameForObject:item.target] : @"first responder"
            ];
        NSString *key = [self keyEquivalentStringForItem:item];
        NSString *title = key.length ? [NSString stringWithFormat:@"%@   %@", item.title, key] : item.title;
        [itemRows addObject:[FLEXMacRow title:title subtitle:subtitle exploring:item]];
    }
    [sections addObject:[FLEXMacSection title:[NSString stringWithFormat:@"Items (%lu)", (unsigned long)itemRows.count] rows:itemRows]];
}

+ (NSString *)keyEquivalentStringForItem:(NSMenuItem *)item {
    if (!item.keyEquivalent.length) {
        return @"";
    }
    NSMutableString *string = [NSMutableString new];
    NSEventModifierFlags flags = item.keyEquivalentModifierMask;
    if (flags & NSEventModifierFlagControl) [string appendString:@"⌃"];
    if (flags & NSEventModifierFlagOption) [string appendString:@"⌥"];
    if (flags & NSEventModifierFlagShift) [string appendString:@"⇧"];
    if (flags & NSEventModifierFlagCommand) [string appendString:@"⌘"];
    [string appendString:item.keyEquivalent.uppercaseString];
    return string;
}

+ (NSArray *)responderChainFrom:(NSResponder *)responder {
    NSMutableArray *chain = [NSMutableArray new];
    NSResponder *next = responder.nextResponder;
    while (next && chain.count < 100) {
        [chain addObject:next];
        next = next.nextResponder;
    }
    return chain;
}

#pragma mark Foundation

+ (void)addDefaultsShortcuts:(NSUserDefaults *)defaults to:(NSMutableArray<FLEXMacRow *> *)rows sections:(NSMutableArray<FLEXMacSection *> *)sections {
    NSString *domain = NSBundle.mainBundle.bundleIdentifier;
    NSDictionary *appDomain = domain ? [defaults persistentDomainForName:domain] : nil;
    NSDictionary *all = defaults.dictionaryRepresentation;
    [rows addObject:FLEXMacExploreRow(@"All Values (dictionaryRepresentation)", all)];

    NSMutableArray *entryRows = [NSMutableArray new];
    for (NSString *key in [appDomain.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
        id value = appDomain[key];
        FLEXMacRow *row = [FLEXMacRow title:key subtitle:FLEXMacSummary(value) exploring:value];
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[
                FLEXMacMenuItem(@"Edit Value…", ^{
                    NSString *json = [FLEXRuntimeUtility editableJSONStringForObject:[defaults objectForKey:key]];
                    [FLEXMacUtility promptWithTitle:key message:@"Enter a JSON value" defaultValue:json completion:^(NSString *text) {
                        if (!text) return;
                        id newValue = [FLEXRuntimeUtility objectValueFromEditableJSONString:text] ?: text;
                        [defaults setObject:newValue forKey:key];
                        if ([host isKindOfClass:[FLEXMacTableViewController class]]) {
                            [(FLEXMacTableViewController *)host reloadData];
                        }
                    }];
                }),
                FLEXMacMenuItem(@"Remove Value", ^{
                    [FLEXMacUtility confirmWithTitle:[NSString stringWithFormat:@"Remove \"%@\"?", key] message:nil actionTitle:@"Remove" destructive:YES completion:^{
                        [defaults removeObjectForKey:key];
                        if ([host isKindOfClass:[FLEXMacTableViewController class]]) {
                            [(FLEXMacTableViewController *)host reloadData];
                        }
                    }];
                }),
            ];
        };
        [entryRows addObject:row];
    }

    NSString *title = [NSString stringWithFormat:@"App Domain — %@ (%lu)", domain ?: @"none", (unsigned long)entryRows.count];
    [sections addObject:[FLEXMacSection title:title rows:entryRows]];
}

+ (FLEXMacSection *)entriesSectionForDictionary:(id)dictionary {
    NSMutableArray *rows = [NSMutableArray new];
    NSArray *keys = nil;
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        keys = [dictionary allKeys];
    } else {
        keys = [[(NSMapTable *)dictionary keyEnumerator] allObjects];
    }

    // Sort keys by their descriptions for readability
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [FLEXMacSummary(a) caseInsensitiveCompare:FLEXMacSummary(b)];
    }];

    for (id key in keys) {
        if (rows.count >= kFLEXMacMaxElements) {
            break;
        }
        id value = [dictionary objectForKey:key];
        FLEXMacRow *row = [FLEXMacRow title:FLEXMacSummary(key) subtitle:FLEXMacSummary(value) exploring:value];
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[FLEXMacMenuItem(@"Explore Key", ^{
                [host flex_push:[FLEXMacObjectExplorerViewController explorerForObject:key]];
            })];
        };
        [rows addObject:row];
    }

    return [FLEXMacSection title:[NSString stringWithFormat:@"Entries (%lu)", (unsigned long)keys.count] rows:rows];
}

+ (FLEXMacSection *)elementsSectionForCollection:(id)collection {
    NSArray *elements = nil;
    if ([collection isKindOfClass:[NSArray class]]) {
        elements = collection;
    } else if ([collection isKindOfClass:[NSOrderedSet class]]) {
        elements = [collection array];
    } else if ([collection isKindOfClass:[NSPointerArray class]]) {
        elements = [collection allObjects];
    } else {
        elements = [collection allObjects];
    }

    BOOL ordered = [collection isKindOfClass:[NSArray class]] || [collection isKindOfClass:[NSOrderedSet class]] ||
        [collection isKindOfClass:[NSPointerArray class]];

    NSMutableArray *rows = [NSMutableArray new];
    [elements enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        if (idx >= kFLEXMacMaxElements) {
            *stop = YES;
            return;
        }
        NSString *title = ordered ? [NSString stringWithFormat:@"[%lu]", (unsigned long)idx] :
            [FLEXRuntimeUtility safeClassNameForObject:element];
        [rows addObject:[FLEXMacRow title:title subtitle:FLEXMacSummary(element) exploring:element]];
    }];

    return [FLEXMacSection title:[NSString stringWithFormat:@"Elements (%lu)", (unsigned long)elements.count] rows:rows];
}

+ (void)addDataShortcuts:(NSData *)data to:(NSMutableArray<FLEXMacRow *> *)rows {
    [rows addObject:FLEXMacInfoRow(@"length", [FLEXMacUtility stringForByteCount:data.length])];

    NSImage *image = data.length < 50 * 1024 * 1024 ? [[NSImage alloc] initWithData:data] : nil;
    if (image) {
        [rows addObject:FLEXMacImageRow(@"Image", image)];
    }

    NSString *utf8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (utf8) {
        [rows addObject:FLEXMacTextRow(@"UTF-8 String", utf8)];
    }

    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    if (plist && ![plist isKindOfClass:[NSString class]]) {
        [rows addObject:FLEXMacExploreRow(@"Property List / JSON", plist)];
    } else {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
        if (json) {
            [rows addObject:FLEXMacExploreRow(@"JSON", json)];
        }
    }

    // Hex dump of the first 4 KB
    NSUInteger length = MIN(data.length, 4096);
    const uint8_t *bytes = data.bytes;
    NSMutableString *hex = [NSMutableString new];
    for (NSUInteger offset = 0; offset < length; offset += 16) {
        [hex appendFormat:@"%08lx  ", (unsigned long)offset];
        NSMutableString *ascii = [NSMutableString new];
        for (NSUInteger i = 0; i < 16; i++) {
            if (offset + i < length) {
                uint8_t byte = bytes[offset + i];
                [hex appendFormat:@"%02x ", byte];
                [ascii appendFormat:@"%c", (byte >= 32 && byte < 127) ? byte : '.'];
            } else {
                [hex appendString:@"   "];
            }
        }
        [hex appendFormat:@" %@\n", ascii];
    }
    if (data.length > length) {
        [hex appendFormat:@"… %lu more bytes", (unsigned long)(data.length - length)];
    }
    FLEXMacRow *hexRow = [FLEXMacRow title:@"Hex Dump" subtitle:@"First 4 KB" pushing:^NSViewController *{
        return [FLEXMacTextViewController viewerWithText:hex title:@"Hex Dump"];
    }];
    [rows addObject:hexRow];
}

@end
