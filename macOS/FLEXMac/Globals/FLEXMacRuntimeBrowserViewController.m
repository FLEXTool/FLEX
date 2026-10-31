//
//  FLEXMacRuntimeBrowserViewController.m
//  FLEX (macOS)
//

#import "FLEXMacRuntimeBrowserViewController.h"
#import "FLEXMacObjectExplorerViewController.h"
#import "FLEXMacObjectListViewController.h"
#import "FLEXMacUtility.h"
#import <objc/runtime.h>

@interface FLEXMacRuntimeBrowserViewController ()
@property (nonatomic, copy, nullable) NSString *imagePath;
@end

@implementation FLEXMacRuntimeBrowserViewController

+ (instancetype)imagesBrowser {
    FLEXMacRuntimeBrowserViewController *browser = [self new];
    browser.title = @"Runtime Browser";
    browser.searchPlaceholder = @"Filter libraries";
    return browser;
}

+ (instancetype)classesInImage:(NSString *)imagePath {
    FLEXMacRuntimeBrowserViewController *browser = [self new];
    browser.imagePath = imagePath;
    browser.title = imagePath.lastPathComponent;
    browser.searchPlaceholder = @"Filter classes";
    return browser;
}

- (NSArray<FLEXMacSection *> *)makeSections {
    return self.imagePath ? [self classSections] : [self imageSections];
}

- (NSArray<FLEXMacSection *> *)imageSections {
    unsigned int imageCount = 0;
    const char **imageNames = objc_copyImageNames(&imageCount);
    NSString *mainExecutable = NSBundle.mainBundle.executablePath.stringByResolvingSymlinksInPath;

    NSMutableArray<FLEXMacRow *> *appRows = [NSMutableArray new];
    NSMutableArray<FLEXMacRow *> *systemRows = [NSMutableArray new];
    for (unsigned int i = 0; i < imageCount; i++) {
        NSString *path = @(imageNames[i]);
        unsigned int classCount = 0;
        const char **classNames = objc_copyClassNamesForImage(imageNames[i], &classCount);
        free(classNames);
        if (!classCount) {
            continue;
        }

        FLEXMacRow *row = [FLEXMacRow
            title:path.lastPathComponent
            subtitle:[NSString stringWithFormat:@"%u classes — %@", classCount, path]
            pushing:^NSViewController *{
                return [FLEXMacRuntimeBrowserViewController classesInImage:path];
            }
        ];
        row.subtitleMaxLines = 1;
        row.copyString = path;

        BOOL isSystem = [path hasPrefix:@"/System/"] || [path hasPrefix:@"/usr/lib/"];
        BOOL isApp = [path.stringByResolvingSymlinksInPath isEqualToString:mainExecutable];
        if (isApp) {
            [appRows insertObject:row atIndex:0];
        } else if (isSystem) {
            [systemRows addObject:row];
        } else {
            [appRows addObject:row];
        }
    }
    free(imageNames);

    NSComparator byTitle = ^NSComparisonResult(FLEXMacRow *a, FLEXMacRow *b) {
        return [a.title caseInsensitiveCompare:b.title];
    };
    [systemRows sortUsingComparator:byTitle];

    return @[
        [FLEXMacSection title:@"App & Embedded Libraries" rows:appRows],
        [FLEXMacSection title:@"System Libraries" rows:systemRows],
    ];
}

- (NSArray<FLEXMacSection *> *)classSections {
    unsigned int classCount = 0;
    const char **classNames = objc_copyClassNamesForImage(self.imagePath.UTF8String, &classCount);
    NSMutableArray<NSString *> *names = [NSMutableArray new];
    for (unsigned int i = 0; i < classCount; i++) {
        [names addObject:@(classNames[i])];
    }
    free(classNames);
    [names sortUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableArray *rows = [NSMutableArray new];
    for (NSString *name in names) {
        FLEXMacRow *row = [FLEXMacRow title:name subtitle:nil pushing:^NSViewController *{
            Class cls = NSClassFromString(name);
            return cls ? [FLEXMacObjectExplorerViewController explorerForObject:cls] : nil;
        }];
        row.monospaced = YES;
        row.contextMenuProvider = ^NSArray<NSMenuItem *> *(NSViewController *host) {
            return @[
                FLEXMacMenuItem(@"Live Instances", ^{
                    [host flex_push:[FLEXMacObjectListViewController instancesOfClassWithName:name]];
                }),
                FLEXMacMenuItem(@"Subclasses", ^{
                    [host flex_push:[FLEXMacObjectListViewController subclassesOfClassWithName:name]];
                }),
            ];
        };
        [rows addObject:row];
    }

    NSString *title = [NSString stringWithFormat:@"%lu classes", (unsigned long)rows.count];
    return @[[FLEXMacSection title:title rows:rows]];
}

@end
