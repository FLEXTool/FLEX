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

FLEXTableViewCellReuseIdentifier const kFLEXDefaultCell = @"kFLEXDefaultCell";
FLEXTableViewCellReuseIdentifier const kFLEXDetailCell = @"kFLEXDetailCell";
FLEXTableViewCellReuseIdentifier const kFLEXMultilineCell = @"kFLEXMultilineCell";
FLEXTableViewCellReuseIdentifier const kFLEXMultilineDetailCell = @"kFLEXMultilineDetailCell";

#pragma mark Private

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

#pragma mark - Initialization

+ (id)groupedTableView {
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

+ (id)plainTableView {
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerCells:@{
            kFLEXDefaultCell : [FLEXTableViewCell class],
            kFLEXDetailCell : [FLEXSubtitleTableViewCell class],
            kFLEXMultilineCell : [FLEXMultilineTableViewCell class],
            kFLEXMultilineDetailCell : [FLEXMultilineDetailTableViewCell class]
        }];
    }

    return self;
}

#pragma mark - Public

- (void)registerCells:(NSDictionary<NSString*, Class> *)registrationMapping {
    [registrationMapping enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class cellClass, BOOL *stop) {
        [self registerClass:cellClass forCellReuseIdentifier:identifier];
    }];
}

@end
