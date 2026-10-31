//
//  InjectorAppDelegate.m
//  FLEX Injector
//
//  A picker for launching your own debuggable macOS apps with FLEX injected
//  via DYLD_INSERT_LIBRARIES.
//

#import "InjectorAppDelegate.h"
#import "FLEXInjectEngine.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface InjectorAppDelegate () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic) NSWindow *window;
@property (nonatomic) NSTableView *table;
@property (nonatomic) NSMutableArray<FLEXInjectInfo *> *apps;
@property (nonatomic) NSTextField *dylibField;
@property (nonatomic) NSButton *autoShowCheckbox;
@property (nonatomic) NSButton *launchButton;
@property (nonatomic) NSTextView *console;
@property (nonatomic) NSMutableArray<NSTask *> *runningTasks;
@end

@implementation InjectorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.apps = [NSMutableArray new];
    self.runningTasks = [NSMutableArray new];
    [self buildMenu];
    [self buildWindow];
    [self scanDefaultLocations];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark Menu

- (void)buildMenu {
    NSMenu *mainMenu = [NSMenu new];
    NSMenuItem *appItem = [NSMenuItem new];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"FLEX Injector"];
    [appMenu addItemWithTitle:@"About FLEX Injector" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:NSMenuItem.separatorItem];
    [appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    [mainMenu addItem:appItem];

    NSMenuItem *editItem = [NSMenuItem new];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSApp.mainMenu = mainMenu;
}

#pragma mark Window

- (void)buildWindow {
    self.window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 720, 560)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                  NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"FLEX Injector";
    self.window.releasedWhenClosed = NO;
    self.window.minSize = NSMakeSize(560, 420);

    // Apps table
    self.table = [NSTableView new];
    for (NSString *identifier in @[@"app", @"status"]) {
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
        column.title = [identifier isEqualToString:@"app"] ? @"Application" : @"Injectability";
        column.width = [identifier isEqualToString:@"app"] ? 340 : 320;
        [self.table addTableColumn:column];
    }
    self.table.usesAutomaticRowHeights = YES;
    self.table.rowHeight = 40;
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.doubleAction = @selector(launchSelected:);
    self.table.target = self;
    if (@available(macOS 11.0, *)) {
        self.table.style = NSTableViewStyleInset;
    }
    NSScrollView *tableScroll = [NSScrollView new];
    tableScroll.documentView = self.table;
    tableScroll.hasVerticalScroller = YES;
    tableScroll.borderType = NSBezelBorder;
    tableScroll.translatesAutoresizingMaskIntoConstraints = NO;

    // Toolbar row: Add, Remove, Rescan
    NSButton *add = [NSButton buttonWithTitle:@"Add App…" target:self action:@selector(addApp:)];
    NSButton *remove = [NSButton buttonWithTitle:@"Remove" target:self action:@selector(removeApp:)];
    NSButton *rescan = [NSButton buttonWithTitle:@"Rescan /Applications" target:self action:@selector(rescan:)];
    NSStackView *tableButtons = [NSStackView stackViewWithViews:@[add, remove, rescan]];
    tableButtons.spacing = 8;
    tableButtons.translatesAutoresizingMaskIntoConstraints = NO;

    // Dylib row
    NSTextField *dylibLabel = [NSTextField labelWithString:@"Dylib:"];
    self.dylibField = [NSTextField textFieldWithString:[FLEXInjectEngine bundledFLEXDylibPath] ?: @""];
    self.dylibField.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    self.dylibField.translatesAutoresizingMaskIntoConstraints = NO;
    self.dylibField.toolTip = @"The dynamic library to insert. Defaults to the bundled FLEX framework.";
    NSButton *chooseDylib = [NSButton buttonWithTitle:@"Choose…" target:self action:@selector(chooseDylib:)];
    NSStackView *dylibRow = [NSStackView stackViewWithViews:@[dylibLabel, self.dylibField, chooseDylib]];
    dylibRow.spacing = 8;
    dylibRow.translatesAutoresizingMaskIntoConstraints = NO;

    // Launch row
    self.autoShowCheckbox = [NSButton checkboxWithTitle:@"Show FLEX toolbar on launch" target:nil action:nil];
    self.autoShowCheckbox.state = NSControlStateValueOn;
    self.launchButton = [NSButton buttonWithTitle:@"Launch with FLEX" target:self action:@selector(launchSelected:)];
    self.launchButton.keyEquivalent = @"\r";
    self.launchButton.bezelColor = NSColor.controlAccentColor;
    NSView *spacer = [NSView new];
    spacer.translatesAutoresizingMaskIntoConstraints = NO;
    [spacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSStackView *launchRow = [NSStackView stackViewWithViews:@[self.autoShowCheckbox, spacer, self.launchButton]];
    launchRow.translatesAutoresizingMaskIntoConstraints = NO;

    // Console
    NSScrollView *consoleScroll = [NSTextView scrollableTextView];
    self.console = consoleScroll.documentView;
    self.console.editable = NO;
    self.console.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    self.console.textContainerInset = NSMakeSize(6, 6);
    consoleScroll.borderType = NSBezelBorder;
    consoleScroll.hasVerticalScroller = YES;
    consoleScroll.translatesAutoresizingMaskIntoConstraints = NO;

    NSStackView *stack = [NSStackView stackViewWithViews:@[
        tableScroll, tableButtons, dylibRow, launchRow, consoleScroll
    ]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 10;
    stack.edgeInsets = NSEdgeInsetsMake(14, 14, 14, 14);
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setHuggingPriority:249 forOrientation:NSLayoutConstraintOrientationVertical];

    NSView *content = self.window.contentView;
    [content addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],

        [tableScroll.leadingAnchor constraintEqualToAnchor:stack.leadingAnchor constant:14],
        [tableScroll.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-14],
        [tableScroll.heightAnchor constraintGreaterThanOrEqualToConstant:220],
        [dylibRow.leadingAnchor constraintEqualToAnchor:stack.leadingAnchor constant:14],
        [dylibRow.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-14],
        [launchRow.leadingAnchor constraintEqualToAnchor:stack.leadingAnchor constant:14],
        [launchRow.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-14],
        [consoleScroll.leadingAnchor constraintEqualToAnchor:stack.leadingAnchor constant:14],
        [consoleScroll.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-14],
        [consoleScroll.heightAnchor constraintGreaterThanOrEqualToConstant:120],
    ]];

    [self logLine:@"Pick one of your debuggable apps and press Launch with FLEX." color:NSColor.secondaryLabelColor];
    [self logLine:[NSString stringWithFormat:@"Injecting: %@", self.dylibField.stringValue] color:NSColor.secondaryLabelColor];

    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark Scanning

