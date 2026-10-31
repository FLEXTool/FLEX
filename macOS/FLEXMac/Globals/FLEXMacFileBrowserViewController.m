//
//  FLEXMacFileBrowserViewController.m
//  FLEX (macOS)
//

#import "FLEXMacFileBrowserViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacUtility.h"
#import "FLEXSQLiteDatabaseManager.h"
#import "FLEXSQLResult.h"

static const unsigned long long kFLEXMacMaxTextPreviewBytes = 20 * 1024 * 1024;

@interface FLEXMacFileBrowserViewController ()
@property (nonatomic, copy) NSString *path;
@end

@implementation FLEXMacFileBrowserViewController

+ (instancetype)browserForPath:(NSString *)path {
    FLEXMacFileBrowserViewController *browser = [self new];
    browser.path = path.stringByStandardizingPath;
    browser.title = [path isEqualToString:NSHomeDirectory()] ? @"Home" : path.lastPathComponent;
    browser.showsRefreshButton = YES;
    browser.emptyText = @"Empty folder";
    return browser;
}

+ (NSViewController *)viewerForFileAtPath:(NSString *)path {
    NSString *extension = path.pathExtension.lowercaseString;
    NSString *name = path.lastPathComponent;

    static NSSet *imageExtensions = nil, *databaseExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageExtensions = [NSSet setWithArray:@[@"png", @"jpg", @"jpeg", @"gif", @"tiff", @"tif", @"heic", @"bmp", @"icns", @"webp", @"pdf"]];
        databaseExtensions = [NSSet setWithArray:@[@"sqlite", @"sqlite3", @"db", @"store", @"sqlitedb"]];
    });

    if ([imageExtensions containsObject:extension]) {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
        if (image) {
            return [FLEXMacImagePreviewViewController previewForImage:image title:name];
        }
    }

    if ([databaseExtensions containsObject:extension]) {
        NSViewController *database = [FLEXMacDatabaseViewController databaseAtPath:path];
        if (database) {
            return database;
        }
    }

    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (!data) {
        [FLEXMacUtility showAlertWithTitle:@"Unable to Read File" message:path];
        return nil;
    }

    if ([extension isEqualToString:@"plist"] || [extension isEqualToString:@"strings"]) {
        id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
        if (plist) {
            return [FLEXMacObjectExplorerViewController explorerForObject:plist];
        }
    }

    if ([extension isEqualToString:@"json"]) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
        if (json) {
            return [FLEXMacObjectExplorerViewController explorerForObject:json];
        }
    }

    if (data.length <= kFLEXMacMaxTextPreviewBytes) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (text) {
            return [FLEXMacTextViewController viewerWithText:text title:name];
        }
    }

    // Binary plists don't always have a .plist extension
    id plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    if (plist) {
        return [FLEXMacObjectExplorerViewController explorerForObject:plist];
    }

    return [FLEXMacObjectExplorerViewController explorerForObject:data];
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    NSPopUpButton *goTo = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
    goTo.bezelStyle = NSBezelStyleTexturedRounded;
    [goTo addItemWithTitle:@"Go To"];

    NSMutableArray<NSArray<NSString *> *> *locations = [NSMutableArray arrayWithArray:@[
        @[@"Home", NSHomeDirectory()],
        @[@"Temporary", NSTemporaryDirectory()],
        @[@"App Bundle", NSBundle.mainBundle.bundlePath],
    ]];
    for (NSArray *pair in @[
        @[@"Application Support", @(NSApplicationSupportDirectory)],
        @[@"Caches", @(NSCachesDirectory)],
        @[@"Documents", @(NSDocumentDirectory)],
        @[@"Library", @(NSLibraryDirectory)],
    ]) {
        NSString *path = NSSearchPathForDirectoriesInDomains([pair[1] unsignedIntegerValue], NSUserDomainMask, YES).firstObject;
        if (path) {
            [locations addObject:@[pair[0], path]];
        }
    }
    for (NSArray<NSString *> *location in locations) {
        NSMenuItem *item = FLEXMacMenuItem(location[0], ^{
            [self flex_push:[FLEXMacFileBrowserViewController browserForPath:location[1]]];
        });
        item.toolTip = location[1];
        [goTo.menu addItem:item];
    }
    [goTo.menu addItem:NSMenuItem.separatorItem];
    [goTo.menu addItem:FLEXMacMenuItem(@"Path…", ^{
        [FLEXMacUtility promptWithTitle:@"Go To Path" message:nil defaultValue:self.path completion:^(NSString *text) {
            if (text.length) {
                [self flex_push:[FLEXMacFileBrowserViewController browserForPath:text.stringByExpandingTildeInPath]];
            }
        }];
    })];

    return @[
        goTo,
        FLEXMacBarButton(@"folder", @"Finder", @"Reveal in Finder", self, @selector(revealInFinder:)),
    ];
}

