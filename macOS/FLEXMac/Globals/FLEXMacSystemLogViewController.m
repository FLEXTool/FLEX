//
//  FLEXMacSystemLogViewController.m
//  FLEX (macOS)
//

#import "FLEXMacSystemLogViewController.h"
#import "FLEXMacPreviewViewControllers.h"
#import "FLEXMacUtility.h"
#import <OSLog/OSLog.h>

/// Avoid rendering huge logs
static const NSUInteger kFLEXMacMaxLogEntries = 5000;

@interface FLEXMacSystemLogViewController ()
@property (nonatomic) NSArray<FLEXMacRow *> *logRows;
@property (nonatomic) BOOL loading;
@property (nonatomic) NSButton *debugCheckbox;
@end

@implementation FLEXMacSystemLogViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"System Log";
        self.showsRefreshButton = YES;
        self.searchPlaceholder = @"Filter messages";
        self.emptyText = @"Loading…";
        _logRows = @[];
    }
    return self;
}

- (void)viewDidLoad {
    self.debugCheckbox = [NSButton checkboxWithTitle:@"Include system frameworks (subsystem com.apple.*)" target:self action:@selector(reloadData)];
    self.debugCheckbox.controlSize = NSControlSizeSmall;
    self.debugCheckbox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    self.headerAccessoryView = self.debugCheckbox;
    [super viewDidLoad];
}

- (void)reloadData {
    [super reloadData];
    [self loadEntries];
}

- (NSArray<FLEXMacSection *> *)makeSections {
    NSString *title = [NSString stringWithFormat:@"%lu messages since launch (newest first)", (unsigned long)self.logRows.count];
    return @[[FLEXMacSection title:title rows:self.logRows]];
}

- (void)loadEntries {
    if (self.loading) {
        return;
    }
    if (@available(macOS 10.15, *)) {
        self.loading = YES;
        BOOL includeApple = self.debugCheckbox.state == NSControlStateValueOn;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSError *error = nil;
            NSArray<FLEXMacRow *> *rows = [self readEntriesIncludingApple:includeApple error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loading = NO;
                self.logRows = rows ?: @[];
                self.emptyText = error ? error.localizedDescription : @"No log messages";
                [super reloadData];
            });
        });
    } else {
        self.emptyText = @"Reading the log requires macOS 10.15 or later";
        [super reloadData];
    }
}

- (NSArray<FLEXMacRow *> *)readEntriesIncludingApple:(BOOL)includeApple error:(NSError **)error API_AVAILABLE(macos(10.15)) {
    OSLogStore *store = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:error];
    if (!store) {
        return nil;
    }

    // The current-process scope only contains entries logged since this process launched
    NSPredicate *predicate = includeApple ? nil :
        [NSPredicate predicateWithFormat:@"NOT (subsystem BEGINSWITH 'com.apple')"];
    OSLogEnumerator *enumerator = [store entriesEnumeratorWithOptions:OSLogEnumeratorReverse
                                                             position:nil
                                                            predicate:predicate
                                                                error:error];
    if (!enumerator) {
        return nil;
    }

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"HH:mm:ss.SSS";

    NSMutableArray<FLEXMacRow *> *rows = [NSMutableArray new];
    for (OSLogEntry *entry in enumerator) {
        if (rows.count >= kFLEXMacMaxLogEntries) {
            break;
        }
        if (![entry isKindOfClass:[OSLogEntryLog class]]) {
            continue;
        }
        OSLogEntryLog *log = (OSLogEntryLog *)entry;
        NSString *message = log.composedMessage ?: @"";
        NSString *source = log.subsystem.length ?
            [NSString stringWithFormat:@"%@ [%@]", log.subsystem, log.category] : (log.sender ?: @"");
        NSString *level = @"";
        switch (log.level) {
            case OSLogEntryLogLevelDebug: level = @"debug"; break;
            case OSLogEntryLogLevelInfo: level = @"info"; break;
            case OSLogEntryLogLevelNotice: level = @"default"; break;
            case OSLogEntryLogLevelError: level = @"error"; break;
            case OSLogEntryLogLevelFault: level = @"fault"; break;
            default: break;
        }

        FLEXMacRow *row = [FLEXMacRow
            title:message
            subtitle:[NSString stringWithFormat:@"%@  %@  %@", [formatter stringFromDate:log.date], level, source]
        ];
        row.monospaced = YES;
        row.subtitleMaxLines = 1;
        row.copyString = message;
        if (log.level == OSLogEntryLogLevelError || log.level == OSLogEntryLogLevelFault) {
            row.titleColor = NSColor.systemRedColor;
        }
        row.action = ^(NSViewController *host) {
            [host flex_push:[FLEXMacTextViewController viewerWithText:message title:@"Log Message"]];
        };
        [rows addObject:row];
    }
    return rows;
}

@end