- (void)scanDefaultLocations {
    NSArray<NSString *> *roots = @[
        @"/Applications",
        [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"],
    ];
    // Include the FLEX example app from this build, if present, as a known-good target.
    NSString *example = [NSBundle.mainBundle.bundlePath.stringByDeletingLastPathComponent
        stringByAppendingPathComponent:@"FLEXMacExample.app"];
    NSMutableArray<NSString *> *paths = [NSMutableArray new];
    if ([NSFileManager.defaultManager fileExistsAtPath:example]) {
        [paths addObject:example];
    }

    for (NSString *root in roots) {
        NSArray *names = [NSFileManager.defaultManager contentsOfDirectoryAtPath:root error:nil];
        for (NSString *name in names) {
            if ([name.pathExtension isEqualToString:@"app"]) {
                [paths addObject:[root stringByAppendingPathComponent:name]];
            }
        }
    }

    [self addAppsAtPaths:paths selectInjectable:YES];
}

- (void)addAppsAtPaths:(NSArray<NSString *> *)paths selectInjectable:(BOOL)selectInjectable {
    NSMutableSet *known = [NSMutableSet new];
    for (FLEXInjectInfo *info in self.apps) {
        [known addObject:info.appPath];
    }

    // Classification shells out to codesign, so do it off the main thread.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray<FLEXInjectInfo *> *added = [NSMutableArray new];
        for (NSString *path in paths) {
            NSString *standardized = path.stringByStandardizingPath;
            if ([known containsObject:standardized]) {
                continue;
            }
            [known addObject:standardized];
            [added addObject:[FLEXInjectEngine inspectAppBundle:standardized]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.apps addObjectsFromArray:added];
            [self sortApps];
            [self.table reloadData];
            if (selectInjectable && self.table.selectedRow < 0) {
                NSUInteger index = [self.apps indexOfObjectPassingTest:^BOOL(FLEXInjectInfo *info, NSUInteger idx, BOOL *stop) {
                    return info.isInjectable;
                }];
                if (index != NSNotFound) {
                    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
                    [self.table scrollRowToVisible:index];
                }
            }
        });
    });
}