- (void)revealInFinder:(id)sender {
    [NSWorkspace.sharedWorkspace selectFile:nil inFileViewerRootedAtPath:self.path];
}

- (NSArray<FLEXMacSection *> *)makeSections {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSError *error = nil;
    NSArray<NSString *> *names = [fm contentsOfDirectoryAtPath:self.path error:&error];
    if (error) {
        self.emptyText = error.localizedDescription;
        return @[];
    }

    NSMutableArray<FLEXMacRow *> *directories = [NSMutableArray new];
    NSMutableArray<FLEXMacRow *> *files = [NSMutableArray new];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;

    for (NSString *name in [names sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
        NSString *fullPath = [self.path stringByAppendingPathComponent:name];
        NSDictionary *attributes = [fm attributesOfItemAtPath:fullPath error:nil];
        BOOL isDirectory = NO;
        [fm fileExistsAtPath:fullPath isDirectory:&isDirectory];

        NSString *subtitle;
        if (isDirectory) {
            NSUInteger count = [fm contentsOfDirectoryAtPath:fullPath error:nil].count;
            subtitle = [NSString stringWithFormat:@"%lu items", (unsigned long)count];
        } else {
            subtitle = [FLEXMacUtility stringForByteCount:[attributes fileSize]];
        }
        NSDate *modified = attributes.fileModificationDate;
        if (modified) {
            subtitle = [subtitle stringByAppendingFormat:@" — %@", [formatter stringFromDate:modified]];
        }

        FLEXMacRow *row = [FLEXMacRow title:name subtitle:subtitle pushing:^NSViewController *{
            BOOL dir = NO;
            [NSFileManager.defaultManager fileExistsAtPath:fullPath isDirectory:&dir];
            return dir ? [FLEXMacFileBrowserViewController browserForPath:fullPath] :
                [FLEXMacFileBrowserViewController viewerForFileAtPath:fullPath];
        }];
        row.image = [NSWorkspace.sharedWorkspace iconForFile:fullPath];
        row.image.size = NSMakeSize(18, 18);
        row.copyString = fullPath;
        row.subtitleMaxLines = 1;
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return [self menuItemsForPath:fullPath isDirectory:isDirectory];
        };

        [(isDirectory ? directories : files) addObject:row];
    }

    return @[
        [FLEXMacSection title:self.path rows:[directories arrayByAddingObjectsFromArray:files]],
    ];
}

- (NSArray<NSMenuItem *> *)menuItemsForPath:(NSString *)path isDirectory:(BOOL)isDirectory {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        FLEXMacMenuItem(@"Copy Path", ^{
            [FLEXMacUtility copyToPasteboard:path];
        }),
        FLEXMacMenuItem(@"Reveal in Finder", ^{
            [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:path]]];
        }),
        FLEXMacMenuItem(@"Open with Default App", ^{
            [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:path]];
        }),
        FLEXMacMenuItem(@"Explore Attributes", ^{
            NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
            [weakSelf flex_push:[FLEXMacObjectExplorerViewController explorerForObject:attributes]];
        }),
    ]];

    if (!isDirectory) {
        [items addObject:FLEXMacMenuItem(@"Explore as NSData", ^{
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
            [weakSelf flex_push:[FLEXMacObjectExplorerViewController explorerForObject:data]];
        })];
    }

    [items addObject:FLEXMacMenuItem(@"Move to Trash…", ^{
        [FLEXMacUtility confirmWithTitle:[NSString stringWithFormat:@"Move \"%@\" to the Trash?", path.lastPathComponent]
                                 message:path actionTitle:@"Move to Trash" destructive:YES completion:^{
            NSError *error = nil;
            if (![NSFileManager.defaultManager trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:&error]) {
                [FLEXMacUtility showError:error];
            }
            [weakSelf reloadData];
        }];
    })];
    return items;
}

@end

#pragma mark - Database

