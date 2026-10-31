//
//  FLEXMacViewHierarchyViewController.m
//  FLEX (macOS)
//

#import "FLEXMacViewHierarchyViewController.h"
#import "FLEXMacHighlightWindow.h"
#import "FLEXMacViewSelector.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacTableModel.h"
#import "FLEXMacUtility.h"

#pragma mark - Node

@interface FLEXMacHierarchyNode : NSObject
@property (nonatomic, readonly) id object; // NSWindow or NSView
@property (nonatomic, readonly, weak) FLEXMacHierarchyNode *parent;
@property (nonatomic, readonly) NSArray<FLEXMacHierarchyNode *> *children;
@property (nonatomic, readonly) NSUInteger depth;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL isWindow;
@end

@implementation FLEXMacHierarchyNode

+ (instancetype)nodeForWindow:(NSWindow *)window includeHidden:(BOOL)includeHidden {
    FLEXMacHierarchyNode *node = [self new];
    node->_object = window;
    node->_isWindow = YES;

    NSString *title = window.title.length ? [NSString stringWithFormat:@" \"%@\"", window.title] : @"";
    NSString *state = window.isVisible ? (window.isKeyWindow ? @" (key)" : @"") : @" (not visible)";
    node->_title = [NSString stringWithFormat:@"%@%@ %@%@",
        NSStringFromClass(window.class), title, [FLEXMacUtility stringForRect:window.frame], state
    ];

    NSView *root = [FLEXMacUtility rootViewForWindow:window];
    node->_children = root ? @[[self nodeForView:root parent:node depth:1 includeHidden:includeHidden]] : @[];
    return node;
}

+ (instancetype)nodeForView:(NSView *)view parent:(FLEXMacHierarchyNode *)parent depth:(NSUInteger)depth includeHidden:(BOOL)includeHidden {
    FLEXMacHierarchyNode *node = [self new];
    node->_object = view;
    node->_parent = parent;
    node->_depth = depth;

    NSMutableString *title = [[FLEXMacUtility descriptionForView:view includingFrame:YES] mutableCopy];
    NSViewController *controller = [FLEXMacUtility viewControllerForView:view];
    if (controller) {
        [title appendFormat:@"  ← %@", NSStringFromClass(controller.class)];
    }
    node->_title = title;

    NSMutableArray *children = [NSMutableArray new];
    for (NSView *subview in view.subviews) {
        if (!includeHidden && subview.isHidden) {
            continue;
        }
        [children addObject:[self nodeForView:subview parent:node depth:depth + 1 includeHidden:includeHidden]];
    }
    node->_children = children;
    return node;
}

- (void)collectInto:(NSMutableArray<FLEXMacHierarchyNode *> *)nodes {
    [nodes addObject:self];
    for (FLEXMacHierarchyNode *child in self.children) {
        [child collectInto:nodes];
    }
}

- (NSView *)view {
    return self.isWindow ? [FLEXMacUtility rootViewForWindow:self.object] : self.object;
}

@end

#pragma mark - Cell

@interface FLEXMacHierarchyCellView : NSTableCellView
@end