- (void)sortApps {
    [self.apps sortUsingComparator:^NSComparisonResult(FLEXInjectInfo *a, FLEXInjectInfo *b) {
        if (a.isInjectable != b.isInjectable) {
            return a.isInjectable ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a.appPath.lastPathComponent localizedStandardCompare:b.appPath.lastPathComponent];
    }];
}

#pragma mark Actions

- (void)addApp:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    panel.allowsMultipleSelection = YES;
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"com.apple.application-bundle"]];
    panel.directoryURL = [NSURL fileURLWithPath:@"/Applications"];
    panel.prompt = @"Add";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSMutableArray *paths = [NSMutableArray new];
            for (NSURL *url in panel.URLs) {
                [paths addObject:url.path];
            }
            [self addAppsAtPaths:paths selectInjectable:NO];
        }
    }];
}

- (void)removeApp:(id)sender {
    NSInteger row = self.table.selectedRow;
    if (row >= 0 && row < (NSInteger)self.apps.count) {
        [self.apps removeObjectAtIndex:row];
        [self.table reloadData];
    }
}

- (void)rescan:(id)sender {
    [self scanDefaultLocations];
}

- (void)chooseDylib:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.message = @"Choose a .dylib or a framework binary to inject";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            self.dylibField.stringValue = panel.URL.path;
        }
    }];
}

- (FLEXInjectInfo *)selectedApp {
    NSInteger row = self.table.selectedRow;
    return (row >= 0 && row < (NSInteger)self.apps.count) ? self.apps[row] : nil;
}

- (void)launchSelected:(id)sender {
    FLEXInjectInfo *info = self.selectedApp;
    if (!info) {
        NSBeep();
        return;
    }

    NSString *dylib = self.dylibField.stringValue;
    if (!dylib.length || ![NSFileManager.defaultManager fileExistsAtPath:dylib]) {
        [self logLine:[NSString stringWithFormat:@"⚠︎ Dylib not found: %@", dylib] color:NSColor.systemRedColor];
        return;
    }

    [self logLine:@"" color:nil];
    [self logLine:[NSString stringWithFormat:@"▶ Launching %@", info.appPath.lastPathComponent] color:NSColor.labelColor];
    [self logLine:[NSString stringWithFormat:@"   exec: %@", info.executablePath] color:NSColor.secondaryLabelColor];
    [self logLine:[NSString stringWithFormat:@"   DYLD_INSERT_LIBRARIES=%@", dylib] color:NSColor.secondaryLabelColor];

    if (!info.isInjectable) {
        [self logLine:[NSString stringWithFormat:@"   note: %@ — trying anyway.", info.statusDescription]
                color:NSColor.systemOrangeColor];
    }

    NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    NSTask *task = [FLEXInjectEngine
        launchApp:info
        dylib:dylib
        autoShow:self.autoShowCheckbox.state == NSControlStateValueOn
        error:&error
        outputHandler:^(NSString *chunk) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf logRaw:chunk];
            });
        }];

    if (!task) {
        [self logLine:[NSString stringWithFormat:@"✗ Failed to launch: %@", error.localizedDescription]
                color:NSColor.systemRedColor];
        return;
    }

    [self.runningTasks addObject:task];
    task.terminationHandler = ^(NSTask *finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf logLine:[NSString stringWithFormat:@"■ %@ exited (status %d)",
                info.appPath.lastPathComponent, finished.terminationStatus]
                color:NSColor.secondaryLabelColor];
            [weakSelf.runningTasks removeObject:finished];
        });
    };
    [self logLine:[NSString stringWithFormat:@"   pid %d launched. Press ⌥⌘F in the app, or use its menu bar.", task.processIdentifier]
            color:NSColor.systemGreenColor];
}

