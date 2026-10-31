//
//  FLEXMacTableViewController.m
//  FLEX (macOS)
//

#import "FLEXMacTableViewController.h"
#import "FLEXMacUtility.h"

#pragma mark - Table view

@interface FLEXMacTableView : NSTableView
@property (nonatomic, copy) void (^activateHandler)(void);
@property (nonatomic, copy) void (^copyHandler)(void);
@end

@implementation FLEXMacTableView

- (void)keyDown:(NSEvent *)event {
    NSString *chars = event.charactersIgnoringModifiers;
    if (chars.length == 1) {
        unichar c = [chars characterAtIndex:0];
        if (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSNewlineCharacter) {
            if (self.activateHandler) self.activateHandler();
            return;
        }
    }
    [super keyDown:event];
}

- (void)copy:(id)sender {
    if (self.copyHandler) self.copyHandler();
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
    if (item.action == @selector(copy:)) {
        return self.selectedRow >= 0;
    }
    return [super validateUserInterfaceItem:item];
}

@end

#pragma mark - Cells

@interface FLEXMacRowCellView : NSTableCellView
@property (nonatomic) NSTextField *titleField;
@property (nonatomic) NSTextField *subtitleField;
@property (nonatomic) NSImageView *iconView;
@property (nonatomic) NSImageView *chevronView;
@property (nonatomic) NSLayoutConstraint *iconWidth;
- (void)configureWithRow:(FLEXMacRow *)row;
@end

@implementation FLEXMacRowCellView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _iconView = [NSImageView new];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.imageScaling = NSImageScaleProportionallyUpOrDown;

        _titleField = [NSTextField labelWithString:@""];
        _titleField.translatesAutoresizingMaskIntoConstraints = NO;
        _titleField.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleField.maximumNumberOfLines = 1;
        [_titleField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                              forOrientation:NSLayoutConstraintOrientationHorizontal];

        _subtitleField = [NSTextField wrappingLabelWithString:@""];
        _subtitleField.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleField.font = [FLEXMacUtility monospacedFontOfSize:11];
        _subtitleField.textColor = NSColor.secondaryLabelColor;
        _subtitleField.lineBreakMode = NSLineBreakByTruncatingTail;
        _subtitleField.selectable = NO;
        _subtitleField.cell.truncatesLastVisibleLine = YES;
        [_subtitleField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                                 forOrientation:NSLayoutConstraintOrientationHorizontal];

        _chevronView = [NSImageView new];
        _chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        _chevronView.image = [FLEXMacUtility symbol:@"chevron.right"];
        _chevronView.contentTintColor = NSColor.tertiaryLabelColor;
        [_chevronView setContentHuggingPriority:NSLayoutPriorityRequired
                                 forOrientation:NSLayoutConstraintOrientationHorizontal];

        NSStackView *labels = [NSStackView stackViewWithViews:@[_titleField, _subtitleField]];
        labels.orientation = NSUserInterfaceLayoutOrientationVertical;
        labels.alignment = NSLayoutAttributeLeading;
        labels.spacing = 1;
        labels.translatesAutoresizingMaskIntoConstraints = NO;
        [labels setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                         forOrientation:NSLayoutConstraintOrientationHorizontal];

        [self addSubview:_iconView];
        [self addSubview:labels];
        [self addSubview:_chevronView];
        self.textField = _titleField;
        self.imageView = _iconView;

        _iconWidth = [_iconView.widthAnchor constraintEqualToConstant:0];
        [NSLayoutConstraint activateConstraints:@[
            [_iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            _iconWidth,
            [_iconView.heightAnchor constraintLessThanOrEqualToConstant:32],

            [labels.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:6],
            [labels.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
            [labels.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
            [labels.trailingAnchor constraintLessThanOrEqualToAnchor:_chevronView.leadingAnchor constant:-4],
            [_titleField.trailingAnchor constraintLessThanOrEqualToAnchor:labels.trailingAnchor],
            [_subtitleField.trailingAnchor constraintLessThanOrEqualToAnchor:labels.trailingAnchor],

            [_chevronView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6],
            [_chevronView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

- (void)configureWithRow:(FLEXMacRow *)row {
    self.titleField.stringValue = row.title ?: @"";
    self.titleField.font = row.monospaced ?
        [FLEXMacUtility monospacedFontOfSize:12] : [NSFont systemFontOfSize:13];
    self.titleField.textColor = row.titleColor ?: NSColor.labelColor;

    BOOL hasSubtitle = row.subtitle.length > 0;
    self.subtitleField.hidden = !hasSubtitle;
    self.subtitleField.stringValue = row.subtitle ?: @"";
    self.subtitleField.maximumNumberOfLines = row.subtitleMaxLines;

    self.iconView.image = row.image;
    self.iconView.hidden = !row.image;
    self.iconWidth.constant = row.image ? MIN(MAX(row.image.size.width, 16), 32) : 0;

    self.chevronView.hidden = !row.isActionable;
}

@end

@interface FLEXMacGroupCellView : NSTableCellView
@end

@implementation FLEXMacGroupCellView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSTextField *label = [NSTextField labelWithString:@""];
        label.font = [NSFont boldSystemFontOfSize:11];
        label.textColor = NSColor.secondaryLabelColor;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];
        self.textField = label;
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-4],
            [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-3],
        ]];
    }
    return self;
}

