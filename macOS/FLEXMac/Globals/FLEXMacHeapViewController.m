//
//  FLEXMacHeapViewController.m
//  FLEX (macOS)
//

#import "FLEXMacHeapViewController.h"
#import "FLEXMacObjectListViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacUtility.h"
#import "FLEXHeapEnumerator.h"

typedef NS_ENUM(NSInteger, FLEXMacHeapSort) {
    FLEXMacHeapSortCount,
    FLEXMacHeapSortSize,
    FLEXMacHeapSortName,
};

@interface FLEXMacHeapViewController ()
@property (nonatomic) FLEXHeapSnapshot *snapshot;
@property (nonatomic) NSSegmentedControl *sortControl;
@end

@implementation FLEXMacHeapViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Heap Objects";
        self.showsRefreshButton = YES;
        self.searchPlaceholder = @"Filter classes";
    }
    return self;
}

- (void)viewDidLoad {
    self.sortControl = [NSSegmentedControl
        segmentedControlWithLabels:@[@"Count", @"Size", @"Name"]
        trackingMode:NSSegmentSwitchTrackingSelectOne
        target:self action:@selector(sortChanged:)
    ];
    self.sortControl.controlSize = NSControlSizeSmall;
    self.sortControl.selectedSegment = FLEXMacHeapSortCount;

    NSTextField *label = [NSTextField labelWithString:@"Sort by:"];
    label.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    NSStackView *header = [NSStackView stackViewWithViews:@[label, self.sortControl]];
    header.spacing = 6;
    self.headerAccessoryView = header;
    [super viewDidLoad];
}

- (void)sortChanged:(id)sender {
    // Re-sort the existing snapshot without rescanning the heap
    self.sections = [self sectionsFromSnapshot];
}

- (void)reloadData {
    self.snapshot = [FLEXHeapEnumerator generateHeapSnapshot];
    [super reloadData];
}

- (NSArray<FLEXMacSection *> *)makeSections {
    return [self sectionsFromSnapshot];
}

- (NSArray<FLEXMacSection *> *)sectionsFromSnapshot {
    FLEXHeapSnapshot *snapshot = self.snapshot;
    NSDictionary<NSString *, NSNumber *> *counts = snapshot.instanceCountsForClassNames;
    NSDictionary<NSString *, NSNumber *> *sizes = snapshot.instanceSizesForClassNames;

    FLEXMacHeapSort sort = self.sortControl.selectedSegment;
    NSArray<NSString *> *names = [snapshot.classNames sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        switch (sort) {
            case FLEXMacHeapSortCount: {
                NSComparisonResult result = [counts[b] compare:counts[a]];
                return result != NSOrderedSame ? result : [a caseInsensitiveCompare:b];
            }
            case FLEXMacHeapSortSize: {
                unsigned long long sizeA = counts[a].unsignedLongLongValue * sizes[a].unsignedLongLongValue;
                unsigned long long sizeB = counts[b].unsignedLongLongValue * sizes[b].unsignedLongLongValue;
                if (sizeA != sizeB) return sizeA > sizeB ? NSOrderedAscending : NSOrderedDescending;
                return [a caseInsensitiveCompare:b];
            }
            case FLEXMacHeapSortName:
            default:
                return [a caseInsensitiveCompare:b];
        }
    }];

    unsigned long long totalCount = 0, totalSize = 0;
    NSMutableArray *rows = [NSMutableArray new];
    for (NSString *name in names) {
        unsigned long long count = counts[name].unsignedLongLongValue;
        unsigned long long size = sizes[name].unsignedLongLongValue * count;
        totalCount += count;
        totalSize += size;

        FLEXMacRow *row = [FLEXMacRow
            title:name
            subtitle:[NSString stringWithFormat:@"%llu instances — %@", count, [FLEXMacUtility stringForByteCount:size]]
            pushing:^NSViewController *{
                return [FLEXMacObjectListViewController instancesOfClassWithName:name];
            }
        ];
        row.monospaced = YES;
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[FLEXMacMenuItem(@"Explore Class", ^{
                Class cls = NSClassFromString(name);
                if (cls) [host flex_push:[FLEXMacObjectExplorerViewController explorerForObject:cls]];
            })];
        };
        [rows addObject:row];
    }

    NSString *title = [NSString stringWithFormat:@"%lu classes, %llu objects, %@",
        (unsigned long)names.count, totalCount, [FLEXMacUtility stringForByteCount:totalSize]
    ];
    return @[[FLEXMacSection title:title rows:rows]];
}

@end
