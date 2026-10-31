//
//  AppDelegate.m
//  FLEXMacExample
//

#import "AppDelegate.h"
#import "ExampleModels.h"
#import <FLEX/FLEX.h>
#import <os/log.h>
#import <sqlite3.h>

@interface AppDelegate () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic) NSWindow *window;
@property (nonatomic) NSArray<ExamplePerson *> *people;
@property (nonatomic) NSTextField *statusLabel;
@property (nonatomic) NSTableView *table;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self buildMainMenu];
    [self makeSampleData];
    [self buildWindow];

    // FLEX setup: record network requests, add a menu item and a custom global entry
    FLEXManager *flex = FLEXManager.sharedManager;
    flex.networkDebuggingEnabled = YES;
    [flex installMainMenuItem];
    [flex registerGlobalEntryWithName:@"🧑 Sample People" objectFutureBlock:^id {
        return self.people;
    }];

    os_log(OS_LOG_DEFAULT, "FLEXMacExample finished launching");
    NSLog(@"Press ⌥⌘F or use Window ▸ Explore with FLEX to toggle FLEX");

    if ([NSProcessInfo.processInfo.arguments containsObject:@"-FLEXShowOnLaunch"]) {
        [flex showExplorer];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark Sample data

- (void)makeSampleData {
    ExamplePerson *ada = [ExamplePerson personWithName:@"Ada" age:36];
    ExamplePerson *grace = [ExamplePerson personWithName:@"Grace" age:85];
    ExamplePerson *alan = [ExamplePerson personWithName:@"Alan" age:41];
    ada.friend = grace;
    grace.friend = alan;
    alan.friend = ada;
    grace.admin = YES;
    self.people = @[ada, grace, alan];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:@"FLEX for macOS" forKey:@"ExampleString"];
    [defaults setInteger:42 forKey:@"ExampleNumber"];
    [defaults setObject:@[@"one", @"two", @"three"] forKey:@"ExampleArray"];

    [self makeSampleDatabase];
}

- (void)makeSampleDatabase {
    NSString *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    NSString *directory = [support stringByAppendingPathComponent:NSBundle.mainBundle.bundleIdentifier ?: @"FLEXMacExample"];
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [directory stringByAppendingPathComponent:@"example.sqlite"];

    sqlite3 *db = NULL;
    if (sqlite3_open(path.UTF8String, &db) == SQLITE_OK) {
        sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);"
            "DELETE FROM people;"
            "INSERT INTO people (name, age) VALUES ('Ada', 36), ('Grace', 85), ('Alan', 41);",
            NULL, NULL, NULL
        );
    }
    sqlite3_close(db);
}

#pragma mark UI

- (void)buildMainMenu {
    NSMenu *mainMenu = [NSMenu new];
    NSString *appName = NSProcessInfo.processInfo.processName;

    NSMenuItem *appItem = [NSMenuItem new];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:appName];
    [appMenu addItemWithTitle:[@"About " stringByAppendingString:appName]
                       action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:NSMenuItem.separatorItem];
    [appMenu addItemWithTitle:[@"Hide " stringByAppendingString:appName] action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:[@"Quit " stringByAppendingString:appName] action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    [mainMenu addItem:appItem];

    NSMenuItem *editItem = [NSMenuItem new];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo" action:NSSelectorFromString(@"undo:") keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:NSSelectorFromString(@"redo:") keyEquivalent:@"Z"];
    [editMenu addItem:NSMenuItem.separatorItem];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSMenuItem *windowItem = [NSMenuItem new];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Close" action:@selector(performClose:) keyEquivalent:@"w"];
    windowItem.submenu = windowMenu;
    [mainMenu addItem:windowItem];

    NSApp.mainMenu = mainMenu;
    NSApp.windowsMenu = windowMenu;
}