@implementation FLEXMacHierarchyCellView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSImageView *dot = [NSImageView new];
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        NSTextField *label = [NSTextField labelWithString:@""];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.font = [FLEXMacUtility monospacedFontOfSize:11.5];
        [label setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                        forOrientation:NSLayoutConstraintOrientationHorizontal];
        [self addSubview:dot];
        [self addSubview:label];
        self.imageView = dot;
        self.textField = label;
        [NSLayoutConstraint activateConstraints:@[
            [dot.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
            [dot.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [dot.widthAnchor constraintEqualToConstant:10],
            [dot.heightAnchor constraintEqualToConstant:10],
            [label.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:6],
            [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-4],
            [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

@end

#pragma mark - Controller

@interface FLEXMacViewHierarchyViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate, NSSearchFieldDelegate>
@property (nonatomic) NSOutlineView *outlineView;
@property (nonatomic) NSSearchField *searchField;
@property (nonatomic) NSButton *hiddenCheckbox;
@property (nonatomic) NSTextField *statusLabel;
@property (nonatomic) NSArray<FLEXMacHierarchyNode *> *roots;
@property (nonatomic) NSArray<FLEXMacHierarchyNode *> *searchResults;
@property (nonatomic, weak) NSView *pendingFocus;
@end

@implementation FLEXMacViewHierarchyViewController

+ (instancetype)hierarchy {
    FLEXMacViewHierarchyViewController *controller = [self new];
    controller.title = @"View Hierarchy";
    return controller;
}

+ (instancetype)hierarchyFocusingOnView:(NSView *)view {
    FLEXMacViewHierarchyViewController *controller = [self hierarchy];
    controller.pendingFocus = view;
    return controller;
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 680)];

    self.searchField = [NSSearchField new];
    self.searchField.placeholderString = @"Filter by class, identifier, title or address";
    self.searchField.delegate = self;
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;

    self.hiddenCheckbox = [NSButton checkboxWithTitle:@"Hidden views" target:self action:@selector(reloadHierarchy)];
    self.hiddenCheckbox.state = NSControlStateValueOn;
    self.hiddenCheckbox.controlSize = NSControlSizeSmall;
    self.hiddenCheckbox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.hiddenCheckbox.translatesAutoresizingMaskIntoConstraints = NO;

    self.outlineView = [NSOutlineView new];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"view"];
    column.resizingMask = NSTableColumnAutoresizingMask;
    [self.outlineView addTableColumn:column];
    self.outlineView.outlineTableColumn = column;
    self.outlineView.headerView = nil;
    self.outlineView.rowHeight = 20;
    self.outlineView.indentationPerLevel = 12;
    self.outlineView.autoresizesOutlineColumn = NO;
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    self.outlineView.target = self;
    self.outlineView.doubleAction = @selector(exploreClicked:);
    self.outlineView.menu = [NSMenu new];
    self.outlineView.menu.delegate = self;
    if (@available(macOS 11.0, *)) {
        self.outlineView.style = NSTableViewStyleFullWidth;
    }

    NSScrollView *scrollView = [NSScrollView new];
    scrollView.documentView = self.outlineView;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.autohidesScrollers = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.statusLabel = [NSTextField labelWithString:@""];
    self.statusLabel.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.statusLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [view addSubview:self.searchField];
    [view addSubview:self.hiddenCheckbox];
    [view addSubview:scrollView];
    [view addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.searchField.topAnchor constraintEqualToAnchor:view.topAnchor constant:8],
        [self.searchField.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:8],
        [self.hiddenCheckbox.leadingAnchor constraintEqualToAnchor:self.searchField.trailingAnchor constant:8],
        [self.hiddenCheckbox.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
        [self.hiddenCheckbox.centerYAnchor constraintEqualToAnchor:self.searchField.centerYAnchor],

        [scrollView.topAnchor constraintEqualToAnchor:self.searchField.bottomAnchor constant:6],
        [scrollView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

        [self.statusLabel.topAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:4],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:8],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-4],
    ]];

    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadHierarchy];
    [self focusOnView:self.pendingFocus];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [FLEXMacHighlightWindow.selectionHighlight highlightView:nil];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self highlightSelection];
}

- (NSView *)flex_preferredFirstResponder {
    return self.outlineView;
}

- (NSArray<NSView *> *)flex_navigationAccessoryViews {
    NSButton *refresh = FLEXMacBarButton(@"arrow.clockwise", @"Refresh", @"Refresh (⌘R)", self, @selector(reloadHierarchy));
    refresh.keyEquivalent = @"r";
    refresh.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    return @[
        FLEXMacBarButton(@"cursorarrow.rays", @"Select", @"Select a view by clicking it", self, @selector(selectView:)),
        FLEXMacBarButton(@"info.circle", @"Explore", @"Explore the selected view", self, @selector(exploreSelected:)),
        refresh,
    ];
}

#pragma mark Data

- (void)reloadHierarchy {
    NSView *selected = self.selectedNode.view;
    if (self.selectedNode.isWindow) {
        selected = nil;
    }

    BOOL includeHidden = self.hiddenCheckbox.state == NSControlStateValueOn;
    NSMutableArray *roots = [NSMutableArray new];
    for (NSWindow *window in FLEXMacUtility.appWindows) {
        // Skip windows which are not meaningful to inspect
        if (!window.contentView || [window isKindOfClass:NSClassFromString(@"NSStatusBarWindow")]) {
            continue;
        }
        [roots addObject:[FLEXMacHierarchyNode nodeForWindow:window includeHidden:includeHidden]];
    }
    self.roots = roots;
    [self updateSearchResults];
    [self.outlineView reloadData];

    if (!self.searchResults) {
        // Expand windows by default
        for (FLEXMacHierarchyNode *root in roots) {
            [self.outlineView expandItem:root];
            [self.outlineView expandItem:root.children.firstObject];
        }
    }

    if (selected) {
        [self focusOnView:selected];
    }
    [self updateStatus];
}