@end

#pragma mark - Controller

@interface FLEXMacTableViewController () <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, NSSearchFieldDelegate>
@property (nonatomic) FLEXMacTableView *table;
@property (nonatomic) NSScrollView *scrollView;
@property (nonatomic) NSSearchField *searchField;
@property (nonatomic) NSStackView *headerStack;
@property (nonatomic) NSTextField *emptyLabel;
/// Mix of FLEXMacSection (headers) and FLEXMacRow
@property (nonatomic) NSArray *items;
@property (nonatomic) NSArray<FLEXMacSection *> *filteredSections;
@end

@implementation FLEXMacTableViewController
@synthesize sections = _sections;

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _showsSearchBar = YES;
        _sections = @[];
        _items = @[];
    }
    return self;
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 560, 680)];

    self.headerStack = [NSStackView stackViewWithViews:@[]];
    self.headerStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.headerStack.alignment = NSLayoutAttributeLeading;
    self.headerStack.spacing = 6;
    self.headerStack.edgeInsets = NSEdgeInsetsMake(8, 8, 6, 8);
    self.headerStack.translatesAutoresizingMaskIntoConstraints = NO;

    self.searchField = [NSSearchField new];
    self.searchField.placeholderString = self.searchPlaceholder ?: @"Filter";
    self.searchField.delegate = self;
    self.searchField.sendsSearchStringImmediately = YES;
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;

    self.table = [FLEXMacTableView new];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"main"];
    column.resizingMask = NSTableColumnAutoresizingMask;
    [self.table addTableColumn:column];
    self.table.headerView = nil;
    self.table.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    self.table.usesAutomaticRowHeights = YES;
    self.table.rowHeight = 24;
    self.table.allowsMultipleSelection = NO;
    self.table.floatsGroupRows = YES;
    if (@available(macOS 11.0, *)) {
        self.table.style = NSTableViewStyleFullWidth;
    }
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.target = self;
    self.table.doubleAction = @selector(tableDoubleClicked:);
    self.table.menu = [NSMenu new];
    self.table.menu.delegate = self;

    __weak typeof(self) weakSelf = self;
    self.table.activateHandler = ^{
        FLEXMacRow *row = weakSelf.selectedRow;
        if (row) [weakSelf activateRow:row];
    };
    self.table.copyHandler = ^{
        [FLEXMacUtility copyToPasteboard:weakSelf.selectedRow.copyString];
    };

    self.scrollView = [NSScrollView new];
    self.scrollView.documentView = self.table;
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.emptyLabel = [NSTextField labelWithString:@""];
    self.emptyLabel.textColor = NSColor.secondaryLabelColor;
    self.emptyLabel.alignment = NSTextAlignmentCenter;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.hidden = YES;

    [view addSubview:self.headerStack];
    [view addSubview:self.scrollView];
    [view addSubview:self.emptyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerStack.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.headerStack.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.headerStack.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.headerStack.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],

        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.scrollView.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.scrollView.centerYAnchor],
    ]];

    self.view = view;
    [self rebuildHeader];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadData];
}