- (void)buildWindow {
    self.window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 520, 460)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                  NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO
    ];
    self.window.title = @"FLEX macOS Example";
    self.window.releasedWhenClosed = NO;

    NSTextField *header = [NSTextField labelWithString:@"FLEX for macOS"];
    header.font = [NSFont systemFontOfSize:22 weight:NSFontWeightBold];

    NSTextField *info = [NSTextField wrappingLabelWithString:
        @"Press ⌥⌘F (or Window ▸ Explore with FLEX) to toggle the FLEX toolbar. "
        @"Use Select to click any view below, Views to browse the hierarchy, and Menu for tools."];
    info.textColor = NSColor.secondaryLabelColor;

    NSButton *showFLEX = [NSButton buttonWithTitle:@"Show FLEX" target:self action:@selector(showFLEX:)];
    showFLEX.bezelColor = NSColor.controlAccentColor;
    showFLEX.keyEquivalent = @"\r";
    showFLEX.identifier = @"showFLEXButton";
    NSButton *network = [NSButton buttonWithTitle:@"Send Network Requests" target:self action:@selector(sendRequests:)];
    NSButton *birthday = [NSButton buttonWithTitle:@"Celebrate Birthday" target:self action:@selector(birthday:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[showFLEX, network, birthday]];

    NSTextField *nameField = [NSTextField textFieldWithString:@"Type something…"];
    nameField.identifier = @"nameField";
    NSSlider *slider = [NSSlider sliderWithValue:0.5 minValue:0 maxValue:1 target:nil action:nil];
    NSButton *checkbox = [NSButton checkboxWithTitle:@"A checkbox" target:nil action:nil];
    NSSegmentedControl *segments = [NSSegmentedControl segmentedControlWithLabels:@[@"One", @"Two", @"Three"]
        trackingMode:NSSegmentSwitchTrackingSelectOne target:nil action:nil];
    segments.selectedSegment = 0;
    NSImageView *imageView = [NSImageView imageViewWithImage:[NSImage imageNamed:NSImageNameComputer]];
    NSStackView *controls = [NSStackView stackViewWithViews:@[slider, checkbox, segments, imageView]];

    NSTableView *table = [NSTableView new];
    self.table = table;
    table.identifier = @"peopleTable";
    for (NSString *column in @[@"Name", @"Age"]) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:column];
        tableColumn.title = column;
        [table addTableColumn:tableColumn];
    }
    table.dataSource = self;
    table.delegate = self;
    NSScrollView *tableScroll = [NSScrollView new];
    tableScroll.documentView = table;
    tableScroll.hasVerticalScroller = YES;
    [tableScroll.heightAnchor constraintEqualToConstant:110].active = YES;

    self.statusLabel = [NSTextField labelWithString:@""];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;

    NSStackView *stack = [NSStackView stackViewWithViews:@[
        header, info, buttons, nameField, controls, tableScroll, self.statusLabel
    ]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 12;
    stack.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSView *content = self.window.contentView;
    [content addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor],
        [info.widthAnchor constraintEqualToAnchor:stack.widthAnchor constant:-40],
        [nameField.widthAnchor constraintEqualToAnchor:stack.widthAnchor constant:-40],
        [tableScroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor constant:-40],
    ]];

    [self.window center];
    // When launched headless (e.g. by the injection tests), stay in the
    // background so we don't steal focus from the test host.
    if (getenv("FLEX_EXAMPLE_HEADLESS")) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [self.window orderBack:nil];
    } else {
        [self.window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

#pragma mark Actions

- (void)showFLEX:(id)sender {
    [FLEXManager.sharedManager toggleExplorer];
}

- (void)birthday:(id)sender {
    for (ExamplePerson *person in self.people) {
        [person celebrateBirthday];
    }
    [self.table reloadData];
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Everyone is a year older (Ada is %ld)", (long)self.people.firstObject.age];
}

- (void)sendRequests:(id)sender {
    NSArray<NSString *> *urls = @[
        @"https://api.github.com/repos/FLEXTool/FLEX",
        @"https://httpbin.org/get?flex=macos",
        @"https://httpbin.org/status/404",
        @"https://www.apple.com/favicon.ico",
    ];

    self.statusLabel.stringValue = @"Sending requests…";
    for (NSString *url in urls) {
        [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
                self.statusLabel.stringValue = [NSString stringWithFormat:@"%@ → %ld%@", url.lastPathComponent, (long)status,
                    error ? [@" " stringByAppendingString:error.localizedDescription] : @""];
            });
        }] resume];
    }

    // A POST with a JSON body
    NSMutableURLRequest *post = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    post.HTTPMethod = @"POST";
    [post setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    post.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"tool": @"FLEX", @"platform": @"macOS"} options:0 error:nil];
    [[NSURLSession.sharedSession dataTaskWithRequest:post] resume];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.people.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    ExamplePerson *person = self.people[row];
    NSString *value = [column.identifier isEqualToString:@"Name"] ? person.name : @(person.age).stringValue;
    NSTextField *label = [NSTextField labelWithString:value];
    return label;
}

@end