@interface FLEXMacDatabaseViewController ()
@property (nonatomic) FLEXSQLiteDatabaseManager *database;
@property (nonatomic, copy, nullable) NSString *tableName;
@end

@implementation FLEXMacDatabaseViewController

+ (instancetype)databaseAtPath:(NSString *)path {
    FLEXSQLiteDatabaseManager *database = [FLEXSQLiteDatabaseManager managerForDatabase:path];
    if (!database) {
        return nil;
    }
    FLEXMacDatabaseViewController *controller = [self new];
    controller.database = database;
    controller.title = path.lastPathComponent;
    controller.showsRefreshButton = YES;
    return controller;
}

+ (instancetype)tableNamed:(NSString *)table in:(FLEXSQLiteDatabaseManager *)database {
    FLEXMacDatabaseViewController *controller = [self new];
    controller.database = database;
    controller.tableName = table;
    controller.title = table;
    controller.showsRefreshButton = YES;
    controller.emptyText = @"No rows";
    return controller;
}

- (NSArray<NSView *> *)additionalNavigationAccessoryViews {
    return @[FLEXMacBarButton(@"terminal", @"SQL", @"Run a SQL query", self, @selector(runQuery:))];
}

- (void)runQuery:(id)sender {
    NSString *placeholder = self.tableName ?
        [NSString stringWithFormat:@"SELECT * FROM \"%@\" LIMIT 100", self.tableName] : @"SELECT ";
    [FLEXMacUtility promptWithTitle:@"Execute SQL" message:nil defaultValue:placeholder completion:^(NSString *text) {
        if (!text.length) {
            return;
        }
        FLEXSQLResult *result = [self.database executeStatement:text];
        if (result.message) {
            [FLEXMacUtility showAlertWithTitle:result.isError ? @"Error" : @"Result" message:result.message];
            return;
        }
        FLEXMacTableViewController *results = [FLEXMacTableViewController new];
        results.title = @"Query Results";
        results.sections = @[[FLEXMacSection title:[NSString stringWithFormat:@"%lu rows", (unsigned long)result.rows.count]
                                               rows:[self rowsForColumns:result.columns data:result.rows]]];
        [self flex_push:results];
    }];
}

- (NSArray<FLEXMacRow *> *)rowsForColumns:(NSArray<NSString *> *)columns data:(NSArray<NSArray *> *)data {
    NSMutableArray *rows = [NSMutableArray new];
    [data enumerateObjectsUsingBlock:^(NSArray *values, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *record = [NSMutableDictionary new];
        NSMutableArray *parts = [NSMutableArray new];
        [values enumerateObjectsUsingBlock:^(id value, NSUInteger col, BOOL *stop2) {
            NSString *column = col < columns.count ? columns[col] : [NSString stringWithFormat:@"%lu", (unsigned long)col];
            record[column] = value;
            [parts addObject:[NSString stringWithFormat:@"%@: %@", column,
                [FLEXMacUtility summaryForObject:value maxLength:80]]];
        }];
        FLEXMacRow *row = [FLEXMacRow
            title:[NSString stringWithFormat:@"Row %lu", (unsigned long)idx + 1]
            subtitle:[parts componentsJoinedByString:@"  |  "]
            exploring:record
        ];
        [rows addObject:row];
    }];
    return rows;
}

- (NSArray<FLEXMacSection *> *)makeSections {
    if (!self.tableName) {
        NSMutableArray *rows = [NSMutableArray new];
        for (NSString *table in [[self.database queryAllTables] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
            NSArray *columns = [self.database queryAllColumnsOfTable:table];
            FLEXMacRow *row = [FLEXMacRow title:table subtitle:[columns componentsJoinedByString:@", "] pushing:^NSViewController *{
                return [FLEXMacDatabaseViewController tableNamed:table in:self.database];
            }];
            row.subtitleMaxLines = 2;
            [rows addObject:row];
        }
        return @[[FLEXMacSection title:@"Tables" rows:rows]];
    }

    NSArray *columns = [self.database queryAllColumnsOfTable:self.tableName];
    NSArray *data = [self.database queryAllDataInTable:self.tableName];
    NSString *title = [NSString stringWithFormat:@"%lu rows — %@", (unsigned long)data.count, [columns componentsJoinedByString:@", "]];
    return @[[FLEXMacSection title:title rows:[self rowsForColumns:columns data:data]]];
}

@end
