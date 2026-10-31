//
//  FLEXMacTableModel.m
//  FLEX (macOS)
//

#import "FLEXMacTableModel.h"
#import "FLEXMacObjectExplorerViewController.h"
#import <objc/runtime.h>

@interface FLEXMacBlockMenuTarget : NSObject
@property (nonatomic, copy) void (^handler)(void);
@end

@implementation FLEXMacBlockMenuTarget
- (void)invoke:(id)sender {
    if (self.handler) self.handler();
}
@end

static const void *kFLEXMacMenuItemTargetKey = &kFLEXMacMenuItemTargetKey;

NSMenuItem *FLEXMacMenuItem(NSString *title, void (^handler)(void)) {
    FLEXMacBlockMenuTarget *target = [FLEXMacBlockMenuTarget new];
    target.handler = handler;
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(invoke:) keyEquivalent:@""];
    item.target = target;
    // NSMenuItem.target is weak; keep the target alive with the item
    objc_setAssociatedObject(item, kFLEXMacMenuItemTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return item;
}

@implementation FLEXMacRow

+ (instancetype)title:(NSString *)title {
    return [self title:title subtitle:nil];
}

+ (instancetype)title:(NSString *)title subtitle:(NSString *)subtitle {
    FLEXMacRow *row = [self new];
    row.title = title ?: @"";
    row.subtitle = subtitle;
    row.subtitleMaxLines = 3;
    return row;
}

+ (instancetype)title:(NSString *)title subtitle:(NSString *)subtitle exploring:(id)object {
    FLEXMacRow *row = [self title:title subtitle:subtitle];
    if (object) {
        row.representedObject = object;
        row.viewControllerProvider = ^NSViewController *{
            return [FLEXMacObjectExplorerViewController explorerForObject:object];
        };
    }
    return row;
}

+ (instancetype)title:(NSString *)title subtitle:(NSString *)subtitle pushing:(NSViewController *(^)(void))provider {
    FLEXMacRow *row = [self title:title subtitle:subtitle];
    row.viewControllerProvider = provider;
    return row;
}

- (BOOL)isActionable {
    return self.viewControllerProvider || self.action;
}

- (NSString *)copyString {
    if (_copyString) {
        return _copyString;
    }
    if (self.subtitle.length) {
        return [NSString stringWithFormat:@"%@: %@", self.title, self.subtitle];
    }
    return self.title;
}

- (BOOL)matchesQuery:(NSString *)query {
    if (!query.length) {
        return YES;
    }
    NSStringCompareOptions options = NSCaseInsensitiveSearch;
    return [self.title rangeOfString:query options:options].location != NSNotFound ||
        (self.subtitle && [self.subtitle rangeOfString:query options:options].location != NSNotFound);
}

@end

@implementation FLEXMacSection

+ (instancetype)title:(NSString *)title rows:(NSArray<FLEXMacRow *> *)rows {
    FLEXMacSection *section = [self new];
    section.title = title;
    section.rows = rows ?: @[];
    return section;
}

- (FLEXMacSection *)filteredWithQuery:(NSString *)query {
    if (!query.length || self.alwaysVisible) {
        return self;
    }

    NSMutableArray *rows = [NSMutableArray new];
    for (FLEXMacRow *row in self.rows) {
        if ([row matchesQuery:query]) {
            [rows addObject:row];
        }
    }

    FLEXMacSection *filtered = [FLEXMacSection title:self.title rows:rows];
    return filtered;
}

@end
