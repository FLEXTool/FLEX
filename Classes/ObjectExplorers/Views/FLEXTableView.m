//
//  FLEXTableView.m
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXMultilineTableViewCell.h"

@interface UITableView (Private)
- (CGFloat)_heightForHeaderInSection:(NSInteger)section;
- (NSString *)_titleForHeaderInSection:(NSInteger)section;
@end

@implementation FLEXTableView

+ (instancetype)flexDefaultTableView {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    } else {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
#else
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
#endif
}

- (CGFloat)_heightForHeaderInSection:(NSInteger)section {
    CGFloat height = [super _heightForHeaderInSection:section];
    if (section == 0 && self.tableHeaderView) {
        NSString *title = [self _titleForHeaderInSection:section];
        if (!@available(iOS 13, *)) {
            return height - self.tableHeaderView.frame.size.height + 8;
        } else if ([title isEqualToString:@" "]) {
            return height - self.tableHeaderView.frame.size.height + 5;
        }
    }

    return height;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerCells:@{
            self.defaultReuseIdentifier : [FLEXTableViewCell class],
            self.subtitleReuseIdentifier : [FLEXSubtitleTableViewCell class],
            self.multilineReuseIdentifier : [FLEXMultilineTableViewCell class],
        }];
    }

    return self;
}

- (void)registerCells:(NSDictionary<NSString*,Class> *)registrationMapping
{
    [registrationMapping enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class cellClass, BOOL *stop) {
        [self registerClass:cellClass forCellReuseIdentifier:identifier];
    }];
}

- (NSString *)defaultReuseIdentifier
{
    return @"kFLEXTableViewCellIdentifier";
}

- (NSString *)subtitleReuseIdentifier
{
    return @"kFLEXSubtitleTableViewCellIdentifier";
}

- (NSString *)multilineReuseIdentifier
{
    return kFLEXMultilineTableViewCellIdentifier;
}

@end