#pragma mark Console

- (void)logRaw:(NSString *)text {
    NSDictionary *attributes = @{
        NSFontAttributeName: self.console.font,
        NSForegroundColorAttributeName: NSColor.labelColor,
    };
    [self.console.textStorage appendAttributedString:
        [[NSAttributedString alloc] initWithString:text attributes:attributes]];
    [self.console scrollRangeToVisible:NSMakeRange(self.console.string.length, 0)];
}

- (void)logLine:(NSString *)line color:(NSColor *)color {
    NSDictionary *attributes = @{
        NSFontAttributeName: self.console.font,
        NSForegroundColorAttributeName: color ?: NSColor.labelColor,
    };
    [self.console.textStorage appendAttributedString:
        [[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"] attributes:attributes]];
    [self.console scrollRangeToVisible:NSMakeRange(self.console.string.length, 0)];
}

#pragma mark Table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.apps.count;
}

- (NSColor *)colorForStatus:(FLEXInjectStatus)status {
    switch (status) {
        case FLEXInjectStatusInjectable: return NSColor.systemGreenColor;
        case FLEXInjectStatusNeedsLibraryValidationDisabled: return NSColor.systemOrangeColor;
        case FLEXInjectStatusRestricted:
        case FLEXInjectStatusSIPProtected:
        case FLEXInjectStatusNotAnApp: return NSColor.systemRedColor;
    }
    return NSColor.labelColor;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    FLEXInjectInfo *info = self.apps[row];

    if ([column.identifier isEqualToString:@"app"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"app" owner:self];
        if (!cell) {
            cell = [NSTableCellView new];
            cell.identifier = @"app";
            NSImageView *icon = [NSImageView new];
            icon.translatesAutoresizingMaskIntoConstraints = NO;
            NSTextField *title = [NSTextField labelWithString:@""];
            title.translatesAutoresizingMaskIntoConstraints = NO;
            NSTextField *subtitle = [NSTextField labelWithString:@""];
            subtitle.font = [NSFont systemFontOfSize:10];
            subtitle.textColor = NSColor.secondaryLabelColor;
            subtitle.lineBreakMode = NSLineBreakByTruncatingMiddle;
            subtitle.translatesAutoresizingMaskIntoConstraints = NO;
            [cell addSubview:icon];
            [cell addSubview:title];
            [cell addSubview:subtitle];
            cell.imageView = icon;
            cell.textField = title;
            subtitle.identifier = @"subtitle";
            [NSLayoutConstraint activateConstraints:@[
                [icon.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:2],
                [icon.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
                [icon.widthAnchor constraintEqualToConstant:28],
                [icon.heightAnchor constraintEqualToConstant:28],
                [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:8],
                [title.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-4],
                [title.topAnchor constraintEqualToAnchor:cell.topAnchor constant:4],
                [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
                [subtitle.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-4],
                [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:1],
            ]];
        }
        cell.imageView.image = info.icon;
        cell.textField.stringValue = info.appPath.lastPathComponent;
        for (NSView *view in cell.subviews) {
            if ([view.identifier isEqualToString:@"subtitle"]) {
                ((NSTextField *)view).stringValue = info.bundleIdentifier ?: info.appPath.stringByDeletingLastPathComponent;
            }
        }
        return cell;
    }

    NSTableCellView *cell = [tableView makeViewWithIdentifier:@"status" owner:self];
    if (!cell) {
        cell = [NSTableCellView new];
        cell.identifier = @"status";
        NSTextField *label = [NSTextField wrappingLabelWithString:@""];
        label.font = [NSFont systemFontOfSize:11];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.maximumNumberOfLines = 3;
        [cell addSubview:label];
        cell.textField = label;
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:2],
            [label.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-4],
            [label.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
        ]];
    }
    cell.textField.stringValue = info.statusDescription;
    cell.textField.textColor = [self colorForStatus:info.status];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.launchButton.enabled = self.selectedApp != nil;
}

@end