- (void)updateSearchResults {
    NSString *query = self.searchField.stringValue;
    if (!query.length) {
        self.searchResults = nil;
        return;
    }

    NSMutableArray<FLEXMacHierarchyNode *> *all = [NSMutableArray new];
    for (FLEXMacHierarchyNode *root in self.roots) {
        [root collectInto:all];
    }

    NSMutableArray *results = [NSMutableArray new];
    for (FLEXMacHierarchyNode *node in all) {
        NSString *address = [NSString stringWithFormat:@"%p", (__bridge void *)node.object];
        if ([node.title rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [address rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [results addObject:node];
        }
    }
    self.searchResults = results;
}

- (void)controlTextDidChange:(NSNotification *)note {
    [self updateSearchResults];
    [self.outlineView reloadData];
    if (!self.searchResults) {
        [self reloadHierarchy];
    }
    [self updateStatus];
}

- (FLEXMacHierarchyNode *)nodeForView:(NSView *)view in:(NSArray<FLEXMacHierarchyNode *> *)nodes {
    for (FLEXMacHierarchyNode *node in nodes) {
        if (node.object == view) {
            return node;
        }
        FLEXMacHierarchyNode *found = [self nodeForView:view in:node.children];
        if (found) {
            return found;
        }
    }
    return nil;
}

- (void)focusOnView:(NSView *)view {
    if (!view || !self.isViewLoaded) {
        return;
    }

    if (self.searchResults) {
        self.searchField.stringValue = @"";
        self.searchResults = nil;
        [self.outlineView reloadData];
    }

    FLEXMacHierarchyNode *node = [self nodeForView:view in:self.roots];
    if (!node) {
        return;
    }

    // Expand all ancestors, outermost first
    NSMutableArray *ancestors = [NSMutableArray new];
    for (FLEXMacHierarchyNode *parent = node.parent; parent; parent = parent.parent) {
        [ancestors insertObject:parent atIndex:0];
    }
    for (FLEXMacHierarchyNode *ancestor in ancestors) {
        [self.outlineView expandItem:ancestor];
    }
    // The window node isn't a parent of the root view node; expand it too
    for (FLEXMacHierarchyNode *root in self.roots) {
        if ([root.children containsObject:ancestors.firstObject ?: node]) {
            [self.outlineView expandItem:root];
        }
    }

    NSInteger row = [self.outlineView rowForItem:node];
    if (row >= 0) {
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [self.outlineView scrollRowToVisible:row];
    }
}

- (FLEXMacHierarchyNode *)selectedNode {
    NSInteger row = self.outlineView.selectedRow;
    return row >= 0 ? [self.outlineView itemAtRow:row] : nil;
}

- (FLEXMacHierarchyNode *)clickedNode {
    NSInteger row = self.outlineView.clickedRow;
    return row >= 0 ? [self.outlineView itemAtRow:row] : nil;
}

- (void)updateStatus {
    FLEXMacHierarchyNode *node = self.selectedNode;
    if (node) {
        self.statusLabel.stringValue = [NSString stringWithFormat:@"%@ %p — %lu subviews",
            NSStringFromClass([node.object class]), (__bridge void *)node.object,
            (unsigned long)[FLEXMacUtility subviewCountOfView:node.view]
        ];
    } else if (self.searchResults) {
        self.statusLabel.stringValue = [NSString stringWithFormat:@"%lu matching views", (unsigned long)self.searchResults.count];
    } else {
        self.statusLabel.stringValue = [NSString stringWithFormat:@"%lu windows — double-click to explore, right-click for more", (unsigned long)self.roots.count];
    }
}

- (void)highlightSelection {
    FLEXMacHierarchyNode *node = self.selectedNode;
    [FLEXMacHighlightWindow.selectionHighlight highlightView:node.view];
}

#pragma mark Actions

- (void)exploreClicked:(id)sender {
    FLEXMacHierarchyNode *node = self.clickedNode;
    if (node) {
        [self flex_push:[FLEXMacObjectExplorerViewController explorerForObject:node.object]];
    }
}

- (void)exploreSelected:(id)sender {
    FLEXMacHierarchyNode *node = self.selectedNode;
    if (node) {
        [self flex_push:[FLEXMacObjectExplorerViewController explorerForObject:node.object]];
    } else {
        NSBeep();
    }
}

- (void)selectView:(id)sender {
    __weak typeof(self) weakSelf = self;
    [FLEXMacViewSelector.sharedSelector beginWithHandler:^(NSView *view) {
        if (view) {
            [weakSelf reloadHierarchy];
            [weakSelf focusOnView:view];
            [weakSelf.view.window makeKeyAndOrderFront:nil];
        }
    }];
}

#pragma mark NSOutlineViewDataSource

- (NSArray<FLEXMacHierarchyNode *> *)childrenOfItem:(FLEXMacHierarchyNode *)item {
    if (!item) {
        return self.searchResults ?: self.roots;
    }
    return self.searchResults ? @[] : item.children;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [self childrenOfItem:item].count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self childrenOfItem:item][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [self childrenOfItem:item].count > 0;
}

#pragma mark NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)column item:(FLEXMacHierarchyNode *)node {
    FLEXMacHierarchyCellView *cell = [outlineView makeViewWithIdentifier:@"node" owner:self];
    if (!cell) {
        cell = [FLEXMacHierarchyCellView new];
        cell.identifier = @"node";
    }

    cell.textField.stringValue = node.title;
    cell.toolTip = node.title;
    if (node.isWindow) {
        cell.textField.font = [NSFont boldSystemFontOfSize:12];
        cell.imageView.image = [FLEXMacUtility symbol:@"macwindow"];
    } else {
        cell.textField.font = [FLEXMacUtility monospacedFontOfSize:11.5];
        cell.imageView.image = [FLEXMacUtility circleImageWithColor:
            [FLEXMacUtility consistentRandomColorForObject:node.object] diameter:10
        ];
    }

    BOOL hidden = !node.isWindow && [(NSView *)node.object isHiddenOrHasHiddenAncestor];
    cell.textField.textColor = hidden ? NSColor.tertiaryLabelColor : NSColor.labelColor;
    return cell;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self highlightSelection];
    [self updateStatus];
}

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    FLEXMacHierarchyNode *node = self.clickedNode;
    if (!node) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    id object = node.object;
    NSView *view = node.view;

    [menu addItem:FLEXMacMenuItem(@"Explore", ^{
        [weakSelf flex_push:[FLEXMacObjectExplorerViewController explorerForObject:object]];
    })];

    NSViewController *controller = node.isWindow ? nil : [FLEXMacUtility viewControllerForAncestralView:view];
    if (controller) {
        [menu addItem:FLEXMacMenuItem([NSString stringWithFormat:@"Explore %@", NSStringFromClass(controller.class)], ^{
            [weakSelf flex_push:[FLEXMacObjectExplorerViewController explorerForObject:controller]];
        })];
    }

    [menu addItem:FLEXMacMenuItem(@"Show Preview", ^{
        NSImage *image = [FLEXMacUtility snapshotOfView:view];
        if (image) {
            [weakSelf flex_push:[FLEXMacImagePreviewViewController previewForImage:image title:NSStringFromClass([object class])]];
        } else {
            NSBeep();
        }
    })];

    [menu addItem:FLEXMacMenuItem(@"Flash on Screen", ^{
        [FLEXMacHighlightWindow flashView:view];
    })];

    if (!node.isWindow) {
        NSView *nodeView = object;
        [menu addItem:FLEXMacMenuItem(nodeView.isHidden ? @"Unhide View" : @"Hide View", ^{
            nodeView.hidden = !nodeView.isHidden;
            [weakSelf reloadHierarchy];
        })];
    }

    [menu addItem:NSMenuItem.separatorItem];
    [menu addItem:FLEXMacMenuItem(@"Copy Description", ^{
        [FLEXMacUtility copyToPasteboard:node.title];
    })];
    [menu addItem:FLEXMacMenuItem(@"Copy Address", ^{
        [FLEXMacUtility copyToPasteboard:[NSString stringWithFormat:@"%p", (__bridge void *)object]];
    })];
    [menu addItem:FLEXMacMenuItem(@"Expand All Below", ^{
        [weakSelf.outlineView expandItem:node expandChildren:YES];
    })];
}

@end
