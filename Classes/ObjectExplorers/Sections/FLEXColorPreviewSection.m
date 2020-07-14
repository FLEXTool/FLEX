//
//  FLEXColorPreviewSection.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXColorPreviewSection.h"

@implementation FLEXColorPreviewSection

+ (instancetype)forObject:(UIColor *)color {
    return [self title:@"Color" reuse:nil cell:^(__kindof UITableViewCell *cell) {
        cell.backgroundColor = color;
    }];
}

- (BOOL)canSelectRow:(NSInteger)row {
    return NO;
}

- (BOOL (^)(NSString *))filterMatcher {
    return ^BOOL(NSString *filterText) {
        // Hide when searching
        return !filterText.length;
    };
}

@end
