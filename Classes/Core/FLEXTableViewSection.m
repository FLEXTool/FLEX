//
//  FLEXTableViewSection.m
//  FLEX
//
//  Created by Tanner on 1/29/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewSection.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "UIMenu+FLEX.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation FLEXTableViewSection

- (NSInteger)numberOfRows {
    return 0;
}

- (void)reloadData { }

- (void)reloadData:(BOOL)updateTable {
    [self reloadData];
    if (updateTable) {
        NSIndexSet *index = [NSIndexSet indexSetWithIndex:_sectionIndex];
        [_tableView reloadSections:index withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setTable:(UITableView *)tableView section:(NSInteger)index {
    _tableView = tableView;
    _sectionIndex = index;
}

- (NSDictionary<NSString *,Class> *)cellRegistrationMapping {
    return nil;
}

- (BOOL)canSelectRow:(NSInteger)row { return NO; }

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    UIViewController *toPush = [self viewControllerToPushForRow:row];
    if (toPush) {
        return ^(UIViewController *host) {
            [host.navigationController pushViewController:toPush animated:YES];
        };
    }

    return nil;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return nil;
}

- (void (^)(__kindof UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return nil;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDefaultCell;
}

- (NSString *)menuTitleForRow:(NSInteger)row {
    NSString *title = [self titleForRow:row];
    NSString *subtitle = [self menuSubtitleForRow:row];
    
    if (subtitle.length) {
        return [NSString stringWithFormat:@"%@\n\n%@", title, subtitle];
    }
    
    return title;
}

- (NSString *)menuSubtitleForRow:(NSInteger)row {
    return @"";
}

- (NSArray<UIMenuElement *> *)menuItemsForRow:(NSInteger)row sender:(UIViewController *)sender API_AVAILABLE(ios(13.0)) {
    NSArray<NSString *> *copyItems = [self copyMenuItemsForRow:row];
    NSAssert(copyItems.count % 2 == 0, @"copyMenuItemsForRow: should return an even list");
    
    if (copyItems.count) {
        NSInteger numberOfActions = copyItems.count / 2;
        BOOL collapseMenu = numberOfActions > 4;
        UIImage *copyIcon = [UIImage systemImageNamed:@"doc.on.doc"];
        
        NSMutableArray *actions = [NSMutableArray new];
        
        for (NSInteger i = 0; i < copyItems.count; i += 2) {
            NSString *key = copyItems[i], *value = copyItems[i+1];
            NSString *title = collapseMenu ? key : [@"Copy " stringByAppendingString:key];
            
            UIAction *copy = [UIAction
                actionWithTitle:title
                image:copyIcon
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    UIPasteboard.generalPasteboard.string = value;
                }
            ];
            if (!value.length) {
                copy.attributes = UIMenuElementAttributesDisabled;
            }
            
            [actions addObject:copy];
        }
        
        UIMenu *copyMenu = [UIMenu
            flex_inlineMenuWithTitle:@"Copy…" 
            image:copyIcon
            children:actions
        ];
        
        if (collapseMenu) {
            return @[[copyMenu flex_collapsed]];
        } else {
            return @[copyMenu];
        }
    }
    
    return @[];
}

- (NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row {
    return nil;
}

- (NSString *)titleForRow:(NSInteger)row { return nil; }
- (NSString *)subtitleForRow:(NSInteger)row { return nil; }

@end

#pragma clang diagnostic pop
