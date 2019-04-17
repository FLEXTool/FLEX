//
//  FLEXTableView.m
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableView.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXMultilineTableViewCell.h"

@implementation FLEXTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerCells:@{
            self.defaultReuseIdentifier: [FLEXTableViewCell class],
            self.subtitleReuseIdentifier: [FLEXSubtitleTableViewCell class],
            self.multilineReuseIdentifier: [FLEXMultilineTableViewCell class],
        }];
    }

    return self;
}

- (void)registerCells:(NSDictionary<NSString*,Class> *)registrationMapping
{    [registrationMapping enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class cellClass, BOOL *stop) {
        [self registerClass:cellClass forCellReuseIdentifier:identifier];
    }];
}

- (NSString *)defaultReuseIdentifier
{    return @"kFLEXTableViewCellIdentifier";
}

- (NSString *)subtitleReuseIdentifier
{    return @"kFLEXSubtitleTableViewCellIdentifier";
}

- (NSString *)multilineReuseIdentifier
{
    return kFLEXMultilineTableViewCellIdentifier;
}

@end