- (NSTableView *)tableView {
    [self view];
    return self.table;
}

#pragma mark Header

- (void)rebuildHeader {
    if (!self.headerStack) {
        return;
    }

    for (NSView *view in self.headerStack.arrangedSubviews.copy) {
        [self.headerStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    if (self.headerAccessoryView) {
        [self.headerStack addArrangedSubview:self.headerAccessoryView];
        [self.headerAccessoryView.trailingAnchor constraintLessThanOrEqualToAnchor:self.headerStack.trailingAnchor constant:-8].active = YES;
    }
    if (self.showsSearchBar) {
        [self.headerStack addArrangedSubview:self.searchField];
        [self.searchField.leadingAnchor constraintEqualToAnchor:self.headerStack.leadingAnchor constant:8].active = YES;
        [self.searchField.trailingAnchor constraintEqualToAnchor:self.headerStack.trailingAnchor constant:-8].active = YES;
    }

    self.headerStack.hidden = self.headerStack.arrangedSubviews.count == 0;
    self.headerStack.edgeInsets = self.headerStack.hidden ? NSEdgeInsetsZero : NSEdgeInsetsMake(8, 8, 6, 8);
}

- (void)setHeaderAccessoryView:(NSView *)headerAccessoryView {
    _headerAccessoryView = headerAccessoryView;
    [self rebuildHeader];
}

- (void)setShowsSearchBar:(BOOL)showsSearchBar {
    _showsSearchBar = showsSearchBar;
    [self rebuildHeader];
}

- (void)setSearchPlaceholder:(NSString *)searchPlaceholder {
    _searchPlaceholder = searchPlaceholder.copy;
    self.searchField.placeholderString = searchPlaceholder ?: @"Filter";
}

- (NSString *)searchText {
    return self.searchField.stringValue ?: @"";
}

- (NSView *)flex_preferredFirstResponder {
    return self.showsSearchBar ? self.searchField : self.table;
}

#pragma mark Navigation items

- (NSArray<NSView *> *)flex_navigationAccessoryViews {
    NSMutableArray *views = [NSMutableArray arrayWithArray:[self additionalNavigationAccessoryViews]];
    if (self.showsRefreshButton) {
        [views addObject:FLEXMacBarButton(@"arrow.clockwise", @"Refresh", @"Refresh (⌘R)", self, @selector(refreshPressed:))];
        NSButton *refresh = views.lastObject;
        refresh.keyEquivalent = @"r";
        refresh.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    }
    return views;
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    return @[];
}

- (void)refreshPressed:(id)sender {
    [self reloadData];
}

#pragma mark Data

- (NSArray<FLEXMacSection *> *)makeSections {
    return _sections;
}

- (void)reloadData {
    [self view];
    NSArray *sections = [self makeSections];
    _sections = sections.copy ?: @[];
    [self refilter];
}

- (void)setSections:(NSArray<FLEXMacSection *> *)sections {
    _sections = sections.copy ?: @[];
    [self refilter];
}

- (void)refilter {
    if (!self.isViewLoaded) {
        return;
    }

    NSString *query = self.searchText;
    NSMutableArray *items = [NSMutableArray new];
    for (FLEXMacSection *section in self.sections) {
        FLEXMacSection *filtered = [section filteredWithQuery:query];
        if (!filtered.rows.count) {
            continue;
        }
        if (filtered.title.length) {
            [items addObject:filtered];
        }
        [items addObjectsFromArray:filtered.rows];
    }

    // Try to preserve the selection and scroll position across reloads
    FLEXMacRow *selected = self.selectedRow;
    NSPoint scrollOrigin = self.scrollView.contentView.bounds.origin;

    self.items = items;
    [self.table reloadData];

    if (selected) {
        NSUInteger index = [items indexOfObjectIdenticalTo:selected];
        if (index != NSNotFound) {
            [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        }
    }
    [self.scrollView.contentView scrollToPoint:scrollOrigin];
    [self.scrollView reflectScrolledClipView:self.scrollView.contentView];

    BOOL empty = items.count == 0;
    self.emptyLabel.hidden = !empty;
    self.emptyLabel.stringValue = query.length ? @"No results" : (self.emptyText ?: @"");
}

- (void)searchTextDidChange {
    [self refilter];
}

- (void)controlTextDidChange:(NSNotification *)note {
    if (note.object == self.searchField) {
        [self searchTextDidChange];
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    if (control != self.searchField) {
        return NO;
    }

    // Arrow keys and return in the search field drive the table
    if (command == @selector(moveDown:) || command == @selector(moveUp:)) {
        NSInteger row = self.table.selectedRow;
        NSInteger delta = command == @selector(moveDown:) ? 1 : -1;
        NSInteger next = row + delta;
        while (next >= 0 && next < (NSInteger)self.items.count && ![self.items[next] isKindOfClass:[FLEXMacRow class]]) {
            next += delta;
        }
        if (next >= 0 && next < (NSInteger)self.items.count) {
            [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:next] byExtendingSelection:NO];
            [self.table scrollRowToVisible:next];
        }
        return YES;
    }
    if (command == @selector(insertNewline:)) {
        FLEXMacRow *row = self.selectedRow;
        if (!row) {
            // Activate the only result, if there is just one
            NSArray *rows = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, id bindings) {
                return [obj isKindOfClass:[FLEXMacRow class]];
            }]];
            if (rows.count == 1) row = rows.firstObject;
        }
        if (row) [self activateRow:row];
        return YES;
    }
    return NO;
}

