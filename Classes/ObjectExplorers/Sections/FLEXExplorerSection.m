//
//  FLEXExplorerSection.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXExplorerSection.h"
#import "FLEXTableView.h"
#import "UIMenu+FLEX.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation FLEXExplorerSection

- (void)reloadData { }

- (NSDictionary<NSString *,Class> *)cellRegistrationMapping {
    return nil;
}

- (BOOL)canSelectRow:(NSInteger)row { return NO; }

- (void (^)(UIViewController *))didSelectRowAction:(NSInteger)row {
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

- (void (^)(UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return nil;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDefaultCell;
}

#if FLEX_AT_LEAST_IOS13_SDK

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

- (NSArray<UIMenuElement *> *)menuItemsForRow:(NSInteger)row sender:(UIViewController *)sender {
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
            inlineMenuWithTitle:@"Copy…" 
            image:copyIcon
            children:actions
        ];
        
        if (collapseMenu) {
            return @[[copyMenu collapsed]];
        } else {
            return @[copyMenu];
        }
    }
    
    return @[];
}

#endif

- (NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row {
    return nil;
}

- (NSString *)titleForRow:(NSInteger)row { return nil; }
- (NSString *)subtitleForRow:(NSInteger)row { return nil; }

@end

#pragma clang diagnostic pop