- (FLEXMacRow *)selectedRow {
    NSInteger index = self.table.selectedRow;
    if (index < 0 || index >= (NSInteger)self.items.count) {
        return nil;
    }
    id item = self.items[index];
    return [item isKindOfClass:[FLEXMacRow class]] ? item : nil;
}

- (FLEXMacRow *)rowAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) {
        return nil;
    }
    id item = self.items[index];
    return [item isKindOfClass:[FLEXMacRow class]] ? item : nil;
}

#pragma mark Actions

- (void)tableDoubleClicked:(id)sender {
    FLEXMacRow *row = [self rowAtIndex:self.table.clickedRow];
    if (row) {
        [self activateRow:row];
    }
}

- (void)activateRow:(FLEXMacRow *)row {
    if (row.viewControllerProvider) {
        NSViewController *controller = row.viewControllerProvider();
        if (controller) {
            [self flex_push:controller];
        }
    } else if (row.action) {
        row.action(self);
    }
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.items.count;
}

#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    return [self.items[row] isKindOfClass:[FLEXMacSection class]];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return [self.items[row] isKindOfClass:[FLEXMacRow class]];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)index {
    id item = self.items[index];
    if ([item isKindOfClass:[FLEXMacSection class]]) {
        FLEXMacGroupCellView *cell = [tableView makeViewWithIdentifier:@"group" owner:self];
        if (!cell) {
            cell = [FLEXMacGroupCellView new];
            cell.identifier = @"group";
        }
        cell.textField.stringValue = [item title].uppercaseString ?: @"";
        return cell;
    }

    FLEXMacRowCellView *cell = [tableView makeViewWithIdentifier:@"row" owner:self];
    if (!cell) {
        cell = [FLEXMacRowCellView new];
        cell.identifier = @"row";
    }
    [cell configureWithRow:item];
    return cell;
}

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    FLEXMacRow *row = [self rowAtIndex:self.table.clickedRow];
    if (!row) {
        return;
    }

    if (row.isActionable) {
        __weak typeof(self) weakSelf = self;
        [menu addItem:FLEXMacMenuItem(@"Open", ^{
            [weakSelf activateRow:row];
        })];
        [menu addItem:NSMenuItem.separatorItem];
    }

    if (row.contextMenuProvider) {
        NSArray *items = row.contextMenuProvider(self);
        for (NSMenuItem *item in items) {
            [menu addItem:item];
        }
        if (items.count) {
            [menu addItem:NSMenuItem.separatorItem];
        }
    }

    NSString *copyString = row.copyString;
    [menu addItem:FLEXMacMenuItem(@"Copy", ^{
        [FLEXMacUtility copyToPasteboard:copyString];
    })];
    if (row.subtitle.length) {
        NSString *subtitle = row.subtitle;
        [menu addItem:FLEXMacMenuItem(@"Copy Subtitle", ^{
            [FLEXMacUtility copyToPasteboard:subtitle];
        })];
    }
}

@end
